"""Mubia Online: la Arena de MU (World7) con estilo Tibia, como zona de leveo.

La forma sale del EncTerrain7 de MU (solo como guía): un recinto de piedra lleno de jaulas con piso de arena
(14 jaulas, de los monstruos más débiles a los más fuertes), pasillos de piedra entre ellas, un jardín al oeste,
un campo abierto al sur con la plaza segura (llegada y Arena Guard) y el estadio de Battle Soccer al este.

Salida: tiles {(x, y, z): (flags, [ground, items...])} en coordenadas globales, CAGES y POIS.
Región vacía x1900-2091, y520-625, z7. Uso: ver build_arena.py.
"""
import math
import random

OX, OY, Z = 1900, 520, 7
W, H = 192, 106
rng = random.Random(7007)

# ---------- piezas ----------
GRASS = 4515
GRASS_VAR = [4518, 4519, 4520, 4521, 4522, 4524, 4525, 4526]
MOUNTAIN = 1128
WATER = 4597
SAND = 231
FLOOR = 7355          # pasillos de piedra del recinto
ROAD = 870            # caminos de afuera (adoquines)
PLAZA = 429           # plaza segura y gradas del estadio
GOAL = 463            # piso blanco de los arcos

B_MTN = dict(N=4445, E=4446, S=4447, W=4448, NW=4449, NE=4450, SE=4451, SW=4452, iNW=4453, iNE=4454, iSE=4455, iSW=4456)
B_WATER = dict(N=4633, E=4634, S=4635, W=4636, NW=4641, NE=4642, SE=4644, SW=4643, iNW=4637, iNE=4638, iSE=4640, iSW=4639)
B_GRASS_ON_PATH = dict(N=4531, E=4532, S=4533, W=4534, NW=4535, NE=4536, SE=4538, SW=4537, iNW=4539, iNE=4540, iSE=4542, iSW=4541)

STONE_WALL = dict(H=1295, V=1294, CORNER=1298, POLE=1296)
BARS = dict(H=2185, V=2184)
RAILING = dict(H=2222, V=2224, CORNER=2228, POLE=2226)
TREES = [3614, 3616, 3617, 3621, 3626, 7024, 957]
BUSHES = [3681, 3682, 3699, 3737]
CAGE_DECOR = [3114, 3115, 3115, 3132, 212, 213, 203, 204]
BASIN = 2110
STATUES = [2035, 2031]
BENCH_N, BENCH_W = 2370, 2372

ground = [["mtn"] * W for _ in range(H)]
items = {}
flags = {}
blocked = set()


def add(x, y, iid, block=True):
    items.setdefault((x, y), []).append(iid)
    if block:
        blocked.add((x, y))


def rect(x0, y0, x1, y1, kind):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            ground[y][x] = kind


def noise(seed, cell):
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


edge = noise(71, 6)

# ---------- terreno abierto (lo demás queda como montaña) ----------
# zona oeste/sur alrededor del recinto, el camino del este y el claro del estadio
OPEN = [(3, 3, 124, 104), (124, 40, 188, 84), (104, 3, 124, 40)]
for y in range(H):
    for x in range(W):
        for (x0, y0, x1, y1) in OPEN:
            d = min(x - x0, x1 - x, y - y0, y1 - y)
            if d >= 0 and d >= edge(x, y) * 3:
                ground[y][x] = "grass"
                break

# estanque del jardín oeste
for y in range(H):
    for x in range(W):
        if math.hypot(x - 10, (y - 16) * 0.7) < 4 + edge(x * 3, y * 3) * 1.5:
            ground[y][x] = "water"

# ---------- caminos de adoquines ----------
rect(109, 6, 113, 101, "road")    # camino principal norte-sur (el "888" del este)
rect(5, 87, 113, 90, "road")      # camino este-oeste del campo sur
rect(102, 54, 113, 58, "road")    # puerta este del recinto -> camino principal
rect(113, 60, 136, 64, "road")    # camino al estadio
rect(57, 73, 61, 87, "road")      # puerta sur del recinto -> campo sur

# ---------- plaza segura (llegada, Arena Guard, fuente) ----------
PZ = (44, 91, 72, 99)
rect(*PZ, "plaza")
for y in range(PZ[1], PZ[3] + 1):
    for x in range(PZ[0], PZ[2] + 1):
        flags[(x, y)] = 1
TEMPLE = (58, 96)

# ---------- recinto de las jaulas ----------
CX0, CY0, CX1, CY1 = 22, 5, 101, 72
rect(CX0, CY0, CX1, CY1, "floor")
walls = set()
for x in range(CX0, CX1 + 1):
    walls.update({(x, CY0), (x, CY1)})
for y in range(CY0, CY1 + 1):
    walls.update({(CX0, y), (CX1, y)})
GATES = set()
GATES.update((CX0, y) for y in range(36, 41))      # puerta oeste (jardín)
GATES.update((CX1, y) for y in range(54, 59))      # puerta este (camino principal)
GATES.update((x, CY1) for x in range(57, 62))      # puerta sur (campo y plaza segura)
rect(18, 36, 21, 40, "floor")                      # escalinata hacia el jardín

COLS = [(33, 44), (51, 62), (69, 80), (86, 98)]
ROWS = [((5, 16), "S"), ((23, 35), "N"), ((41, 53), "N")]
CAGES = []   # (x0, y0, x1, y1, lado de la puerta)
for (y0, y1), side in ROWS:
    for (x0, x1) in COLS:
        CAGES.append((x0, y0, x1, y1, side))
CAGES.append((33, 59, 56, 72, "N"))   # jaula 13: el pozo grande del suroeste
CAGES.append((62, 59, 98, 72, "N"))   # jaula 14: la jaula de los jefes

bars = set()
cage_inside = []
for (x0, y0, x1, y1, side) in CAGES:
    rect(x0 + 1, y0 + 1, x1 - 1, y1 - 1, "sand")
    cage_inside.append([(x, y) for y in range(y0 + 1, y1) for x in range(x0 + 1, x1)])
    gy = y1 if side == "S" else y0
    mid = (x0 + x1) // 2
    for x in range(x0, x1 + 1):
        for y in (y0, y1):
            if y == gy and x0 + 1 < x < x1 - 1:
                if mid - 1 <= x <= mid + 1:
                    GATES.add((x, y))      # entrada de 3 casillas
                else:
                    bars.add((x, y))       # rejas: se ve adentro pero no se pasa
            else:
                walls.add((x, y))
    for y in range(y0, y1 + 1):
        walls.update({(x0, y), (x1, y)})
walls -= GATES
walls -= bars
for (x, y) in GATES:
    if ground[y][x] in ("mtn", "grass"):
        ground[y][x] = "floor"
    if ground[y][x] == "sand":
        ground[y][x] = "floor"
for (x, y) in walls | bars:
    if ground[y][x] in ("sand", "grass", "mtn"):
        ground[y][x] = "floor"


def wall_piece(cells, x, y, kind):
    n = (x, y - 1) in cells
    s = (x, y + 1) in cells
    e = (x + 1, y) in cells
    w = (x - 1, y) in cells
    if e and s:
        return kind["CORNER"]
    if (n or s) and (e or w):
        return kind["POLE"]
    if n or s:
        return kind["V"]
    return kind["H"]


solid = walls | bars
for (x, y) in walls:
    add(x, y, wall_piece(solid, x, y, STONE_WALL))
for (x, y) in bars:
    add(x, y, BARS["V"] if ((x, y - 1) in solid or (x, y + 1) in solid) and not ((x - 1, y) in solid or (x + 1, y) in solid) else BARS["H"])

# braseros en los cruces de pasillos
for (x, y) in ((23, 17), (32, 17), (23, 40), (32, 40), (23, 58), (32, 58), (99, 17), (100, 40), (99, 58)):
    add(x, y, BASIN)

# ---------- estadio de Battle Soccer ----------
SX0, SY0, SX1, SY1 = 136, 46, 185, 77
rect(SX0, SY0, SX1, SY1, "plaza")
swalls = set()
for x in range(SX0, SX1 + 1):
    swalls.update({(x, SY0), (x, SY1)})
for y in range(SY0, SY1 + 1):
    swalls.update({(SX0, y), (SX1, y)})
swalls -= {(SX0, y) for y in range(60, 65)}            # entrada oeste
for (x, y) in swalls:
    add(x, y, wall_piece(swalls, x, y, STONE_WALL))
FX0, FY0, FX1, FY1 = 142, 53, 179, 70                  # la cancha
rect(FX0, FY0, FX1, FY1, "field")
rails = set()
for x in range(FX0 - 1, FX1 + 2):
    rails.update({(x, FY0 - 1), (x, FY1 + 1)})
for y in range(FY0 - 1, FY1 + 2):
    rails.update({(FX0 - 1, y), (FX1 + 1, y)})
rails -= {(x, FY0 - 1) for x in range(159, 163)}       # entradas a la cancha (norte y sur)
rails -= {(x, FY1 + 1) for x in range(159, 163)}
for (x, y) in rails:
    add(x, y, wall_piece(rails, x, y, RAILING))
for y in range(60, 64):                                 # arcos
    ground[y][FX0] = "goal"
    ground[y][FX1] = "goal"
for (x, y) in rails:
    ground[y][x] = "plaza"
# gradas: bancos mirando a la cancha
for x in range(SX0 + 3, SX1 - 2, 2):
    for y in (SY0 + 2, SY0 + 4, SY1 - 4, SY1 - 2):
        if not (159 <= x <= 162):
            add(x, y, BENCH_N, block=False)
for y in range(SY0 + 7, SY1 - 6, 2):
    for x in (SX0 + 2, SX1 - 2):
        if not (59 <= y <= 65):
            add(x, y, BENCH_W, block=False)
for (x, y) in ((SX0 + 2, 59), (SX0 + 2, 65)):
    add(x, y, BASIN)
STADIUM_PZ = set()
for y in range(SY0 + 1, SY1):
    for x in range(SX0 + 1, SX1):
        if ground[y][x] == "plaza":
            STADIUM_PZ.add((x, y))
FIELD = {(x, y) for y in range(FY0, FY1 + 1) for x in range(FX0, FX1 + 1)}

# ---------- plaza segura: fuente/estatuas y faroles ----------
add(52, 93, STATUES[0])
add(64, 93, STATUES[0])
add(58, 92, STATUES[1])
for (x, y) in ((45, 92), (71, 92), (45, 98), (71, 98)):
    add(x, y, BASIN)
ARENA_GUARD = (54, 95)

# ---------- decoración ----------
for k, inside in enumerate(cage_inside):
    for (x, y) in inside:
        if rng.random() < 0.035:
            add(x, y, rng.choice(CAGE_DECOR), block=False)
    x0, y0, x1, y1, side = CAGES[k]
    for (x, y) in ((x0 + 1, y0 + 1), (x1 - 1, y0 + 1), (x0 + 1, y1 - 1), (x1 - 1, y1 - 1)):
        if (x, y) not in blocked and abs(y - (y1 if side == "S" else y0)) > 1:
            add(x, y, BASIN)


def near(x, y, kinds, r=1):
    return any(0 <= x + dx < W and 0 <= y + dy < H and ground[y + dy][x + dx] in kinds
               for dx in range(-r, r + 1) for dy in range(-r, r + 1))


tree_spots = set()
for y in range(1, H - 1):
    for x in range(1, W - 1):
        if ground[y][x] != "grass" or (x, y) in items:
            continue
        if near(x, y, ("road", "plaza", "floor", "field", "goal"), 1):
            continue
        dense = x < 20 or y < 3 or near(x, y, ("mtn",), 2)
        r = rng.random()
        if r < (0.22 if dense else 0.03) and not any((x + dx, y + dy) in tree_spots for dx in (-1, 0, 1) for dy in (-1, 0, 1)):
            add(x, y, rng.choice(TREES))
            tree_spots.add((x, y))
        elif r < (0.30 if dense else 0.06):
            add(x, y, rng.choice(BUSHES), block=False)

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


def g(x, y):
    if 0 <= x < W and 0 <= y < H:
        return ground[y][x]
    return "mtn"


PAVED = ("road", "plaza", "floor")
borders = {}
for y in range(H):
    for x in range(W):
        t = ground[y][x]
        b = []
        if t in ("grass",) + PAVED:
            for p in border_pieces(x, y, lambda a, c: g(a, c) == "water"):
                b.append(B_WATER[p])
        if t in ("grass", "road"):
            for p in border_pieces(x, y, lambda a, c: g(a, c) == "mtn"):
                b.append(B_MTN[p])
        if t in PAVED:
            for p in border_pieces(x, y, lambda a, c: g(a, c) == "grass"):
                b.append(B_GRASS_ON_PATH[p])
        if b:
            borders[(x, y)] = b

# ---------- armar tiles ----------
PROTECTION, PVP = 1, 16
tiles = {}
for y in range(H):
    for x in range(W):
        t = ground[y][x]
        if t == "grass" or t == "field":
            gid = rng.choice(GRASS_VAR) if rng.random() < 0.08 else GRASS
        else:
            gid = dict(mtn=MOUNTAIN, water=WATER, sand=SAND, floor=FLOOR, road=ROAD, plaza=PLAZA, goal=GOAL)[t]
        f = flags.get((x, y), 0)
        if (x, y) in STADIUM_PZ:
            f |= PROTECTION
        if (x, y) in FIELD:
            f |= PVP
        stack = [gid] + borders.get((x, y), []) + items.get((x, y), [])
        tiles[(OX + x, OY + y, Z)] = (f, stack)


def G(p):
    return (OX + p[0], OY + p[1], Z)


def walkable_inside(k):
    return [G(p) for p in cage_inside[k] if p not in blocked]


POIS = {
    "temple": G(TEMPLE),
    "arena_guard": G(ARENA_GUARD),
    "stadium": G((160, 61)),
    "cages": [(G(c[:2]), G(c[2:4])) for c in CAGES],
}
