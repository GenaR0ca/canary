"""Agrega Dungeon 1, 2 y 3 al canary.otbm (sin tocar lo que ya existe) y genera sus spawns.

Uso: python3 build_dungeon.py <canary.otbm> <salida.otbm> <canary-monster.xml> <iteminfo.pkl>
El xml de monstruos se modifica en el lugar (se agrega el bloque de Dungeon si todavía no está).
iteminfo.pkl: {id: {'unpass': bool, ...}} sacado del appearances.dat (para no poner monstruos en casillas bloqueadas).
"""
import os
import pickle
import random
import struct
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import otbm
import dungeon as D

SRC, DST, MONSTER_XML, INFO = sys.argv[1:5]
info = pickle.load(open(INFO, 'rb'))
rng = random.Random(909)

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
clash = [p for p in D.tiles if p in existing]
assert not clash, ('ya hay casillas en la zona de Dungeon', clash[:5])

areas = {}
for (x, y, z), (flags, stack) in sorted(D.tiles.items()):
    key = (x & 0xFF00, y & 0xFF00, z)
    props = bytes([x & 0xFF, y & 0xFF])
    if flags:
        props += bytes([3]) + struct.pack('<I', flags)
    first = stack[0]
    children = []
    if info.get(first, {}).get('ground'):
        props += bytes([9]) + struct.pack('<H', first)
        rest = stack[1:]
    else:
        rest = stack
    children = [[6, struct.pack('<H', iid), []] for iid in rest]
    areas.setdefault(key, []).append([5, props, children])
idx = next(i for i, n in enumerate(mapdata[2]) if n[0] == 12)
new_nodes = [[4, struct.pack('<HHB', *k), v] for k, v in sorted(areas.items())]
mapdata[2][idx:idx] = new_nodes
open(DST, 'wb').write(otbm.serialize(header, root))
print('tiles', len(D.tiles), 'areas', len(new_nodes))

# ---------- monstruos ----------
# del más débil al más fuerte de cada piso (los fuertes van lejos de la llegada y en los puntos calientes)
FLOOR_MONSTERS = {
    1: ["Skeleton Warrior", "Larva", "Cyclops", "Ghost"],                                  # nivel 19-32
    2: ["Ghost", "Skeleton Archer", "Hell Hound", "Hell Spider", "Elite Skeleton"],      # nivel 32-42
    3: ["Elite Skeleton", "Thunder Lich", "Poison Bull", "Dark Knight"],                 # nivel 42-48
}
BOSS = ("Gorgon", (91, 24), 600)   # jefe de Dungeon 3 (nivel 55), sale cada 10 minutos
SPAWNTIME = 10
MIN_DIST = 16
SAFE = 6   # sin monstruos cerca de las llegadas y las escaleras


def free(pos):
    stack = D.tiles.get(pos, (0, []))[1]
    return bool(stack) and not any(info.get(i, {}).get('unpass') for i in stack) and stack[0] not in (D.STAIRS_DOWN,) \
        and D.STAIRS_UP not in stack


safe_points = list(D.POIS['arrive'].values()) + list(D.POIS['stairs'].values()) + [D.POIS['lorencia_tp']]


def is_safe(p):
    return any(p[2] == s[2] and abs(p[0] - s[0]) <= SAFE and abs(p[1] - s[1]) <= SAFE for s in safe_points)


out = ['\t<!-- Dungeon (MU): Dungeon 1 (z8), Dungeon 2 (z9), Dungeon 3 (z10) -->\n']
total = 0
for f in (1, 2, 3):
    names = FLOOR_MONSTERS[f]
    cells = [p for p in D.walkable_global(f) if free(p) and not is_safe(p)]
    cellset = set(cells)
    arrive = D.POIS['arrive'][f]
    far = max(abs(p[0] - arrive[0]) + abs(p[1] - arrive[1]) for p in cells)
    centers = []
    # primero los puntos calientes de los minimapas de MU
    for (hp, mult) in D.HOT[f]:
        g = D.G(f, hp)
        c = min(cells, key=lambda p: (p[0] - g[0]) ** 2 + (p[1] - g[1]) ** 2)
        centers.append((c, mult + 3, True))
    order = cells[:]
    rng.shuffle(order)
    for p in order:
        if all(max(abs(p[0] - c[0][0]), abs(p[1] - c[0][1])) >= MIN_DIST for c in centers):
            centers.append((p, rng.randint(4, 6), False))
    for (c, n, hot) in centers:
        spots = [p for p in cells if abs(p[0] - c[0]) <= 4 and abs(p[1] - c[1]) <= 4]
        rng.shuffle(spots)
        d = (abs(c[0] - arrive[0]) + abs(c[1] - arrive[1])) / far
        tier = min(len(names) - 1, int(d * len(names)))
        if hot:
            tier = max(tier, len(names) - 2)
        pool = names[max(0, tier - 1):tier + 1]
        mons = []
        for p in spots[:n]:
            name = rng.choice(pool)
            mons.append(f'\t\t<monster name="{name}" x="{p[0] - c[0]}" y="{p[1] - c[1]}" z="{c[2]}" spawntime="{SPAWNTIME}" />\n')
        if not mons:
            continue
        total += len(mons)
        out.append(f'\t<monster centerx="{c[0]}" centery="{c[1]}" centerz="{c[2]}" radius="4">\n{"".join(mons)}\t</monster>\n')
    print('piso', f, 'bloques', len(centers))

name, bp, btime = BOSS
g = D.G(3, bp)
c = min((p for p in D.walkable_global(3) if free(p)), key=lambda p: (p[0] - g[0]) ** 2 + (p[1] - g[1]) ** 2)
out.append(f'\t<monster centerx="{c[0]}" centery="{c[1]}" centerz="{c[2]}" radius="2">\n'
           f'\t\t<monster name="{name}" x="0" y="0" z="{c[2]}" spawntime="{btime}" />\n\t</monster>\n')
total += 1
block = ''.join(out)
xml = open(MONSTER_XML, encoding='utf-8').read()
if 'Dungeon (MU)' not in xml:
    xml = xml.replace('</monsters>', block + '</monsters>')
    open(MONSTER_XML, 'w', encoding='utf-8').write(xml)
print('monstruos', total, 'jefe', name, c)
print('llegadas', D.POIS['arrive'], 'teleport a Lorencia', D.POIS['lorencia_tp'])
