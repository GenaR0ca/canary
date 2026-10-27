"""Agrega Tarkan 1 y 2 al canary.otbm (sin tocar lo que ya existe) y genera sus spawns.

Uso: python3 build_tarkan.py <canary.otbm> <salida.otbm> <canary-monster.xml> <canary-npc.xml> <iteminfo.pkl>
Los xml de monstruos y NPCs se modifican en el lugar (se agrega el bloque de Tarkan si todavía no está).
iteminfo.pkl: {id: {'unpass': bool, 'ground': bool, ...}} sacado del appearances.dat.
"""
import os
import pickle
import random
import struct
import sys
from collections import deque

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import otbm
import tarkan as T

SRC, DST, MONSTER_XML, NPC_XML, INFO = sys.argv[1:6]
info = pickle.load(open(INFO, 'rb'))
tiles = T.tiles
rng = random.Random(9090)

# ---------- mapa ----------
header, root = otbm.parse_file(SRC)
mapdata = root[2][0]
assert mapdata[0] == 2
existing = set()
for node in mapdata[2]:
    if node[0] == 4:
        bx, by, bz = struct.unpack('<HHB', node[1][:5])
        for t in node[2]:
            if t[0] in (5, 14):
                existing.add((bx + t[1][0], by + t[1][1], bz))
clash = [p for p in tiles if p in existing]
assert not clash, ('ya hay casillas en la zona de Tarkan', clash[:5])

areas = {}
for (x, y, z), (flags, stack, attrs) in sorted(tiles.items()):
    key = (x & 0xFF00, y & 0xFF00, z)
    props = bytes([x & 0xFF, y & 0xFF])
    if flags:
        props += bytes([3]) + struct.pack('<I', flags)
    first = stack[0]
    assert info.get(first, {}).get('ground'), ('la primera cosa no es piso', (x, y, z), first)
    props += bytes([9]) + struct.pack('<H', first)
    rest = stack[1:]
    # los atributos (action id, depot id) van en la última cosa de la casilla
    children = [[6, struct.pack('<H', iid) + (attrs if i == len(rest) - 1 else b''), []] for i, iid in enumerate(rest)]
    areas.setdefault(key, []).append([5, props, children])
idx = next(i for i, n in enumerate(mapdata[2]) if n[0] == 12)
new_nodes = [[4, struct.pack('<HHB', *k), v] for k, v in sorted(areas.items())]
mapdata[2][idx:idx] = new_nodes
open(DST, 'wb').write(otbm.serialize(header, root))
print('tiles', len(tiles), 'areas', len(new_nodes))

# ---------- monstruos ----------
# Tarkan 1 (oeste): Mutant cerca de la zona segura, después Bloody Wolf y lejos Iron Wheel.
# Tarkan 2 (este): Iron Wheel y Tantallos; en la zona roja y el cuadrado del noreste Beam Knight;
# en el círculo de lava del sureste Beam Knight con algún Death Beam Knight, y Zaikan en el noreste.
SPAWNTIME = {"Death Beam Knight": 150, "Zaikan": 150}
DEFAULT_SPAWNTIME = 10
MIN_DIST = 11
SAFE_R = 6


def free(pos):
    stack = tiles.get(pos, (0, []))[1]
    return bool(stack) and not any(info.get(i, {}).get('unpass') for i in stack)


walk = T.walkable_global()
safe_cells = T.safe_global()
near_safe = {(s[0] + dx, s[1] + dy, s[2]) for s in safe_cells for dx in range(-6, 7) for dy in range(-6, 7)}
keep = [T.POIS['arrive1'], T.POIS['arrive2'], T.POIS['tp_atlans']]


def is_safe(p):
    return p in near_safe or any(abs(p[0] - k[0]) <= SAFE_R and abs(p[1] - k[1]) <= SAFE_R for k in keep)


start = T.POIS['arrive1']
d = {start: 0}
q = deque([start])
while q:
    c = q.popleft()
    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        n = (c[0] + dx, c[1] + dy, c[2])
        if n in walk and n not in d:
            d[n] = d[c] + 1
            q.append(n)
cells = [p for p in sorted(walk) if p in d and free(p) and not is_safe(p)]
t1 = [p for p in cells if not T.is_tarkan2(p)]
far1 = max(d[p] for p in t1)


def names_for(c):
    z = T.zone_global(c)
    if not T.is_tarkan2(c):
        f = d[c] / (far1 + 1)
        if f < 0.45:
            return ["Mutant", "Bloody Wolf"], 0.15
        if f < 0.75:
            return ["Bloody Wolf", "Iron Wheel"], 0.3
        return ["Iron Wheel", "Bloody Wolf"], 0.25
    if z == 'se':
        return ["Beam Knight", "Death Beam Knight"], 0.15
    if z in ('ne', 'east'):
        return ["Beam Knight", "Tantallos"], 0.35
    return ["Tantallos", "Iron Wheel"], 0.35


order = cells[:]
rng.shuffle(order)
centers = []
for p in order:
    if all(max(abs(p[0] - c[0]), abs(p[1] - c[1])) >= MIN_DIST for c in centers):
        centers.append(p)

out = ['\t<!-- Tarkan (MU): Tarkan 1 y Tarkan 2 -->\n']
total = 0
counts = {}
for c in centers:
    spots = [p for p in cells if abs(p[0] - c[0]) <= 4 and abs(p[1] - c[1]) <= 4]
    rng.shuffle(spots)
    names, p2 = names_for(c)
    n = rng.randint(5, 8)
    mons = []
    rare = 0
    for p in spots[:n]:
        name = names[1] if rng.random() < p2 else names[0]
        if name == "Death Beam Knight":
            if rare >= 1:
                name = names[0]
            else:
                rare += 1
        t = SPAWNTIME.get(name, DEFAULT_SPAWNTIME)
        counts[name] = counts.get(name, 0) + 1
        mons.append(f'\t\t<monster name="{name}" x="{p[0] - c[0]}" y="{p[1] - c[1]}" z="{c[2]}" spawntime="{t}" />\n')
    if not mons:
        continue
    total += len(mons)
    out.append(f'\t<monster centerx="{c[0]}" centery="{c[1]}" centerz="{c[2]}" radius="4">\n{"".join(mons)}\t</monster>\n')

# Zaikan: un solo jefe en el medio del cuadrado del noreste
ne = [p for p in cells if T.zone_global(p) == 'ne']
cx = sum(p[0] for p in ne) / len(ne)
cy = sum(p[1] for p in ne) / len(ne)
zk = min(ne, key=lambda p: (p[0] - cx) ** 2 + (p[1] - cy) ** 2)
out.append(f'\t<monster centerx="{zk[0]}" centery="{zk[1]}" centerz="{zk[2]}" radius="3">\n'
           f'\t\t<monster name="Zaikan" x="0" y="0" z="{zk[2]}" spawntime="{SPAWNTIME["Zaikan"]}" />\n\t</monster>\n')
total += 1
counts["Zaikan"] = 1

block = ''.join(out)
xml = open(MONSTER_XML, encoding='utf-8').read()
if 'Tarkan (MU)' not in xml:
    xml = xml.replace('</monsters>', block + '</monsters>')
    open(MONSTER_XML, 'w', encoding='utf-8').write(xml)
print('monstruos', total, counts, 'bloques', len(centers), 'Zaikan', zk)

# ---------- NPC ----------
amy = T.POIS['amy']
npc = (f'\t<npc centerx="{amy[0]}" centery="{amy[1]}" centerz="{amy[2]}" radius="1">\n'
       f'\t\t<npc name="Potion Girl Amy" x="0" y="0" z="{amy[2]}" spawntime="60" />\n\t</npc>\n')
xml = open(NPC_XML, encoding='utf-8').read()
if f'centerx="{amy[0]}" centery="{amy[1]}"' not in xml:
    xml = xml.replace('</npcs>', npc + '</npcs>')
    open(NPC_XML, 'w', encoding='utf-8').write(xml)
for k, v in T.POIS.items():
    print(k, v)
