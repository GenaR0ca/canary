"""Reemplaza la región de Noria (z7) en un canary.otbm por la de noria2, sin tocar el resto del mapa."""
import struct, sys
sys.path.insert(0, '/tmp/claude-0/map')
import otbm, noria2 as N

SRC, DST = sys.argv[1], sys.argv[2]
header, root = otbm.parse_file(SRC)
mapdata = root[2][0]
X0, Y0, X1, Y1 = N.OX, N.OY, N.OX + N.W - 1, N.OY + N.H - 1
removed = 0
for node in mapdata[2]:
    if node[0] != 4:
        continue
    bx, by, bz = struct.unpack('<HHB', node[1][:5])
    if bz != N.Z:
        continue
    keep = []
    for t in node[2]:
        if t[0] in (5, 14):
            x, y = bx + t[1][0], by + t[1][1]
            if X0 <= x <= X1 and Y0 <= y <= Y1:
                removed += 1
                continue
        keep.append(t)
    node[2] = keep
mapdata[2] = [n for n in mapdata[2] if n[0] != 4 or n[2]]
areas = {}
for (x, y, z), (flags, stack) in sorted(N.tiles.items()):
    key = (x & 0xFF00, y & 0xFF00, z)
    props = bytes([x & 0xFF, y & 0xFF])
    if flags:
        props += bytes([3]) + struct.pack('<I', flags)
    props += bytes([9]) + struct.pack('<H', stack[0])
    children = [[6, struct.pack('<H', iid), []] for iid in stack[1:]]
    areas.setdefault(key, []).append([5, props, children])
idx = next(i for i, n in enumerate(mapdata[2]) if n[0] == 12)
mapdata[2][idx:idx] = [[4, struct.pack('<HHB', *k), v] for k, v in sorted(areas.items())]
open(DST, 'wb').write(otbm.serialize(header, root))
print('removed', removed, 'added', len(N.tiles))
