"""Agrega las arenas de Devil Square al canary.otbm (sin tocar lo que ya existe).

Uso: python3 tools/mubia/mapas/build_devil_square.py <canary.otbm de entrada> <canary.otbm de salida>
"""
import os
import struct
import sys

sys.path.insert(0, os.path.dirname(__file__))
import otbm  # noqa: E402
import devil_square  # noqa: E402

SRC, DST = sys.argv[1], sys.argv[2]
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
clash = [p for p in devil_square.tiles if p in existing]
assert not clash, clash[:5]

areas = {}
for (x, y, z), (flags, stack) in sorted(devil_square.tiles.items()):
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
print('tiles', len(devil_square.tiles), 'areas', len(new_nodes))
