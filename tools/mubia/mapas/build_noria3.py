"""Aplica Noria v3 sobre el canary.otbm de Genaro sin tocar el resto del mapa: reemplaza los tiles de la región de
Noria (z7), mueve el templo del town 10 y actualiza los NPCs de Noria en canary-npc.xml.
uso: python build_noria3.py origen.otbm destino.otbm npc_origen.xml npc_destino.xml"""
import re, struct, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import otbm, noria3 as N

SRC, DST, NPC_SRC, NPC_DST = sys.argv[1:5]
X0, Y0, X1, Y1 = N.OX, N.OY, N.OX + N.W - 1, N.OY + N.H - 1


def inside(x, y):
    return X0 <= x <= X1 and Y0 <= y <= Y1


header, root = otbm.parse_file(SRC)
mapdata = root[2][0]

# 1) quitar los tiles viejos de Noria (z7) y avisar si hay algo en otros pisos
removed, other_floors = 0, 0
for node in mapdata[2]:
    if node[0] != 4:
        continue
    bx, by, bz = struct.unpack('<HHB', node[1][:5])
    keep = []
    for t in node[2]:
        if t[0] in (5, 14):
            x, y = bx + t[1][0], by + t[1][1]
            if inside(x, y):
                if t[0] == 14:
                    raise ValueError(('hay una casa dentro de Noria', x, y, bz))
                if bz == N.Z:
                    removed += 1
                    continue
                other_floors += 1
        keep.append(t)
    node[2] = keep
mapdata[2] = [n for n in mapdata[2] if n[0] != 4 or n[2]]

# 2) agregar los tiles nuevos
areas = {}
for (x, y, z), (flags, stack, attrs) in sorted(N.tiles.items()):
    props = bytes([x & 0xFF, y & 0xFF])
    if flags:
        props += bytes([3]) + struct.pack('<I', flags)
    props += bytes([9]) + struct.pack('<H', stack[0])
    children = [[6, struct.pack('<H', iid) + attrs.get(i, b''), []] for i, iid in enumerate(stack) if i > 0]
    areas.setdefault((x & 0xFF00, y & 0xFF00, z), []).append([5, props, children])
idx = next(i for i, n in enumerate(mapdata[2]) if n[0] == 12)
mapdata[2][idx:idx] = [[4, struct.pack('<HHB', *k), v] for k, v in sorted(areas.items())]

# 3) mover el templo de Noria (town 10)
towns = mapdata[2][next(i for i, n in enumerate(mapdata[2]) if n[0] == 12)]
moved = False
for tw in towns[2]:
    p = tw[1]
    if struct.unpack('<I', p[:4])[0] == 10:
        l = struct.unpack('<H', p[4:6])[0]
        tw[1] = p[:6 + l] + struct.pack('<HHB', *N.POIS['temple']) + p[11 + l:]
        print('templo', p[6:6 + l].decode('latin1'), '->', N.POIS['temple'])
        moved = True
assert moved, 'no encontré el town 10 (Noria)'

open(DST, 'wb').write(otbm.serialize(header, root))
print('tiles quitados', removed, 'tiles nuevos', len(N.tiles), 'tiles en otros pisos (sin tocar)', other_floors)

# 4) NPCs: mover los que están en Noria a su lugar nuevo
xml = open(NPC_SRC, encoding='utf-8').read()
seen = set()


def move_npc(m):
    block = m.group(0)
    cx, cy = int(m.group(1)), int(m.group(2))
    if not inside(cx, cy):
        return block
    name = re.search(r'<npc name="([^"]+)"', block[block.index('>') + 1:]).group(1)
    if name not in N.POIS['npcs']:
        print('NPC en Noria que no conozco, queda donde está:', name, cx, cy)
        return block
    nx, ny, nz = N.POIS['npcs'][name]
    seen.add(name)
    block = re.sub(r'centerx="\d+" centery="\d+"', f'centerx="{nx}" centery="{ny}"', block, count=1)
    return re.sub(r'radius="\d+"', 'radius="1"', block, count=1)


xml = re.sub(r'\t<npc centerx="(\d+)" centery="(\d+)".*?\t</npc>\n', move_npc, xml, flags=re.S)
missing = set(N.POIS['npcs']) - seen
if missing:
    print('NPCs que no estaban en Noria (no se agregan):', sorted(missing))
open(NPC_DST, 'w', encoding='utf-8', newline='').write(xml)
print('NPCs movidos:', sorted(seen))
