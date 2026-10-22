"""Genera Noria (MU, la ciudad de las Elfas) como tiles de Tibia 15.x, diseñada a mano (estilo Lorencia v1).
Salida: dict (x,y,z) -> (flags, [ground, items...]) en coordenadas globales, y metadatos (pois)."""
import math, random, json

OX, OY, Z = 1160, 520, 7
W = H = 256
rng = random.Random(4321)

# ---------- piezas ----------
GRASS = 4515
GRASS_VAR = [4518, 4519, 4520, 4521, 4522, 4524, 4525, 4526, 4527, 4528]
DIRT = 103
COBBLE = 870
WATER = 4597
MOUNTAIN = 1128
WOOD = 408
BRIDGE = 1771
STONE_TILE = 429

# bordes: N E S W, esquinas exteriores NW NE SE SW, interiores iNW iNE iSE iSW
B_GRASS_ON_DIRT = dict(N=4531, E=4532, S=4533, W=4534, NW=4535, NE=4536, SE=4538, SW=4537, iNW=4539, iNE=4540, iSE=4542, iSW=4541)
B_WATER_ON_LAND = dict(N=4633, E=4634, S=4635, W=4636, NW=4641, NE=4642, SE=4644, SW=4643, iNW=4637, iNE=4638, iSE=4640, iSW=4639)
B_MTN_ON_GRASS = dict(N=4445, E=4446, S=4447, W=4448, NW=4449, NE=4450, SE=4451, SW=4452, iNW=4453, iNE=4454, iSE=4455, iSW=4456)

STONE_WALL = dict(H=1295, V=1294, NW=1296, SE=1298, NE=1297, SW=1295, X=1296)
FRAME_WALL = dict(H=1282, V=1281, NW=1283, SE=1285, NE=1282, SW=1282, X=1283)

TREES = [3614, 3617, 3619, 3625, 3616, 7024, 3682, 3682]
BUSHES = [3681, 3681, 3698, 3699, 3747, 3746, 3748]
FLOWERS = [3655, 3654, 3892, 3656, 3894, 3661]
STONES = [1856, 1855, 1857]
DEAD = [3633, 3624, 3632]
LAMP = 2109
BENCH = 2371
BARREL = 2519
CRATE = 2471
SIGN = 2012

ground = [["grass"] * W for _ in range(H)]
items = {}  # (lx,ly) -> list
flags = {}
blocked = set()  # casillas donde no poner decoración


def add(lx, ly, iid):
    items.setdefault((lx, ly), []).append(iid)


# ---------- ruido simple ----------
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



forest_noise = make_noise(2, 22)
detail_noise = make_noise(3, 5)


edge_noise = make_noise(11, 9)
forest_noise = make_noise(12, 18)
detail_noise = make_noise(13, 5)

CENTER = (128, 128)
TOWN_R = 30  # radio del pueblo (claro en el bosque)


def town_r(x, y):
    a = math.atan2(y - CENTER[1], x - CENTER[0])
    return TOWN_R + 3 * math.sin(a * 3 + 1) + 2 * math.sin(a * 5)


def in_town(x, y, pad=0):
    return math.hypot(x - CENTER[0], y - CENTER[1]) <= town_r(x, y) + pad


# ---------- montañas alrededor (más altas al norte) ----------
for y in range(H):
    for x in range(W):
        d = min(x, W - 1 - x, H - 1 - y)
        dn = y
        if d < 4 + edge_noise(x, y) * 5 or dn < 7 + edge_noise(x, y) * 8:
            ground[y][x] = "mtn"

# ---------- arroyo: baja del norte, forma un estanque al este del pueblo y sigue al sur ----------
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
# lago chico en el bosque del oeste
LAKE = (52, 92, 11)
for y in range(H):
    for x in range(W):
        if math.hypot(x - LAKE[0], (y - LAKE[1]) * 1.3) < LAKE[2] + edge_noise(x * 2, y * 2) * 4:
            if ground[y][x] != "mtn":
                ground[y][x] = "water"

# ---------- pueblo: un claro en el bosque, zona protegida ----------
for y in range(H):
    for x in range(W):
        if in_town(x, y) and ground[y][x] != "water":
            ground[y][x] = "grass"
            flags[(x, y)] = 1
        if in_town(x, y, 2):
            blocked.add((x, y))
for (x, y) in list(flags):
    if ground[y][x] == "water":
        pass


def wall_line(walls, wall_cells):
    """Pone las piezas de pared según los vecinos (estilo Tibia)."""
    for (x, y) in wall_cells:
        n = (x, y - 1) in wall_cells
        s = (x, y + 1) in wall_cells
        e = (x + 1, y) in wall_cells
        w = (x - 1, y) in wall_cells
        if e and s and not n and not w:
            piece = walls["NW"]
        elif n and w and not e and not s:
            piece = walls["SE"]
        elif w and s and not e and not n:
            piece = walls["NE"]
        elif n and e and not w and not s:
            piece = walls["SW"]
        elif (e or w) and (n or s):
            piece = walls["X"]
        elif n or s:
            piece = walls["V"]
        else:
            piece = walls["H"]
        add(x, y, piece)
        blocked.add((x, y))


# plaza central de piedra
PLAZA = (CENTER[0] - 8, CENTER[1] - 6, CENTER[0] + 8, CENTER[1] + 6)
for y in range(PLAZA[1], PLAZA[3] + 1):
    for x in range(PLAZA[0], PLAZA[2] + 1):
        ground[y][x] = "stone"

# caminos de tierra: del templo a cada salida del pueblo y por el bosque
ROADS = [
    [(128, 122), (126, 90), (120, 60), (124, 30), (122, 12)],  # norte (zona de Golems)
    [(128, 134), (130, 170), (124, 205), (128, 240)],  # sur
    [(120, 128), (90, 132), (60, 126), (30, 130), (10, 128)],  # oeste
    [(136, 128), (150, 130), (180, 128), (215, 134), (245, 128)],  # este (cruza el arroyo)
]


def draw_road(points, width=1.4):
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
                        elif g == "grass":
                            ground[y][x] = "dirt"
                        elif g == "mtn" and min(x, y, W - 1 - x, H - 1 - y) > 0:
                            ground[y][x] = "dirt"
                        blocked.add((x, y))


for r in ROADS:
    draw_road(r)


# puentes rectos de madera (3 de ancho) donde un camino cruza el agua
def straighten_bridges():
    seen = set()
    cells = [(x, y) for y in range(H) for x in range(W) if ground[y][x] == "bridge"]
    groups = []
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
        groups.append(grp)
    for grp in groups:
        for (x, y) in grp:
            ground[y][x] = "water"
        xs = [x for x, _ in grp]
        ys = [y for _, y in grp]
        horizontal = (max(xs) - min(xs)) >= (max(ys) - min(ys))
        if horizontal:
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
                    if ground[y][k] == "grass":
                        ground[y][k] = "dirt"
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
                    if ground[k][x] == "grass":
                        ground[k][x] = "dirt"


straighten_bridges()

# ---------- casas de madera ----------
HOUSES = [
    # nombre, x0, y0, x1, y1, puerta (lado, desde, hasta)
    ("lala", 104, 110, 115, 119, ("E", 114, 116)),
    ("eo", 141, 110, 152, 119, ("W", 114, 116)),
    ("casa1", 106, 140, 116, 148, ("N", 110, 112)),
    ("casa2", 140, 140, 150, 148, ("N", 144, 146)),
    ("taller", 118, 98, 126, 105, ("S", 121, 123)),
]
house_walls = set()
for name, x0, y0, x1, y1, door in HOUSES:
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            ground[y][x] = "wood"
            blocked.add((x, y))
    cells = set()
    for x in range(x0, x1 + 1):
        cells.add((x, y0))
        cells.add((x, y1))
    for y in range(y0, y1 + 1):
        cells.add((x0, y))
        cells.add((x1, y))
    side, a, b = door
    for k in range(a, b + 1):
        cells.discard({"S": (k, y1), "N": (k, y0), "E": (x1, k), "W": (x0, k)}[side])
    house_walls |= cells
    # sendero de tierra desde la puerta hacia la plaza
    for k in range(a, b + 1):
        if side == "E":
            path = [(x, k) for x in range(x1 + 1, PLAZA[0])]
        elif side == "W":
            path = [(x, k) for x in range(PLAZA[2] + 1, x0)]
        elif side == "N":
            path = [(k, y) for y in range(PLAZA[3] + 1, y0)]
        else:
            path = [(k, y) for y in range(y1 + 1, PLAZA[1])]
        for (px, py) in path:
            if ground[py][px] == "grass":
                ground[py][px] = "dirt"
            blocked.add((px, py))
wall_line(FRAME_WALL, house_walls)

for name, x0, y0, x1, y1, door in HOUSES:
    if name == "lala":
        add(x0 + 2, y0 + 2, CRATE)
        add(x0 + 2, y1 - 2, BARREL)
    elif name == "eo":
        for y in range(y0 + 2, y1 - 1, 2):
            add(x1 - 2, y, BARREL)
    elif name == "taller":
        add(x0 + 2, y0 + 2, CRATE)
        add(x1 - 2, y0 + 2, CRATE)
    else:
        add(x0 + 2, y0 + 2, BENCH)
        add(x1 - 2, y1 - 2, BARREL)

# plaza: faroles, bancos y canteros con flores
for dx, dy in ((-8, -6), (8, -6), (-8, 6), (8, 6)):
    add(CENTER[0] + dx, CENTER[1] + dy, LAMP)
for dx in (-4, 4):
    add(CENTER[0] + dx, CENTER[1] - 6, BENCH)
    add(CENTER[0] + dx, CENTER[1] + 6, BENCH)
# puesto del Chaos Goblin (la Chaos Machine), al sur de la plaza
CHAOS = (CENTER[0], CENTER[1] + 4)
for dx in (-2, 2):
    add(CHAOS[0] + dx, CHAOS[1], CRATE)
    blocked.add((CHAOS[0] + dx, CHAOS[1]))

# jardines del pueblo: flores y arbustos sobre el pasto
for y in range(H):
    for x in range(W):
        if (x, y) in flags and ground[y][x] == "grass" and (x, y) not in items:
            near_road = any(ground[y + dy][x + dx] in ("dirt", "stone", "wood") for dx in (-1, 0, 1) for dy in (-1, 0, 1))
            r = rng.random()
            if near_road:
                continue
            if r < 0.06:
                add(x, y, rng.choice(FLOWERS))
            elif r < 0.08:
                add(x, y, rng.choice(BUSHES))
            elif r < 0.095 and math.hypot(x - CENTER[0], y - CENTER[1]) > 20:
                add(x, y, rng.choice(TREES))

# anillo de árboles grandes que rodea el pueblo (deja libres los caminos)
for y in range(H):
    for x in range(W):
        if ground[y][x] != "grass" or (x, y) in items:
            continue
        d = math.hypot(x - CENTER[0], y - CENTER[1]) - town_r(x, y)
        if 0.5 < d < 4 and rng.random() < 0.55:
            add(x, y, rng.choice(TREES[:5]))
            blocked.add((x, y))

DUNGEON = (124, 14)
# ---------- decoración ----------
def free(x, y):
    return ground[y][x] == "grass" and (x, y) not in blocked and (x, y) not in items


for y in range(H):
    for x in range(W):
        if not free(x, y):
            continue
        # no tapar caminos ni la orilla de la ciudad
        if in_town(x, y, 4):
            continue
        f = forest_noise(x, y)
        r = rng.random()
        if f > 0.58 and r < 0.34 + (f - 0.58):
            add(x, y, rng.choice(TREES))
        elif r < 0.06:
            add(x, y, rng.choice(TREES))
        elif r < 0.07:
            add(x, y, rng.choice(BUSHES))
        elif r < 0.10:
            add(x, y, rng.choice(FLOWERS))
        elif r < 0.11:
            add(x, y, rng.choice(STONES))
        elif r < 0.113:
            add(x, y, rng.choice(DEAD))

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
        if t in ("dirt", "cobble", "stone"):
            for p in border_pieces(x, y, lambda a, c: g(a, c) == "grass"):
                b.append(B_GRASS_ON_DIRT[p])
        if t in ("grass", "dirt", "cobble", "stone"):
            for p in border_pieces(x, y, lambda a, c: g(a, c) == "water"):
                b.append(B_WATER_ON_LAND[p])
        if t == "grass":
            for p in border_pieces(x, y, lambda a, c: g(a, c) == "mtn"):
                b.append(B_MTN_ON_GRASS[p])
        if b:
            borders[(x, y)] = b

# ---------- armar tiles ----------
GROUND_ID = dict(grass=GRASS, dirt=DIRT, cobble=COBBLE, water=WATER, mtn=MOUNTAIN, wood=WOOD, bridge=BRIDGE, stone=STONE_TILE)
tiles = {}
for y in range(H):
    for x in range(W):
        t = ground[y][x]
        gid = GROUND_ID[t]
        if t == "grass" and rng.random() < 0.08:
            gid = rng.choice(GRASS_VAR)
        stack = [gid] + borders.get((x, y), []) + items.get((x, y), [])
        tiles[(OX + x, OY + y, Z)] = (flags.get((x, y), 0), stack)


def G(p):
    return (OX + p[0], OY + p[1], Z)


POIS = {
    "temple": G(CENTER),
    "return_tp": G((CENTER[0] + 3, CENTER[1] - 3)),
    "npcs": {
        "Elf Lala": G((109, 114)),
        "Eo the Craftsman": G((147, 114)),
        "Chaos Goblin": G(CHAOS),
    },
    "ground": ground,
}
