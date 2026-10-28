"""Agrega Icarus al canary.otbm (sin tocar lo que ya existe), sus spawns de monstruos y a Potion Girl Amy.

Uso: python3 build_icarus.py <canary.otbm> <salida.otbm> <canary-monster.xml> <canary-npc.xml> <iteminfo.pkl>
Los xml de monstruos y NPCs se modifican en el lugar (se agrega el bloque de Icarus si todavía no está).
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
import icarus as A

SRC, DST, MONSTER_XML, NPC_XML, INFO = sys.argv[1:6]
info = pickle.load(open(INFO, 'rb'))
tiles = A.tiles
rng = random.Random(4242)

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
assert not clash, ('ya hay casillas en la zona de Icarus', clash[:5])

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
# Un respawn en cada símbolo XP del mapa de Genaro. Los monstruos son los de Icarus en MU, más fuertes
# cuanto más lejos de la zona segura del centro. Phoenix of Darkness (jefe) en la plataforma más lejana.
ZONES = [
    ["Alquamos", "Queen Rainer", "Mega Crust"],
    ["Mega Crust", "Queen Rainer", "Drakan"],
    ["Drakan", "Alpha Crust", "Phantom Knight"],
    ["Phantom Knight", "Great Drakan", "Alpha Crust"],
]
SPAWNTIME = 10

walk = A.walkable_global()
safe_cells = A.safe_global()


def free(pos):
    stack = tiles.get(pos, (0, []))[1]
    return pos in walk and pos not in safe_cells and not any(info.get(i, {}).get('unpass') for i in stack)


rooms = A.rooms_global()
boss = A.POIS['boss']
out = ['\t<!-- Icarus (MU) -->\n']
total = 0
count = {}
for i, c in enumerate(rooms):
    spots = [(c[0] + dx, c[1] + dy, c[2]) for dx in range(-4, 5) for dy in range(-4, 5)]
    spots = [p for p in spots if free(p) and max(abs(p[0] - c[0]), abs(p[1] - c[1])) <= 4]
    rng.shuffle(spots)
    zone = ZONES[min(len(ZONES) - 1, i * len(ZONES) // len(rooms))]
    mons = []
    is_boss = c == boss
    for p in spots[:(4 if is_boss else rng.randint(5, 8))]:
        r = rng.random()
        name = zone[0] if r < 0.45 else (zone[1] if r < 0.8 else zone[2])
        count[name] = count.get(name, 0) + 1
        mons.append(f'\t\t<monster name="{name}" x="{p[0] - c[0]}" y="{p[1] - c[1]}" z="{c[2]}" spawntime="{SPAWNTIME}" />\n')
    if is_boss:
        mons.append(f'\t\t<monster name="Phoenix of Darkness" x="0" y="0" z="{c[2]}" spawntime="900" />\n')
    total += len(mons)
    out.append(f'\t<monster centerx="{c[0]}" centery="{c[1]}" centerz="{c[2]}" radius="4">\n{"".join(mons)}\t</monster>\n')

block = ''.join(out)
xml = open(MONSTER_XML, encoding='utf-8').read()
if 'Icarus (MU)' not in xml:
    xml = xml.replace('</monsters>', block + '</monsters>')
    open(MONSTER_XML, 'w', encoding='utf-8').write(xml)
print('bloques', len(rooms), 'monstruos', total, count)

# ---------- NPC: Potion Girl Amy ----------
a = A.POIS['amy']
npc = (f'\t<npc centerx="{a[0]}" centery="{a[1]}" centerz="{a[2]}" radius="1">\n'
       f'\t\t<npc name="Potion Girl Amy" x="0" y="0" z="{a[2]}" spawntime="60" />\n\t</npc>\n')
xml = open(NPC_XML, encoding='utf-8').read()
if f'centerx="{a[0]}" centery="{a[1]}"' not in xml:
    xml = xml.replace('</npcs>', npc + '</npcs>')
    open(NPC_XML, 'w', encoding='utf-8').write(xml)
for k, v in A.POIS.items():
    print(k, v)
