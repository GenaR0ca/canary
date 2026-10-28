"""Agrega la Arena al canary.otbm (sin tocar lo que ya existe) y genera sus spawns y el NPC.

Uso: python3 build_arena.py <canary.otbm> <salida.otbm> <canary-monster.xml> <canary-npc.xml> <iteminfo.pkl>
Los dos xml se modifican en el lugar (se agrega el bloque de la Arena si todavía no está).
"""
import os
import pickle
import random
import struct
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import otbm
import arena as A

SRC, DST, MONSTER_XML, NPC_XML, INFO = sys.argv[1:6]
info = pickle.load(open(INFO, 'rb'))
rng = random.Random(77)

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
clash = [p for p in A.tiles if p in existing]
assert not clash, clash[:5]

areas = {}
for (x, y, z), (flags, stack) in sorted(A.tiles.items()):
    key = (x & 0xFF00, y & 0xFF00, z)
    props = bytes([x & 0xFF, y & 0xFF])
    if flags:
        props += bytes([3]) + struct.pack('<I', flags)
    props += bytes([9]) + struct.pack('<H', stack[0])
    children = [[6, struct.pack('<H', iid), []] for iid in stack[1:]]
    areas.setdefault(key, []).append([5, props, children])
idx = next(i for i, n in enumerate(mapdata[2]) if n[0] == 12)
new_nodes = [[4, struct.pack('<HHB', *k), v] for k, v in sorted(areas.items())]
mapdata[2][idx:idx] = new_nodes
open(DST, 'wb').write(otbm.serialize(header, root))
print('tiles', len(A.tiles), 'areas', len(new_nodes))

# ---------- monstruos: cada jaula más fuerte que la anterior ----------
CAGE_MONSTERS = [
    ["Spider", "Goblin", "Budge Dragon", "Chain Scorpion"],                       # 1: nivel 2-5
    ["Bull Fighter", "Elite Goblin", "Hound"],                                   # 2: 6-9
    ["Beetle Monster", "Elite Bull Fighter", "Hunter"],                          # 3: 10-13
    ["Lich", "Forest Monster", "Agon"],                                          # 4: 14-16
    ["Giant", "Stone Golem", "Skeleton Warrior"],                                # 5: 17-19
    ["Worm", "Ice Monster", "Hommerd"],                                          # 6: 20-24
    ["Larva", "Assassin", "Yeti"],                                               # 7: 25-30
    ["Ghost", "Skeleton Archer", "Elite Yeti", "Hell Hound"],                    # 8: 32-38
    ["Hell Spider", "Elite Skeleton", "Thunder Lich", "Poison Bull"],            # 9: 40-46
    ["Shadow", "Dark Knight", "Poison Shadow", "Cursed Wizard"],                 # 10: 47-54
    ["Gorgon", "Death Cow", "Devil", "Death Knight", "Death Gorgon", "Balrog"],  # 11: 55-66
    ["Ogre Archer", "Elite Ogre", "Bloody Wolf", "Metal Balrog", "Iron Wheel"],  # 12: 70-80
    ["Tantallos", "Beam Knight", "Cursed King", "Death Beam Knight"],            # 13: 83-93
    ["Gigantis", "Berserker", "Balram (Trainee)", "Soram (Trainee)", "Persona", "Dreadfear", "Dark Elf"],  # 14: 105-135
]
assert len(CAGE_MONSTERS) == len(A.CAGES)
BLOCKS = [2] * 12 + [4, 7]
PER_BLOCK = 6
SPAWNTIME = 10


def walk(p):
    f, st = A.tiles[p]
    return not any(info.get(i, {}).get('unpass') for i in st)


out = ['\t<!-- Arena (MU): jaulas de leveo, de la mas debil (1) a la mas fuerte (14) -->\n']
total = 0
for k, names in enumerate(CAGE_MONSTERS):
    cells = [p for p in A.walkable_inside(k) if walk(p)]
    x0, y0, x1, y1, side = A.CAGES[k]
    n = BLOCKS[k]
    # centros repartidos a lo largo de la jaula
    for b in range(n):
        if n == 1:
            cx = (x0 + x1) // 2
        else:
            cx = x0 + 3 + round(b * (x1 - x0 - 6) / (n - 1))
        cy = (y0 + y1) // 2
        c = (A.OX + cx, A.OY + cy, A.Z)
        spots = [p for p in cells if abs(p[0] - c[0]) <= 3 and abs(p[1] - c[1]) <= 3]
        rng.shuffle(spots)
        mons = []
        for i, p in enumerate(spots[:PER_BLOCK]):
            name = names[(b * PER_BLOCK + i) % len(names)]
            mons.append(f'\t\t<monster name="{name}" x="{p[0] - c[0]}" y="{p[1] - c[1]}" z="{A.Z}" spawntime="{SPAWNTIME}" />\n')
        total += len(mons)
        out.append(f'\t<monster centerx="{c[0]}" centery="{c[1]}" centerz="{A.Z}" radius="3">\n{"".join(mons)}\t</monster>\n')
block = ''.join(out)
xml = open(MONSTER_XML, encoding='utf-8').read()
if 'Arena (MU)' not in xml:
    xml = xml.replace('</monsters>', block + '</monsters>')
    open(MONSTER_XML, 'w', encoding='utf-8').write(xml)
print('monsters', total)

# ---------- Arena Guard ----------
gx, gy, gz = A.POIS['arena_guard']
npc = (f'\t<npc centerx="{gx}" centery="{gy}" centerz="{gz}" radius="1">\n'
       f'\t\t<npc name="Arena Guard" x="0" y="0" z="{gz}" spawntime="60" />\n\t</npc>\n')
xml = open(NPC_XML, encoding='utf-8').read()
if 'Arena Guard' not in xml:
    xml = xml.replace('</npcs>', npc + '</npcs>')
    open(NPC_XML, 'w', encoding='utf-8').write(xml)
print('npc', A.POIS['arena_guard'], 'temple', A.POIS['temple'])
