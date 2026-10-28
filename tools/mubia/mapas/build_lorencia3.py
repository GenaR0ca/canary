"""Aplica lorencia3 (ciudad de Lorencia decorada) sobre el canary.otbm de Genaro, sin tocar el resto del mapa.
uso: python build_lorencia3.py origen.otbm destino.otbm"""
import struct, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import otbm, lorencia3 as L

SRC, DST = sys.argv[1], sys.argv[2]
header, root = otbm.parse_file(SRC)
mapdata = root[2][0]
BX0, BY0, BX1, BY1 = L.X0 - 2, L.Y0 - 2, L.X1 + 2, L.Y1 + 2


def tile_items(t):
    p = t[1]
    i = 6 if t[0] == 14 else 2
    items = []
    while i < len(p):
        a = p[i]; i += 1
        if a == 3:
            i += 4
        elif a == 9:
            items.append(struct.unpack('<H', p[i:i + 2])[0]); i += 2
        else:
            raise ValueError(('atributo de tile desconocido', a))
    for c in t[2]:
        if len(c[1]) > 2 or c[2]:
            raise ValueError(('item con atributos dentro de la ciudad', t[1][:2]))
        items.append(struct.unpack('<H', c[1][:2])[0])
    return items


# 1) leer los tiles actuales de la ciudad
cur = {}
for node in mapdata[2]:
    if node[0] != 4:
        continue
    bx, by, bz = struct.unpack('<HHB', node[1][:5])
    for t in node[2]:
        if t[0] in (5, 14):
            x, y = bx + t[1][0], by + t[1][1]
            if BX0 <= x <= BX1 and BY0 <= y <= BY1:
                if t[0] == 14:
                    raise ValueError(('casa dentro de la ciudad', x, y))
                cur[(x, y, bz)] = tile_items(t)

T = L.build(cur)
new = T.t

# 2) quitar los tiles que cambian
removed = 0
for node in mapdata[2]:
    if node[0] != 4:
        continue
    bx, by, bz = struct.unpack('<HHB', node[1][:5])
    keep = []
    for t in node[2]:
        if t[0] in (5, 14) and (bx + t[1][0], by + t[1][1], bz) in new:
            removed += 1
            continue
        keep.append(t)
    node[2] = keep
mapdata[2] = [n for n in mapdata[2] if n[0] != 4 or n[2]]

# 3) agregar los tiles nuevos en áreas nuevas
areas = {}
for (x, y, z), (flags, stack, attrs) in sorted(new.items()):
    if not stack:
        continue
    props = bytes([x & 0xFF, y & 0xFF])
    if flags:
        props += bytes([3]) + struct.pack('<I', flags)
    props += bytes([9]) + struct.pack('<H', stack[0])
    children = [[6, struct.pack('<H', iid) + attrs.get(i, b''), []] for i, iid in enumerate(stack) if i > 0]
    areas.setdefault((x & 0xFF00, y & 0xFF00, z), []).append([5, props, children])
idx = next(i for i, n in enumerate(mapdata[2]) if n[0] == 12)
mapdata[2][idx:idx] = [[4, struct.pack('<HHB', *k), v] for k, v in sorted(areas.items())]

# 4) mover el templo de Lorencia (town 9)
towns = mapdata[2][next(i for i, n in enumerate(mapdata[2]) if n[0] == 12)]
for tw in towns[2]:
    p = tw[1]
    tid = struct.unpack('<I', p[:4])[0]
    if tid == 9:
        l = struct.unpack('<H', p[4:6])[0]
        tw[1] = p[:6 + l] + struct.pack('<HHB', L.TEMPLE[0], L.TEMPLE[1], 7) + p[11 + l:]
        print('templo', p[6:6 + l].decode('latin1'), '->', L.TEMPLE)

open(DST, 'wb').write(otbm.serialize(header, root))
print('tiles quitados', removed, 'tiles nuevos', sum(len(v) for v in areas.values()))
