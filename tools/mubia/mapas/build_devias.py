"""Agrega Devias al canary.otbm (sin tocar lo que ya existe) y genera spawns."""
import struct, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import otbm, devias as lorencia

SRC = sys.argv[1]
DST = sys.argv[2]
header, root = otbm.parse_file(SRC)
mapdata = root[2][0]
assert mapdata[0] == 2

# no pisar nada existente
existing = set()
for node in mapdata[2]:
    if node[0] == 4:
        bx, by, bz = struct.unpack('<HHB', node[1][:5])
        for t in node[2]:
            if t[0] in (5, 14):
                existing.add((bx + t[1][0], by + t[1][1], bz))
clash = [p for p in lorencia.tiles if p in existing]
assert not clash, clash[:5]

areas = {}
for (x, y, z), (flags, stack) in sorted(lorencia.tiles.items()):
    key = (x & 0xFF00, y & 0xFF00, z)
    props = bytes([x & 0xFF, y & 0xFF])
    if flags:
        props += bytes([3]) + struct.pack('<I', flags)
    props += bytes([9]) + struct.pack('<H', stack[0])
    children = [[6, struct.pack('<H', iid), []] for iid in stack[1:]]
    areas.setdefault(key, []).append([5, props, children])

# insertar las áreas antes del nodo de ciudades (12)
idx = next(i for i, n in enumerate(mapdata[2]) if n[0] == 12)
new_nodes = [[4, struct.pack('<HHB', *k), v] for k, v in sorted(areas.items())]
mapdata[2][idx:idx] = new_nodes

# ciudad Devias
towns = mapdata[2][idx + len(new_nodes)]
assert towns[0] == 12
ids = [struct.unpack('<I', t[1][:4])[0] for t in towns[2]]
TOWN_ID = 11
assert TOWN_ID not in ids
name = b'Devias'
tx, ty, tz = lorencia.POIS['temple']
towns[2].append([13, struct.pack('<IH', TOWN_ID, len(name)) + name + struct.pack('<HHB', tx, ty, tz), []])

open(DST, 'wb').write(otbm.serialize(header, root))
print('tiles', len(lorencia.tiles), 'areas', len(new_nodes))
