"""Genera Aida 1 y 2 (MU, World34) como un bosque de Tibia al estilo de Ab'dendriel.

La forma (claros, caminos, lagunas y paredes de bosque) sale de Data/World34 del cliente de MU
(EncTerrain34.att y EncTerrain34.map, decodificados en aida_mu.pkl), pero se dibuja con piezas de Tibia:
- piso caminable de MU con pasto -> suelo de bosque de Ab'dendriel (con pastitos, flores y helechos)
- piso caminable de MU con tierra -> tierra con bordes de bosque
- piso caminable de MU con roca -> pasto (prados)
- lo bloqueado de MU -> bosque cerrado (un árbol en cada casilla); lagunas donde MU tiene agua
- columnas chicas de MU -> un árbol suelto (en las ruinas del norte, columnas de piedra)

x local = índice // 256, y local = índice % 256 (igual que el minimapa de MU, norte arriba).
Aida 1 empieza en la zona segura del oeste (la única zona protegida), con Potion Girl Amy y un baúl.
Aida 2 es el punto rojo que marcó Genaro, al sureste.

Salida: tiles {(x, y, z): [flags, [ground, items...], attrs]} en coordenadas globales y POIS.
"""
import math
import os
import pickle
import random
import struct
from collections import deque

HERE = os.path.dirname(os.path.abspath(__file__))
att, tex = pickle.load(open(os.path.join(HERE, 'aida_mu.pkl'), 'rb'))
rng = random.Random(3434)

OX, OY, Z = 1300, 1320, 7
W = H = 256
PZ = 1   # flag de zona protegida en el otbm


def A(x, y):
    if 0 <= x < W and 0 <= y < H:
        return att[x * 256 + y]
    return 4


def T(x, y):
    if 0 <= x < W and 0 <= y < H:
        return tex[x * 256 + y]
    return 0


def walk_mu(p):
    return A(*p) & 12 == 0


# ---------- piezas de Tibia (Ab'dendriel) ----------
FOREST = 18459
FOREST_VAR = [18460, 18461, 18462, 18463, 18464]
GRASS = 4515
GRASS_VAR = [4518, 4519, 4521, 4522, 4525, 4526, 4527, 4528]
DIRT = 103
WATER = 4597

B_FOREST = dict(N=18796, E=18807, S=18806, W=18797, NW=18798, NE=18799, SE=18801, SW=18800, iNW=18802, iNE=18803, iSE=18805, iSW=18804)
B_WATER = dict(N=4633, E=4634, S=4635, W=4636, NW=4641, NE=4642, SE=4644, SW=4643, iNW=4637, iNE=4638, iSE=4640, iSW=4639)
B_GRASS_ON_DIRT = dict(N=4531, E=4532, S=4533, W=4534, NW=4535, NE=4536, SE=4538, SW=4537, iNW=4539, iNE=4540, iSE=4542, iSW=4541)

# árboles de Ab'dendriel (no se pasan): abetos, hayas, arces rojos y amarillos, ciruelos, perales
TREES = [3614, 3614, 3614, 3621, 3621, 3622, 3615, 3616, 3616, 3617, 3617, 3619, 3682, 3618, 3620]
WALL_TREES = TREES + [3614, 3614, 3621, 3616, 3615, 3617, 3681]
EDGE_PLANTS = [18866, 18867, 18870, 18871, 18873, 18874]     # helechos (se pisan) al pie de los árboles
TUFTS = [6217, 6218, 6218, 21935, 21935]                      # pastitos y flores chicas (se pisan)
FLOWERS = [3653, 3654, 3657, 3892, 6219, 6220]                # trigo, flores, enredaderas (se pisan)
SMALL = [13762, 13763, 13764, 13765, 1855, 1856, 15211]       # musgo, piedritas (se pisan)
FIREFLIES = [6493, 6497]
BUSHES = [3681, 3682, 3696]                                   # arbustos (no se pasan)
STONES = [1772, 1791]
PILLAR = 7708
BROKEN_PILLAR = 8389
RUBBLE = [5618, 5619, 5620, 5621, 5622, 5623]
LAMPION = 25409
BENCH = 25240
DEPOT = 3499
DEPOT_ID = 10          # mismo depot que Noria (Aida es el bosque de las elfas)
CHESTS = [2472, 2480]
CRATE = 2471
HEDGE_H = [2706, 2707, 2712]
HEDGE_V = [2708, 2709, 2713]
AID_FIXED = b"\x04" + struct.pack("<H", 100)   # action id 100 = no se puede mover

N4 = ((1, 0), (-1, 0), (0, 1), (0, -1))
AROUND = [(dx, dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1)]

# puntos que marcó Genaro sobre el mapa de MU (imagen de 1024 px -> casillas = px / 4)
SPAWN_MARK = (10, 86)     # blanco: donde aparece el jugador en Aida
AMY_MARK = (16, 80)       # celeste: Potion Girl Amy (y el baúl cerca)
AIDA2_MARK = (177, 191)   # rojo: Aida 2


def flood(seed, ok):
    seen = {seed}
    q = deque([seed])
    while q:
        x, y = q.popleft()
        for dx, dy in N4:
            p = (x + dx, y + dy)
            if p not in seen and ok(p):
                seen.add(p)
                q.append(p)
    return seen


ALL_WALK = [(i // 256, i % 256) for i in range(65536) if att[i] & 12 == 0]


def nearest(cells, target, ok=lambda p: True):
    return min((p for p in cells if ok(p)), key=lambda p: (p[0] - target[0]) ** 2 + (p[1] - target[1]) ** 2)


WALK = flood(nearest(ALL_WALK, SPAWN_MARK), walk_mu)
SAFE = {p for p in WALK if A(*p) & 1}


def roomy(cells, p, r):
    return all((p[0] + dx, p[1] + dy) in cells for dx in range(-r, r + 1) for dy in range(-r, r + 1))


# ---------- tipo de suelo de cada casilla caminable (según la textura de MU, suavizado) ----------
def kind_mu(p):
    t = T(*p)
    if t in (0, 1):
        return 'forest'
    if t in (2, 3, 4, 6):
        return 'dirt'
    return 'grass'


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


dirt_noise = make_noise(41, 7)

ground = {}
for p in WALK:
    k = kind_mu(p)
    # la tierra de MU queda como manchas de tierra dentro del suelo de bosque (no todo pelado)
    if k == 'dirt' and dirt_noise(*p) < 0.45:
        k = 'forest'
    ground[p] = k
# suavizado (mayoría en 5x5), dos pasadas, para que no queden casillas sueltas
for _ in range(2):
    new = {}
    for p in WALK:
        cnt = {}
        for dx in range(-2, 3):
            for dy in range(-2, 3):
                q = (p[0] + dx, p[1] + dy)
                if q in ground:
                    cnt[ground[q]] = cnt.get(ground[q], 0) + 1
        new[p] = max(cnt, key=lambda k: (cnt[k], k == ground[p]))
    ground = new
# la zona segura es un prado
for p in SAFE:
    ground[p] = 'grass'

# ---------- lo bloqueado: bosque y lagunas ----------
blocked_near = set()
for (x, y) in WALK:
    for dx in range(-12, 13):
        for dy in range(-12, 13):
            q = (x + dx, y + dy)
            if q not in WALK and 0 <= q[0] < W and 0 <= q[1] < H:
                blocked_near.add(q)

# componentes bloqueadas encerradas por piso: columnas chicas (árbol suelto) o lagunas/islas de bosque
near = {(x + dx, y + dy) for (x, y) in WALK for dx, dy in AROUND} - WALK
pillars, islands = set(), set()
seen = set()
for p in sorted(near):
    if p in seen:
        continue
    comp, q, closed = {p}, deque([p]), True
    seen.add(p)
    while q:
        c = q.popleft()
        for dx, dy in N4:
            nb = (c[0] + dx, c[1] + dy)
            if nb in WALK:
                continue
            if nb not in blocked_near:
                closed = False
                continue
            if nb not in seen:
                seen.add(nb)
                comp.add(nb)
                q.append(nb)
    if closed and len(comp) <= 4:
        pillars |= comp
    elif closed:
        islands |= comp

# distancia de cada casilla bloqueada a lo caminable
dist = {p: 0 for p in WALK}
q = deque(WALK)
while q:
    c = q.popleft()
    for dx, dy in N4:
        nb = (c[0] + dx, c[1] + dy)
        if 0 <= nb[0] < W and 0 <= nb[1] < H and nb not in dist:
            dist[nb] = dist[c] + 1
            q.append(nb)

for x in range(W):
    for y in range(H):
        p = (x, y)
        if p in WALK:
            continue
        t = T(x, y)
        if p in pillars:
            ground[p] = 'pillar'
        elif t == 5 and dist[p] >= 1:
            ground[p] = 'water'
        else:
            ground[p] = 'woods'
# las lagunas: agua de MU dentro de lo bloqueado, con al menos una casilla de bosque alrededor del borde del mapa
for p in list(ground):
    if ground[p] == 'water' and min(p[0], p[1], W - 1 - p[0], H - 1 - p[1]) < 2:
        ground[p] = 'woods'
# sacar lagunas sueltas (manchas de menos de 6 casillas)
for kind in ('water',):
    done = set()
    for p in [k for k, v in ground.items() if v == kind]:
        if p in done:
            continue
        comp = flood(p, lambda c, kind=kind: ground.get(c) == kind)
        done |= comp
        if len(comp) < 6:
            for c in comp:
                ground[c] = 'woods'

# ---------- lugares especiales ----------
SPAWN = nearest(SAFE, SPAWN_MARK, lambda p: roomy(SAFE, p, 1))
AMY = nearest(SAFE, AMY_MARK, lambda p: roomy(WALK, p, 1) and max(abs(p[0] - SPAWN[0]), abs(p[1] - SPAWN[1])) >= 3)
CHEST = nearest(SAFE, (AMY[0] + 4, AMY[1]), lambda p: roomy(WALK, p, 1) and max(abs(p[0] - AMY[0]), abs(p[1] - AMY[1])) >= 3
                and max(abs(p[0] - SPAWN[0]), abs(p[1] - SPAWN[1])) >= 3)
AIDA2 = nearest(WALK, AIDA2_MARK, lambda p: roomy(WALK, p, 2))
# el jefe Hell Maine: en el claro de las ruinas del noroeste (la plaza con columnas de MU)
BOSS = nearest(WALK, (40, 37), lambda p: roomy(WALK, p, 2))
KEEP = [SPAWN, AMY, CHEST, AIDA2]

items = {}
attrs = {}
flags = {}


def add(p, iid, attr=b''):
    items.setdefault(p, []).append(iid)
    if attr:
        attrs[p] = attr


def near_keep(p, r=2):
    return any(abs(p[0] - k[0]) <= r and abs(p[1] - k[1]) <= r for k in KEEP)


NORTH_RUINS = lambda p: p[1] < 62   # las salas de paredes rectas del norte de MU: ruinas élficas

# bosque cerrado: un árbol (o arbusto) en cada casilla
for p, g in ground.items():
    if g == 'woods':
        if dist[p] <= 1 and rng.random() < 0.35:
            add(p, rng.choice(BUSHES))
        else:
            add(p, rng.choice(WALL_TREES))
    elif g == 'pillar':
        if NORTH_RUINS(p):
            add(p, rng.choice([PILLAR, PILLAR, BROKEN_PILLAR]))
        else:
            add(p, rng.choice(TREES + STONES))

# decoración del piso caminable
for p in sorted(WALK):
    if near_keep(p, 1) or p in SAFE:
        continue
    g = ground[p]
    r = rng.random()
    edge = any(ground.get((p[0] + dx, p[1] + dy)) in ('woods', 'pillar') for dx, dy in N4)
    open5 = roomy(WALK, p, 2)
    if open5 and r < 0.025 and not any((p[0] + dx, p[1] + dy) in items and items[(p[0] + dx, p[1] + dy)][0] in TREES + BUSHES
                                       for dx in range(-3, 4) for dy in range(-3, 4)):
        # algún árbol o arbusto suelto en los claros grandes (sin cerrar pasillos)
        add(p, rng.choice(TREES + BUSHES))
    elif edge and r < 0.30:
        add(p, rng.choice(EDGE_PLANTS + TUFTS))
    elif g == 'forest' and r < 0.50:
        add(p, rng.choice(TUFTS + TUFTS + SMALL + FIREFLIES + EDGE_PLANTS[4:]))
    elif g == 'grass' and r < 0.22:
        add(p, rng.choice(FLOWERS + TUFTS))
    elif g == 'dirt' and r < 0.10:
        add(p, rng.choice(SMALL[4:] + [21935, 6219, 6220]))
    if NORTH_RUINS(p) and p not in items and rng.random() < 0.025:
        add(p, rng.choice(RUBBLE), AID_FIXED)

# ---------- zona segura: prado con setos, faroles, Amy y el baúl ----------
for p in SAFE:
    flags[p] = PZ
for p in sorted(SAFE):
    if near_keep(p, 1):
        continue
    edge_out = any((p[0] + dx, p[1] + dy) not in SAFE and (p[0] + dx, p[1] + dy) in WALK for dx, dy in N4)
    if edge_out:
        continue   # la salida de la zona segura queda libre
    r = rng.random()
    if r < 0.30:
        add(p, rng.choice(FLOWERS + TUFTS))
    elif r < 0.34:
        add(p, rng.choice(FIREFLIES))
add(CHEST, DEPOT, b"\x0a" + struct.pack("<H", DEPOT_ID))
for dx, dy, it in ((-1, 0, CHESTS[0]), (1, 0, CRATE)):
    q2 = (CHEST[0] + dx, CHEST[1] + dy)
    if q2 in SAFE and q2 not in (AMY, SPAWN):
        items[q2] = [it]
        attrs[q2] = AID_FIXED
for dx, dy in ((-1, -1), (1, -1)):
    q2 = (AMY[0] + dx, AMY[1] + dy)
    if q2 in SAFE and q2 not in (CHEST, SPAWN):
        items[q2] = [LAMPION]
        attrs.pop(q2, None)
# casillas que quedan limpias para pararse
for k in (SPAWN, AMY, AIDA2):
    for dx, dy in AROUND:
        q2 = (k[0] + dx, k[1] + dy)
        if q2 in WALK and q2 not in (CHEST,) and not (k == AMY and dy == -1 and dx != 0):
            if q2 in items and items[q2][0] in (DEPOT, CHESTS[0], CRATE, LAMPION):
                continue
            items.pop(q2, None)
            attrs.pop(q2, None)


# ---------- bordes ----------
DIRS = dict(NW=(-1, -1), N=(0, -1), NE=(1, -1), E=(1, 0), SE=(1, 1), S=(0, 1), SW=(-1, 1), W=(-1, 0))


def border_pieces(x, y, is_other):
    o = {k: is_other(x + dx, y + dy) for k, (dx, dy) in DIRS.items()}
    out = []
    n, e, s, w = o["N"], o["E"], o["S"], o["W"]
    if n and w:
        out.append("iNW")
    if n and e:
        out.append("iNE")
    if s and e:
        out.append("iSE")
    if s and w:
        out.append("iSW")
    if n and not (w or e):
        out.append("N")
    if s and not (w or e):
        out.append("S")
    if w and not (n or s):
        out.append("W")
    if e and not (n or s):
        out.append("E")
    if o["NW"] and not n and not w:
        out.append("NW")
    if o["NE"] and not n and not e:
        out.append("NE")
    if o["SE"] and not s and not e:
        out.append("SE")
    if o["SW"] and not s and not w:
        out.append("SW")
    return out


def base(p):
    g = ground.get(p, 'woods')
    return 'forest' if g in ('woods', 'pillar') else g


borders = {}
for p, g in ground.items():
    x, y = p
    b = []
    bg = base(p)
    if bg != 'water':
        for k in border_pieces(x, y, lambda a, c: ground.get((a, c)) == 'water'):
            b.append(B_WATER[k])
    if bg == 'dirt':
        for k in border_pieces(x, y, lambda a, c: base((a, c)) == 'grass'):
            b.append(B_GRASS_ON_DIRT[k])
    if bg in ('grass', 'dirt'):
        for k in border_pieces(x, y, lambda a, c: base((a, c)) == 'forest'):
            b.append(B_FOREST[k])
    if b:
        borders[p] = b

# ---------- armar tiles ----------
tiles = {}
for p, g in ground.items():
    bg = base(p)
    if bg == 'forest':
        gid = rng.choice(FOREST_VAR) if rng.random() < 0.2 else FOREST
    elif bg == 'grass':
        gid = rng.choice(GRASS_VAR) if rng.random() < 0.08 else GRASS
    elif bg == 'dirt':
        gid = DIRT
    elif bg == 'water':
        gid = WATER
    stack = [gid] + borders.get(p, []) + items.get(p, [])
    tiles[(OX + p[0], OY + p[1], Z)] = [flags.get(p, 0), stack, attrs.get(p, b'') if p in items else b'']


def G(p):
    return (OX + p[0], OY + p[1], Z)


POIS = {
    'spawn': G(SPAWN),
    'aida2': G(AIDA2),
    'amy': G(AMY),
    'chest': G(CHEST),
    'boss': G(BOSS),
}


def walkable_global():
    return {G(p) for p in WALK}


def safe_global():
    return {G(p) for p in SAFE}


if __name__ == '__main__':
    print('tiles', len(tiles), 'caminables', len(WALK), 'zona segura', len(SAFE))
    for k, v in POIS.items():
        print(k, v)
