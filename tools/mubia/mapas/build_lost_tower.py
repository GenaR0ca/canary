"""Agrega Lost Tower 1-7 al canary.otbm (sin tocar lo que ya existe) y genera sus spawns.

Uso: python3 build_lost_tower.py <canary.otbm> <salida.otbm> <canary-monster.xml> <iteminfo.pkl>
El xml de monstruos se modifica en el lugar (se agrega el bloque de Lost Tower si todavía no está).
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
import lost_tower as L

SRC, DST, MONSTER_XML, INFO = sys.argv[1:5]
info = pickle.load(open(INFO, 'rb'))
tiles = L.tiles
rng = random.Random(7007)

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
assert not clash, ('ya hay casillas en la zona de Lost Tower', clash[:5])

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
# cada piso tiene sus monstruos de MU; los más fuertes lejos de la entrada del piso
FLOOR_MONSTERS = {
    1: ["Shadow", "Poison Shadow"],              # nivel 47-50
    2: ["Poison Shadow", "Cursed Wizard"],       # nivel 50-54
    3: ["Cursed Wizard", "Death Cow"],           # nivel 54-57
    4: ["Death Cow", "Devil"],                   # nivel 57-60
    5: ["Devil", "Death Knight"],                # nivel 60-62
    6: ["Death Knight", "Death Gorgon"],         # nivel 62-64
    7: ["Death Gorgon", "Balrog"],               # nivel 64-66
}
SPAWNTIME = {"Balrog": 150}   # el Balrog de MU tarda más en volver (regenTime 150)
DEFAULT_SPAWNTIME = 10
MIN_DIST = 11
SAFE = 6   # sin monstruos cerca de las llegadas, escaleras, portales y de la zona segura


def free(pos):
    stack = tiles.get(pos, (0, []))[1]
    return bool(stack) and not any(info.get(i, {}).get('unpass') for i in stack) \
        and L.STAIRS_DOWN not in stack and L.STAIRS_UP not in stack


safe_cells = L.safe_global()
near_safe = {(s[0] + dx, s[1] + dy, s[2]) for s in safe_cells for dx in range(-5, 6) for dy in range(-5, 6)}
keep = list(L.POIS['arrive'].values()) + list(L.POIS['stairs_up'].values()) + list(L.POIS['stairs_down'].values()) + \
    [L.POIS['devias_front'], L.POIS['icarus_front']]


def is_safe(p):
    return p in near_safe or any(p[2] == s[2] and abs(p[0] - s[0]) <= SAFE and abs(p[1] - s[1]) <= SAFE for s in keep)


out = ['\t<!-- Lost Tower (MU): Lost Tower 1 a 7 -->\n']
total = 0
for f in range(1, 8):
    walk = L.walkable_global(f)
    start = L.POIS['arrive'][f]
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
    far = max(d[p] for p in cells)
    names = FLOOR_MONSTERS[f]
    order = cells[:]
    rng.shuffle(order)
    centers = []
    for p in order:
        if all(max(abs(p[0] - c[0]), abs(p[1] - c[1])) >= MIN_DIST for c in centers):
            centers.append(p)
    for c in centers:
        spots = [p for p in cells if abs(p[0] - c[0]) <= 4 and abs(p[1] - c[1]) <= 4]
        rng.shuffle(spots)
        # el segundo monstruo del piso aparece más cuanto más lejos de la entrada
        strong = d[c] / (far + 1)
        n = rng.randint(5, 8)
        mons = []
        balrogs = 0
        for p in spots[:n]:
            name = names[1] if rng.random() < 0.25 + 0.5 * strong else names[0]
            if name == "Balrog":
                if balrogs >= 1:
                    name = names[0]
                else:
                    balrogs += 1
            t = SPAWNTIME.get(name, DEFAULT_SPAWNTIME)
            mons.append(f'\t\t<monster name="{name}" x="{p[0] - c[0]}" y="{p[1] - c[1]}" z="{c[2]}" spawntime="{t}" />\n')
        if not mons:
            continue
        total += len(mons)
        out.append(f'\t<monster centerx="{c[0]}" centery="{c[1]}" centerz="{c[2]}" radius="4">\n{"".join(mons)}\t</monster>\n')
    print('Lost Tower', f, 'casillas', len(cells), 'bloques', len(centers))

block = ''.join(out)
xml = open(MONSTER_XML, encoding='utf-8').read()
if 'Lost Tower (MU)' not in xml:
    xml = xml.replace('</monsters>', block + '</monsters>')
    open(MONSTER_XML, 'w', encoding='utf-8').write(xml)
print('monstruos', total)
for k, v in L.POIS.items():
    print(k, v)
