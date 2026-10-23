"""Genera Noria (MU, la ciudad de las Elfas) con el estilo de Feyrist (Tibia): lush meadow, caminos de piedra,
bosque con forest floor, hayas, casas-planta, casas-hongo, caracoles, faroles de árbol, hongos, velas y cristales.
Salida: dict (x,y,z) -> (flags, [ground, items...]) en coordenadas globales, y metadatos (POIS)."""
import math, random

OX, OY, Z = 1160, 520, 7
W = H = 256
rng = random.Random(2468)

# ---------- piezas de Feyrist ----------
MEADOW = 25269
MEADOW_VAR = [25273, 25274, 25275, 25276, 25277, 25278, 25279, 25280, 25281, 25282]
PATH = 25245
PATH_VAR = list(range(25246, 25257))
FOREST = 18460
WATER = 4597
MOUNTAIN = 1128
BRIDGE = 1771
GRASS = 4515
GRASS_VAR = [4518, 4519, 4520, 4521, 4522, 4524, 4525, 4526]

# bordes: N E S W, esquinas exteriores NW NE SE SW, interiores iNW iNE iSE iSW (aprendidos del mapa de Feyrist)
B_PATH = dict(N=25258, E=25259, S=25257, W=25260, NW=25264, NE=25263, SE=25261, SW=25262, iNW=25268, iNE=25267, iSE=25265, iSW=25266)
B_FOREST = dict(N=18796, E=18807, S=18806, W=18797, NW=18798, NE=18799, SE=18801, SW=18800, iNW=18802, iNE=18803, iSE=18805, iSW=18804)
B_WATER = dict(N=4633, E=4634, S=4635, W=4636, NW=4641, NE=4642, SE=4644, SW=4643, iNW=4637, iNE=4638, iSE=4640, iSW=4639)
B_MEADOW = dict(N=25284, E=25285, S=25283, W=25286, NW=25290, NE=25289, SE=25287, SW=25288, iNW=25294, iNE=25293, iSE=25291, iSW=25292)
B_GRASS_ON_PATH = dict(N=4531, E=4532, S=4533, W=4534, NW=4535, NE=4536, SE=4538, SW=4537, iNW=4539, iNE=4540, iSE=4542, iSW=4541)
PERGOLA = dict(NW=25333, NE=25334, SW=25335, SE=25336, H=25338, V=25337)
HANGING_FLOWERS = [6225, 6226, 6227, 6229]
B_MTN = dict(N=4445, E=4446, S=4447, W=4448, NW=4449, NE=4450, SE=4451, SW=4452, iNW=4453, iNE=4454, iSE=4455, iSW=4456)

BEECHES = [25468, 25469, 25470, 25471, 25472, 25473, 25474, 25475]
MAGIC_TREES = [25467, 25403, 25404, 25398, 25397, 25400, 25399, 25401, 25402, 25309, 25477, 25478, 9225]
FOREST_SMALL = [18869, 18870, 18871, 18872, 25388, 25394, 3918, 3919, 3914, 3915, 15209, 15211]
MEADOW_SMALL = [3890, 3888, 3889, 3892, 3893, 3656, 25382, 25358, 25356, 25357] + list(range(24845, 24861))
BIG_MORELS = [25392, 25390]
LAMPION = 25409
FOUNTAIN = 25411
BENCH = 25240
PLANT_HOUSES = [25312, 25314, 25316, 25318, 25320]
MUSHROOM_HOUSE = 25332
LOG_HOUSE = 25322
SNAIL_V = (25326, 25325)  # arriba, abajo
SNAIL_H = (25329, 25330)  # izquierda, derecha

ground = [["meadow"] * W for _ in range(H)]
items = {}
flags = {}
blocked = set()


def add(lx, ly, iid):
    items.setdefault((lx, ly), []).append(iid)


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


edge_noise = make_noise(11, 9)
forest_noise = make_noise(12, 20)
detail_noise = make_noise(13, 5)

CENTER = (128, 128)
TOWN_R = 30


def town_r(x, y):
    a = math.atan2(y - CENTER[1], x - CENTER[0])
    return TOWN_R + 3 * math.sin(a * 3 + 1) + 2 * math.sin(a * 5)


def in_town(x, y, pad=0):
    return math.hypot(x - CENTER[0], y - CENTER[1]) <= town_r(x, y) + pad


# ---------- montañas alrededor ----------
for y in range(H):
    for x in range(W):
        d = min(x, W - 1 - x, H - 1 - y)
        if d < 4 + edge_noise(x, y) * 5 or y < 7 + edge_noise(x, y) * 8:
            ground[y][x] = "mtn"

# ---------- bosque (forest floor bajo las hayas) ----------
for y in range(H):
    for x in range(W):
        if ground[y][x] == "meadow" and forest_noise(x, y) > 0.56 and not in_town(x, y, 6):
            ground[y][x] = "forest"

# ---------- arroyo, estanque y lago ----------
STREAM = [(150, 0), (156, 40), (160, 70), (164, 96), (166, 112)]
STREAM2 = [(166, 140), (160, 170), (150, 200), (142, 230), (140, 255)]
POND = (167, 126, 9)


def carve_stream(points, width):
    for (ax, ay), (bx, by) in zip(points, points[1:]):
        steps = int(max(abs(bx - ax), abs(by - ay)) * 2) + 1
        for i in range(steps + 1):
            t = i / steps
            px = ax + (bx - ax) * t + 3 * math.sin((ay + (by - ay) * t) / 11.0)
            py = ay + (by - ay) * t
            for y in range(int(py - width - 1), int(py + width + 2)):
                for x in range(int(px - width - 1), int(px + width + 2)):
                    if 0 <= x < W and 0 <= y < H and math.hypot(x - px, y - py) <= width:
                        ground[y][x] = "water"


carve_stream(STREAM, 2.2)
carve_stream(STREAM2, 2.2)
for y in range(H):
    for x in range(W):
        if math.hypot(x - POND[0], (y - POND[1]) * 1.15) < POND[2] + edge_noise(x * 3, y * 3) * 2:
            ground[y][x] = "water"
LAKE = (52, 92, 11)
for y in range(H):
    for x in range(W):
        if math.hypot(x - LAKE[0], (y - LAKE[1]) * 1.3) < LAKE[2] + edge_noise(x * 2, y * 2) * 4 and ground[y][x] != "mtn":
            ground[y][x] = "water"

glade_noise = make_noise(14, 11)
for y in range(H):
    for x in range(W):
        if ground[y][x] == "meadow" and glade_noise(x, y) > 0.68:
            ground[y][x] = "grass"
PONDS = [(70, 60, 4), (200, 70, 5), (90, 190, 4), (210, 200, 4), (40, 170, 3), (185, 40, 3), (60, 230, 3)]
for (px, py, pr) in PONDS:
    for y in range(py - pr - 3, py + pr + 4):
        for x in range(px - pr - 3, px + pr + 4):
            if math.hypot(x - px, (y - py) * 1.2) < pr + edge_noise(x * 3, y * 3) * 1.5 and ground[y][x] != "mtn":
                ground[y][x] = "water"

# ---------- pueblo: claro de pasto verde rodeado de pradera, zona protegida ----------
for y in range(H):
    for x in range(W):
        if in_town(x, y) and ground[y][x] != "water":
            ground[y][x] = "grass" if in_town(x, y, -4) else "meadow"
            flags[(x, y)] = 1

# plaza redonda de piedra
PLAZA_R = 7.5
for y in range(H):
    for x in range(W):
        if math.hypot(x - CENTER[0], y - CENTER[1]) <= PLAZA_R:
            ground[y][x] = "path"
            blocked.add((x, y))

ROADS = [
    [(128, 122), (126, 90), (120, 60), (124, 30), (122, 12)],
    [(128, 134), (130, 170), (124, 205), (128, 240)],
    [(120, 128), (90, 132), (60, 126), (30, 130), (10, 128)],
    [(136, 128), (150, 130), (180, 128), (215, 134), (245, 128)],
]


def draw_road(points, width=0.9):
    for (ax, ay), (bx, by) in zip(points, points[1:]):
        steps = int(max(abs(bx - ax), abs(by - ay)) * 2) + 1
        for i in range(steps + 1):
            t = i / steps
            px = ax + (bx - ax) * t + (detail_noise(ax + i, ay) - 0.5) * 1.5
            py = ay + (by - ay) * t + (detail_noise(ax, ay + i) - 0.5) * 1.5
            for y in range(int(py - width - 1), int(py + width + 2)):
                for x in range(int(px - width - 1), int(px + width + 2)):
                    if 0 <= x < W and 0 <= y < H and math.hypot(x - px, y - py) <= width:
                        g = ground[y][x]
                        if g == "water":
                            ground[y][x] = "bridge"
                        elif g in ("meadow", "forest", "grass"):
                            ground[y][x] = "path"
                        elif g == "mtn" and min(x, y, W - 1 - x, H - 1 - y) > 0:
                            ground[y][x] = "path"
                        blocked.add((x, y))


for r in ROADS:
    draw_road(r)


def straighten_bridges():
    seen = set()
    cells = [(x, y) for y in range(H) for x in range(W) if ground[y][x] == "bridge"]
    for c in cells:
        if c in seen:
            continue
        stack, grp = [c], []
        seen.add(c)
        while stack:
            cx, cy = stack.pop()
            grp.append((cx, cy))
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    n = (cx + dx, cy + dy)
                    if n not in seen and 0 <= n[0] < W and 0 <= n[1] < H and ground[n[1]][n[0]] == "bridge":
                        seen.add(n)
                        stack.append(n)
        for (x, y) in grp:
            ground[y][x] = "water"
        xs = [x for x, _ in grp]
        ys = [y for _, y in grp]
        if (max(xs) - min(xs)) >= (max(ys) - min(ys)):
            my = sorted(ys)[len(ys) // 2]
            for y in range(my - 1, my + 2):
                x = min(xs) - 1
                while x > 0 and ground[y][x] == "water":
                    x -= 1
                x2 = max(xs) + 1
                while x2 < W - 1 and ground[y][x2] == "water":
                    x2 += 1
                for k in range(x + 1, x2):
                    ground[y][k] = "bridge"
                    blocked.add((k, y))
                for k in (x, x - 1, x2, x2 + 1):
                    if ground[y][k] in ("meadow", "forest", "grass"):
                        ground[y][k] = "path"
        else:
            mx = sorted(xs)[len(xs) // 2]
            for x in range(mx - 1, mx + 2):
                y = min(ys) - 1
                while y > 0 and ground[y][x] == "water":
                    y -= 1
                y2 = max(ys) + 1
                while y2 < H - 1 and ground[y2][x] == "water":
                    y2 += 1
                for k in range(y + 1, y2):
                    ground[k][x] = "bridge"
                    blocked.add((x, k))
                for k in (y, y - 1, y2, y2 + 1):
                    if ground[k][x] in ("meadow", "forest", "grass"):
                        ground[k][x] = "path"


straighten_bridges()


# ---------- pérgolas de pilares (las "casas" de Feyrist) y casitas de hadas ----------
def reserve(x, y, r=2):
    for dy in range(-r - 1, r):
        for dx in range(-r - 1, r):
            blocked.add((x + dx, y + dy))


def pergola(x0, y0, x1, y1, door):
    """Marco de pilares de x0,y0 a x1,y1 con una abertura (lado, desde, hasta) y flores colgando arriba."""
    side, a, b = door
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            ground[y][x] = "grass"
            blocked.add((x, y))
    for x in range(x0, x1 + 1):
        for y in (y0, y1):
            if (side == "N" and y == y0 or side == "S" and y == y1) and a <= x <= b:
                continue
            if (x, y) == (x0, y0):
                piece = PERGOLA["NW"]
            elif (x, y) == (x1, y0):
                piece = PERGOLA["NE"]
            elif (x, y) == (x0, y1):
                piece = PERGOLA["SW"]
            elif (x, y) == (x1, y1):
                piece = PERGOLA["SE"]
            else:
                piece = PERGOLA["H"]
            add(x, y, piece)
            if y == y0 and x0 < x < x1 and rng.random() < 0.7:
                add(x, y, rng.choice(HANGING_FLOWERS))
    for y in range(y0 + 1, y1):
        for x in (x0, x1):
            if (side == "W" and x == x0 or side == "E" and x == x1) and a <= y <= b:
                continue
            add(x, y, PERGOLA["V"])


PERGOLAS = [
    # x0, y0, x1, y1, abertura hacia la plaza
    (107, 109, 115, 117, ("E", 112, 114)),  # Elf Lala
    (141, 109, 149, 117, ("W", 112, 114)),  # Eo the Craftsman
    (108, 139, 115, 145, ("N", 111, 112)),
    (141, 139, 148, 145, ("N", 144, 145)),
]
for p in PERGOLAS:
    pergola(*p)

FAIRY_HOUSES = [(119, 104, PLANT_HOUSES[0]), (138, 104, MUSHROOM_HOUSE), (104, 125, LOG_HOUSE), (152, 132, PLANT_HOUSES[1]),
                (120, 152, PLANT_HOUSES[3]), (137, 152, MUSHROOM_HOUSE), (152, 124, PLANT_HOUSES[2]), (104, 133, PLANT_HOUSES[4])]
for (x, y, it) in FAIRY_HOUSES:
    add(x, y, it)
    reserve(x, y, 1)
for (x, y) in ((126, 100), (99, 140)):
    add(x, y - 1, SNAIL_V[0])
    add(x, y, SNAIL_V[1])
    reserve(x, y, 2)

# fuente de las hadas al norte del templo, faroles-árbol alrededor de la plaza y bancos
FOUNTAIN_POS = (CENTER[0], CENTER[1] - 4)
add(*FOUNTAIN_POS, FOUNTAIN)
for k in range(8):
    a = k * math.pi / 4 + math.pi / 8
    x = int(round(CENTER[0] + math.cos(a) * (PLAZA_R + 2)))
    y = int(round(CENTER[1] + math.sin(a) * (PLAZA_R + 2)))
    if ground[y][x] in ("meadow", "grass"):
        add(x, y, LAMPION)
        reserve(x, y, 1)
for (dx, dy) in ((-4, -4), (4, -4), (-4, 4), (4, 4)):
    add(CENTER[0] + dx, CENTER[1] + dy, BENCH)
CHAOS = (CENTER[0], CENTER[1] + 4)

# ---------- decoración ----------
def free(x, y):
    return ground[y][x] in ("meadow", "forest", "grass") and (x, y) not in blocked and (x, y) not in items


tree_spots = set()


def can_tree(x, y):
    # los árboles de Feyrist son grandes: no los pegamos entre sí
    return not any((x + dx, y + dy) in tree_spots for dx in (-1, 0, 1) for dy in (-1, 0, 1))


for y in range(1, H - 1):
    for x in range(1, W - 1):
        if not free(x, y):
            continue
        r = rng.random()
        g = ground[y][x]
        if (x, y) in flags:
            # jardines del pueblo: flores, pétalos, velas y algún árbol mágico
            if math.hypot(x - CENTER[0], y - CENTER[1]) < PLAZA_R + 3:
                continue
            near_path = any(ground[y + dy][x + dx] == "path" for dx in (-1, 0, 1) for dy in (-1, 0, 1))
            if r < 0.16:
                add(x, y, rng.choice(MEADOW_SMALL))
            elif r < 0.20 and not near_path and math.hypot(x - CENTER[0], y - CENTER[1]) > 12 and can_tree(x, y):
                add(x, y, rng.choice(MAGIC_TREES + BEECHES + BEECHES))
                tree_spots.add((x, y))
            elif r < 0.21 and not near_path:
                add(x, y, rng.choice(FOREST_SMALL[4:]))
            continue
        if g == "forest":
            if r < 0.30 and can_tree(x, y):
                add(x, y, rng.choice(BEECHES + BEECHES + MAGIC_TREES))
                tree_spots.add((x, y))
            elif r < 0.45:
                add(x, y, rng.choice(FOREST_SMALL))
            elif r < 0.46:
                add(x, y, rng.choice(BIG_MORELS))
        else:
            if r < 0.045 and can_tree(x, y):
                add(x, y, rng.choice(BEECHES + MAGIC_TREES))
                tree_spots.add((x, y))
            elif r < 0.12:
                add(x, y, rng.choice(MEADOW_SMALL))
            elif r < 0.125:
                add(x, y, rng.choice(BIG_MORELS))

# anillo de hayas que rodea el pueblo (deja libres los caminos)
for y in range(H):
    for x in range(W):
        if ground[y][x] not in ("meadow", "grass") or (x, y) in items or (x, y) in blocked:
            continue
        d = math.hypot(x - CENTER[0], y - CENTER[1]) - town_r(x, y)
        if 0.5 < d < 4 and rng.random() < 0.5 and can_tree(x, y):
            add(x, y, rng.choice(BEECHES))
            tree_spots.add((x, y))

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
    used_n = n and (w or e)
    used_s = s and (w or e)
    used_w = w and (n or s)
    used_e = e and (n or s)
    if n and not used_n:
        out.append("N")
    if s and not used_s:
        out.append("S")
    if w and not used_w:
        out.append("W")
    if e and not used_e:
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


borders = {}
for y in range(H):
    for x in range(W):
        t = ground[y][x]
        b = []
        if t in ("meadow", "forest", "path", "grass"):
            for p in border_pieces(x, y, lambda a, c: g(a, c) == "water"):
                b.append(B_WATER[p])
        if t in ("meadow", "forest", "grass"):
            for p in border_pieces(x, y, lambda a, c: g(a, c) == "mtn"):
                b.append(B_MTN[p])
        if t == "grass":
            for p in border_pieces(x, y, lambda a, c: g(a, c) == "meadow"):
                b.append(B_MEADOW[p])
        if t == "meadow":
            for p in border_pieces(x, y, lambda a, c: g(a, c) == "path"):
                b.append(B_PATH[p])
        if t == "path":
            for p in border_pieces(x, y, lambda a, c: g(a, c) == "grass"):
                b.append(B_GRASS_ON_PATH[p])
        if t in ("meadow", "path", "grass"):
            for p in border_pieces(x, y, lambda a, c: g(a, c) == "forest"):
                b.append(B_FOREST[p])
        if b:
            borders[(x, y)] = b

# ---------- armar tiles ----------
tiles = {}
for y in range(H):
    for x in range(W):
        t = ground[y][x]
        if t == "meadow":
            gid = rng.choice(MEADOW_VAR) if rng.random() < 0.10 else MEADOW
        elif t == "path":
            gid = rng.choice(PATH_VAR) if rng.random() < 0.15 else PATH
        elif t == "grass":
            gid = rng.choice(GRASS_VAR) if rng.random() < 0.08 else GRASS
        else:
            gid = dict(forest=FOREST, water=WATER, mtn=MOUNTAIN, bridge=BRIDGE)[t]
        stack = [gid] + borders.get((x, y), []) + items.get((x, y), [])
        tiles[(OX + x, OY + y, Z)] = (flags.get((x, y), 0), stack)


def G(p):
    return (OX + p[0], OY + p[1], Z)


POIS = {
    "temple": G(CENTER),
    "return_tp": G((CENTER[0] + 3, CENTER[1] - 3)),
    "npcs": {
        "Elf Lala": G((111, 113)),
        "Eo the Craftsman": G((145, 113)),
        "Chaos Goblin": G(CHAOS),
    },
    "ground": ground,
}
