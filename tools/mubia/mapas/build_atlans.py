"""Agrega Atlans al canary.otbm (sin tocar lo que ya existe) y genera sus spawns.

Uso: python3 build_atlans.py <canary.otbm> <salida.otbm> <canary-monster.xml> <iteminfo.pkl>
El xml de monstruos se modifica en el lugar (se agrega el bloque de Atlans si todavía no está).
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
import atlans as A

SRC, DST, MONSTER_XML, INFO = sys.argv[1:5]
info = pickle.load(open(INFO, 'rb'))
A.UNPASS = {i for i, v in info.items() if v.get('unpass')}
tiles = A.build()
rng = random.Random(4808)

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
assert not clash, ('ya hay casillas en la zona de Atlans', clash[:5])

areas = {}
for (x, y, z), (flags, stack) in sorted(tiles.items()):
    key = (x & 0xFF00, y & 0xFF00, z)
    props = bytes([x & 0xFF, y & 0xFF])
    if flags:
        props += bytes([3]) + struct.pack('<I', flags)
    first = stack[0]
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
print('tiles', len(tiles), 'areas', len(new_nodes))

# ---------- monstruos ----------
# cada casilla pertenece a la llegada (Atlans 1, 2 o 3) más cercana caminando
ZONE_MONSTERS = {
    1: ["Bahamut", "Vepar", "Valkyrie"],                      # nivel 43-46
    2: ["Valkyrie", "Great Bahamut", "Silver Valkyrie"],      # nivel 46-68
    3: ["Lizard King", "Lizard King", "Hydra"],               # nivel 70-74
}
SPAWNTIME = {"Hydra": 150}   # la Hydra de MU tarda más en volver (regenTime 150)
DEFAULT_SPAWNTIME = 10
MIN_DIST = 13
SAFE = 7   # sin monstruos cerca de las llegadas, del remolino de Tarkan y de la zona segura

walk = A.walkable_global()
safe_cells = A.safe_global()


def free(pos):
    stack = tiles.get(pos, (0, []))[1]
    return bool(stack) and not any(info.get(i, {}).get('unpass') for i in stack)


dist = {}
for f, a in A.POIS['arrive'].items():
    d = {a: 0}
    q = deque([a])
    while q:
        c = q.popleft()
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            n = (c[0] + dx, c[1] + dy, c[2])
            if n in walk and n not in d:
                d[n] = d[c] + 1
                q.append(n)
    dist[f] = d

keep = list(A.POIS['arrive'].values()) + [A.POIS['tarkan_front']]


near_safe = {(s[0] + dx, s[1] + dy, s[2]) for s in safe_cells for dx in range(-5, 6) for dy in range(-5, 6)}


def is_safe(p):
    return p in near_safe or any(abs(p[0] - s[0]) <= SAFE and abs(p[1] - s[1]) <= SAFE for s in keep)


cells = [p for p in sorted(walk) if free(p) and not is_safe(p) and all(p in dist[f] for f in (1, 2, 3))]
zone = {p: min((1, 2, 3), key=lambda f: dist[f][p]) for p in cells}
by_zone = {f: [p for p in cells if zone[p] == f] for f in (1, 2, 3)}

out = ['\t<!-- Atlans (MU): Atlans 1, Atlans 2, Atlans 3 -->\n']
total = 0
for f in (1, 2, 3):
    names = ZONE_MONSTERS[f]
    zc = by_zone[f]
    far = max(dist[f][p] for p in zc)
    order = zc[:]
    rng.shuffle(order)
    centers = []
    for p in order:
        if all(max(abs(p[0] - c[0]), abs(p[1] - c[1])) >= MIN_DIST for c in centers):
            centers.append(p)
    zset = set(zc)
    for c in centers:
        spots = [p for p in zc if abs(p[0] - c[0]) <= 4 and abs(p[1] - c[1]) <= 4]
        rng.shuffle(spots)
        tier = min(len(names) - 1, int(dist[f][c] / (far + 1) * len(names)))
        pool = names[max(0, tier - 1):tier + 1]
        n = rng.randint(5, 8)
        mons = []
        hydras = 0
        for p in spots[:n]:
            name = rng.choice(pool)
            if name == "Hydra":
                if hydras >= 1:
                    name = "Lizard King"
                else:
                    hydras += 1
            t = SPAWNTIME.get(name, DEFAULT_SPAWNTIME)
            mons.append(f'\t\t<monster name="{name}" x="{p[0] - c[0]}" y="{p[1] - c[1]}" z="{c[2]}" spawntime="{t}" />\n')
        if not mons:
            continue
        total += len(mons)
        out.append(f'\t<monster centerx="{c[0]}" centery="{c[1]}" centerz="{c[2]}" radius="4">\n{"".join(mons)}\t</monster>\n')
    print('Atlans', f, 'casillas', len(zc), 'bloques', len(centers))

block = ''.join(out)
xml = open(MONSTER_XML, encoding='utf-8').read()
if 'Atlans (MU)' not in xml:
    xml = xml.replace('</monsters>', block + '</monsters>')
    open(MONSTER_XML, 'w', encoding='utf-8').write(xml)
print('monstruos', total)
print('llegadas', A.POIS['arrive'], 'Tarkan', A.POIS['tarkan_vortex'], A.POIS['tarkan_front'])
