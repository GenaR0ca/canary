"""Genera Icarus (MU, Crimson Icarus) como pasarelas de piedra flotando en un vacío rojo, estilo Tibia.

La forma sale del mapa que pasó Genaro (icarus_layout.png, minimapa de Crimson Icarus):
- lo gris oscuro del minimapa = pasarelas y salas de piedra
- cada símbolo "XP" = una plataforma redonda con un respawn de monstruos
- la flecha verde del centro = donde aparece el jugador; el círculo amarillo = la única zona protegida
  (con Potion Girl Amy, un baúl y el teleport de vuelta a Lost Tower 7)
Todo lo demás es vacío: rojo oscuro cerca de las pasarelas y negro más lejos, con barandas de piedra blanca
en los bordes, antorchas, pilares sueltos y cristales de colores (las columnas de luz de MU).

1 píxel del minimapa = 0.6 casillas. Norte arriba, igual que la imagen.
Salida: tiles {(x, y, z): [flags, [ground, items...], attrs]} en coordenadas globales y POIS.
"""
import math
import os
import random
import struct
from collections import deque

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
rng = random.Random(4141)

OX, OY, Z = 2100, 1100, 7
SCALE = 0.6
MARGIN = 8
PZ = 1   # flag de zona protegida en el otbm

img = Image.open(os.path.join(HERE, 'icarus_layout.png')).convert('RGBA')
IW, IH = img.size
PX = img.load()
W = int(IW * SCALE) + 2 * MARGIN
H = int(IH * SCALE) + 2 * MARGIN

# ---------- piezas de Tibia ----------
VOID_RED = [18615, 18616, 18617, 18618, 18619, 18620]   # vacío rojo oscuro (no se pisa)
VOID_BLACK = 13775                                      # vacío negro, lejos de las pasarelas
STONE = 429                                             # losas grandes de piedra gris
STONE_VAR = [22538, 430]
CARVED = [21705, 520]                                   # piedra tallada (centro de plataformas)
MOSAIC = 21437                                          # mosaico del centro de la zona segura
RAIL_H, RAIL_V, RAIL_CORNER, RAIL_POLE = 2222, 2224, 2228, 2226   # baranda de piedra blanca
TORCH_H, TORCH_V = 2929, 2931                           # antorchas encendidas sobre la baranda
PILLARS = [2153, 2153, 7507]                            # pilares sueltos en el vacío
CRYSTALS = [7805, 7806, 7807, 7808]                     # cristales grandes (azul, celeste, rojo, verde)
BASIN = 2110                                            # brasero encendido
DEPOT = 3499
DEPOT_ID = 11          # mismo depot que Devias y Lost Tower
RETURN_PORTAL = 1949   # el teleport de vuelta lo crea teleports.lua (acá solo se deja libre la casilla)

N4 = ((1, 0), (-1, 0), (0, 1), (0, -1))
AROUND = [(dx, dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1) if dx or dy]


def to_tile(px, py):
    return (int(px * SCALE) + MARGIN, int(py * SCALE) + MARGIN)


# ---------- lo caminable según el minimapa ----------
def dark(x, y):
    r, g, b, a = PX[x, y]
    return a > 40 and max(r, g, b) < 115


count = {}
for y in range(IH):
    for x in range(IW):
        if dark(x, y):
            t = to_tile(x, y)
            count[t] = count.get(t, 0) + 1
per_tile = (1 / SCALE) ** 2
walk = {t for t, n in count.items() if n >= 0.4 * per_tile}
# los bordes blancos del minimapa se comen un poco del pasillo: se suman las casillas a medio pintar de al lado
walk |= {t for t, n in count.items() if n >= 0.1 * per_tile and any((t[0] + dx, t[1] + dy) in walk for dx, dy in N4)}

def in_block(cells, p, n):
    """True si p es parte de algún cuadrado n x n completamente caminable"""
    return any(all((p[0] - ox + i, p[1] - oy + j) in cells for i in range(n) for j in range(n))
               for ox in range(n) for oy in range(n))


# las líneas del borde blanco dejan rayitas de 1 casilla: se sacan
for _ in range(2):
    walk = {p for p in walk if in_block(walk, p, 2)}
# los pasillos angostos se ensanchan para que tengan al menos 4 casillas (la baranda del sur/este ocupa una)
thin = [p for p in walk if not in_block(walk, p, 4)]
walk |= {(p[0] + dx, p[1] + dy) for p in thin for dx, dy in N4}

# los símbolos XP (sacados del texto amarillo "XP"); la calavera está a la izquierda del texto
XP_MARKS = [(119, 18), (61, 37), (304, 38), (383, 44), (249, 73), (61, 79), (405, 85), (161, 109), (199, 113),
            (69, 120), (367, 120), (327, 152), (257, 163), (365, 183), (55, 187), (156, 189), (287, 196),
            (432, 212), (345, 247), (59, 264), (407, 267), (332, 293), (257, 294), (45, 321), (338, 337),
            (139, 347), (391, 385), (72, 398), (197, 413), (245, 417), (349, 421), (105, 447), (272, 450),
            (199, 451), (35, 453)]
ARROW_MARK = (193, 244)
PZ_BOX = ((173, 215), (211, 268))   # el círculo amarillo de Genaro (en píxeles)

ROOMS = []
for (lx, ly) in XP_MARKS:
    c = to_tile(lx - 9, ly - 2)
    ROOMS.append(c)
    r = 4.6
    for dx in range(-5, 6):
        for dy in range(-5, 6):
            if dx * dx + dy * dy <= r * r:
                walk.add((c[0] + dx, c[1] + dy))

# zona segura: la pasarela que encierra el círculo amarillo, más una plaza de 11x11 alrededor de la flecha
SPAWN = to_tile(*ARROW_MARK)
(pax, pay), (pbx, pby) = PZ_BOX
A0, B0 = to_tile(pax, pay), to_tile(pbx, pby)
ecx, ecy = (A0[0] + B0[0]) / 2, (A0[1] + B0[1]) / 2
erx, ery = (B0[0] - A0[0]) / 2, (B0[1] - A0[1]) / 2
PLAZA = {(SPAWN[0] + dx, SPAWN[1] + dy) for dx in range(-5, 6) for dy in range(-5, 6) if abs(dx) + abs(dy) <= 8}
walk |= PLAZA
SAFE = {p for p in walk if ((p[0] - ecx) / erx) ** 2 + ((p[1] - ecy) / ery) ** 2 <= 1} | PLAZA

walk = {p for p in walk if MARGIN // 2 <= p[0] < W - MARGIN // 2 and MARGIN // 2 <= p[1] < H - MARGIN // 2}


def flood(seed, cells):
    seen = {seed}
    q = deque([seed])
    while q:
        x, y = q.popleft()
        for dx, dy in N4:
            p = (x + dx, y + dy)
            if p in cells and p not in seen:
                seen.add(p)
                q.append(p)
    return seen


# unir con un pasillo de 3 casillas lo que quedó suelto (plataformas que el minimapa no conectaba bien)
while True:
    main = flood(SPAWN, walk)
    rest = walk - main
    if not rest:
        break
    comp = flood(next(iter(sorted(rest))), walk)
    a, b = min(((p, q) for p in comp for q in main if abs(p[0] - q[0]) + abs(p[1] - q[1]) < 60),
               key=lambda pq: abs(pq[0][0] - pq[1][0]) + abs(pq[0][1] - pq[1][1]),
               default=(None, None))
    if a is None:
        walk -= comp   # demasiado lejos: se descarta
        continue
    x, y = a
    while (x, y) != b:
        if x != b[0]:
            x += 1 if b[0] > x else -1
        elif y != b[1]:
            y += 1 if b[1] > y else -1
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                walk.add((x + dx, y + dy))
WALK = walk

# distancia de cada casilla de vacío a la pasarela
dist = {p: 0 for p in WALK}
q = deque(WALK)
while q:
    c = q.popleft()
    for dx, dy in N4:
        nb = (c[0] + dx, c[1] + dy)
        if 0 <= nb[0] < W and 0 <= nb[1] < H and nb not in dist:
            dist[nb] = dist[c] + 1
            q.append(nb)

# ---------- lugares especiales ----------
cx, cy = SPAWN
AMY = (cx - 3, cy - 4)
CHEST = (cx + 3, cy - 4)
RETURN = (cx, cy + 5)            # teleport de vuelta a Lost Tower 7
BASINS = [(cx - 4, cy + 4), (cx + 4, cy + 4)]
for p in (AMY, CHEST, RETURN) + tuple(BASINS):
    assert p in SAFE, ('fuera de la zona segura', p)


def dcenter(p):
    return math.hypot(p[0] - cx, p[1] - cy)


ROOMS.sort(key=dcenter)
BOSS = ROOMS[-1]                 # Phoenix of Darkness: la plataforma más lejana del centro

items = {}
attrs = {}
flags = {p: PZ for p in SAFE}
ground = {}
AID_FIXED = b"\x04" + struct.pack("<H", 100)   # action id 100 = no se puede mover


def add(p, iid, attr=b''):
    items.setdefault(p, []).append(iid)
    if attr:
        attrs[p] = attr


room_cells = set()
for c in ROOMS:
    for dx in range(-3, 4):
        for dy in range(-3, 4):
            if dx * dx + dy * dy <= 10:
                room_cells.add((c[0] + dx, c[1] + dy))

# piso de las pasarelas
for p in WALK:
    if p in SAFE:
        d = max(abs(p[0] - cx), abs(p[1] - cy))
        ground[p] = MOSAIC if d <= 1 else (CARVED[0] if d <= 3 else STONE)
    elif p in room_cells:
        ground[p] = CARVED[0] if rng.random() < 0.85 else CARVED[1]
    else:
        ground[p] = rng.choice(STONE_VAR) if rng.random() < 0.08 else STONE

def make_noise(seed, cell):
    r = random.Random(seed)
    grid = {}

    def val(ix, iy):
        if (ix, iy) not in grid:
            grid[(ix, iy)] = r.random()
        return grid[(ix, iy)]

    def f(x, y):
        x /= cell
        y /= cell
        ix, iy = int(math.floor(x)), int(math.floor(y))
        fx, fy = x - ix, y - iy
        sx, sy = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy)
        a = val(ix, iy) * (1 - sx) + val(ix + 1, iy) * sx
        b = val(ix, iy + 1) * (1 - sx) + val(ix + 1, iy + 1) * sx
        return a * (1 - sy) + b * sy

    return f


void_noise = make_noise(77, 6)

# vacío: rojo cerca de la pasarela, cada vez más negro al alejarse
for x in range(W):
    for y in range(H):
        p = (x, y)
        if p in WALK:
            continue
        d = dist.get(p, 99)
        ground[p] = VOID_BLACK if d + 5 * void_noise(x, y) > 10 else rng.choice(VOID_RED)

# barandas de piedra blanca en el borde, con antorchas cada tanto.
# En Tibia la baranda se dibuja en el borde de abajo / derecho de su casilla: al norte y al oeste de la pasarela
# va en la casilla de vacío; al sur y al este va en la última casilla de la pasarela (que deja de pisarse).
RAILED = set()
torch_n = 0
KEEP_FREE = {(cx + dx, cy + dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1)} | {AMY, CHEST, RETURN}


def rail(p, horiz, vert):
    global torch_n
    if p in KEEP_FREE:
        return
    if horiz and vert:
        add(p, RAIL_CORNER)
    elif horiz:
        add(p, RAIL_H)
    elif vert:
        add(p, RAIL_V)
    else:
        return
    if p in WALK:
        RAILED.add(p)
    torch_n += 1
    if torch_n % 7 == 0:
        add(p, TORCH_H if horiz else TORCH_V)


for x in range(W):
    for y in range(H):
        p = (x, y)
        if p in WALK:
            rail(p, (x, y + 1) not in WALK, (x + 1, y) not in WALK)
        else:
            rail(p, (x, y + 1) in WALK, (x + 1, y) in WALK)

# pilares sueltos y cristales de colores flotando en el vacío
for p in sorted(ground):
    if p in WALK or p in items:
        continue
    d = dist.get(p, 99)
    r = rng.random()
    if d == 2 and r < 0.035:
        add(p, rng.choice(PILLARS))
    elif d == 3 and r < 0.03:
        add(p, rng.choice(CRYSTALS))
    elif 4 <= d <= 7 and r < 0.008:
        add(p, rng.choice(PILLARS + CRYSTALS))

# cristal de color junto a cada plataforma de respawn (como las columnas de luz de MU)
for i, c in enumerate(ROOMS):
    for dx, dy in ((0, -6), (6, 0), (0, 6), (-6, 0), (5, -5), (-5, 5)):
        p = (c[0] + dx, c[1] + dy)
        if p not in WALK and dist.get(p) in (1, 2) and p not in items:
            add(p, CRYSTALS[i % 4])
            break

# zona segura: Amy, el baúl, braseros; la casilla del teleport y el centro quedan libres
add(CHEST, DEPOT, b"\x0a" + struct.pack("<H", DEPOT_ID))
for b in BASINS:
    add(b, BASIN, AID_FIXED)
for dx, dy in ((-6, -6), (6, -6), (-6, 6), (6, 6)):
    p = (cx + dx, cy + dy)
    if p in SAFE and p not in items:
        add(p, PILLARS[0])
for p in SAFE:
    edge = any((p[0] + dx, p[1] + dy) not in SAFE for dx, dy in N4)
    if edge and (p[0] - cx) % 4 == 0 and (p[1] - cy) % 4 == 0 and p not in items and dcenter(p) > 3:
        pass  # sin decoración en el borde: la salida queda libre

tiles = {}
for p, g in ground.items():
    stack = [g] + items.get(p, [])
    tiles[(OX + p[0], OY + p[1], Z)] = [flags.get(p, 0), stack, attrs.get(p, b'') if p in items else b'']


def G(p):
    return (OX + p[0], OY + p[1], Z)


POIS = {
    'spawn': G(SPAWN),
    'amy': G(AMY),
    'chest': G(CHEST),
    'return': G(RETURN),
    'boss': G(BOSS),
}


def rooms_global():
    return [G(c) for c in ROOMS]


def walkable_global():
    return {G(p) for p in WALK - RAILED}


def safe_global():
    return {G(p) for p in SAFE}


if __name__ == '__main__':
    print('tamaño', W, H, 'tiles', len(tiles), 'caminables', len(WALK), 'zona segura', len(SAFE), 'salas', len(ROOMS))
    for k, v in POIS.items():
        print(k, v)
