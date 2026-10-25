"""Noria v3 (MU, la ciudad de las Elfas) con la forma del mapa oficial de MU (Noria vista desde arriba):
la ciudad abajo al centro-izquierda, rodeada de agua y de un anillo de árboles, con 3 salidas (oeste, norte y este),
caminos como en el mapa de MU y los NPCs donde los marcó Genaro.
Estilo: Feyrist (pradera, caminos de piedra, hayas, árboles mágicos) + Ab'dendriel (casas de árbol, enredaderas,
setos con flores, luciérnagas, trigo y flores de luna).
Salida: tiles dict (x,y,z) -> (flags, [ground, items...], {indice: attrs}) y POIS."""
import math, random, struct

OX, OY, Z = 1160, 520, 7
W = H = 256
rng = random.Random(97531)

# ---------- piezas de Feyrist ----------
MEADOW = 25269
MEADOW_VAR = [25273, 25274, 25275, 25276, 25277, 25278, 25279, 25280, 25281, 25282]
PATH = 25245
PATH_VAR = list(range(25246, 25257))
FOREST = 18460
FOREST_VAR = [18461, 18462, 18463, 18464]
WATER = 4597
MOUNTAIN = 1128
BRIDGE = 1771
GRASS = 4515
GRASS_VAR = [4518, 4519, 4520, 4521, 4522, 4524, 4525, 4526]
BARK = [18454, 18455, 18456, 18457, 18458]  # piso de las casas de árbol de Ab'dendriel

B_PATH = dict(N=25258, E=25259, S=25257, W=25260, NW=25264, NE=25263, SE=25261, SW=25262, iNW=25268, iNE=25267, iSE=25265, iSW=25266)
B_FOREST = dict(N=18796, E=18807, S=18806, W=18797, NW=18798, NE=18799, SE=18801, SW=18800, iNW=18802, iNE=18803, iSE=18805, iSW=18804)
B_WATER = dict(N=4633, E=4634, S=4635, W=4636, NW=4641, NE=4642, SE=4644, SW=4643, iNW=4637, iNE=4638, iSE=4640, iSW=4639)
B_MEADOW = dict(N=25284, E=25285, S=25283, W=25286, NW=25290, NE=25289, SE=25287, SW=25288, iNW=25294, iNE=25293, iSE=25291, iSW=25292)
B_GRASS_ON_PATH = dict(N=4531, E=4532, S=4533, W=4534, NW=4535, NE=4536, SE=4538, SW=4537, iNW=4539, iNE=4540, iSE=4542, iSW=4541)
B_MTN = dict(N=4445, E=4446, S=4447, W=4448, NW=4449, NE=4450, SE=4451, SW=4452, iNW=4453, iNE=4454, iSE=4455, iSW=4456)
PERGOLA = dict(NW=25333, NE=25334, SW=25335, SE=25336, H=25338, V=25337)
HANGING_FLOWERS = [6225, 6226, 6227, 6229]

BEECHES = [25468, 25469, 25470, 25471, 25472, 25473, 25474, 25475]
MAGIC_TREES = [25467, 25403, 25404, 25398, 25397, 25400, 25399, 25401, 25402, 25309, 25477, 25478]
CHERRY = 9225
AB_TREES = [3617, 3619, 3618, 3620, 3621, 3614, 3682]  # ciruelo, peral, arce rojo y amarillo, haya, abetos (Ab'dendriel)
FOREST_SMALL = [18869, 18870, 18871, 18872, 18873, 18874, 25388, 25394, 3918, 3919, 3914, 3915, 15209, 15211, 3681]
MEADOW_SMALL = [3890, 3888, 3889, 3892, 3893, 3656, 25382, 25358, 25356, 25357] + list(range(24845, 24861))
AB_FLOWERS = [3653, 3654, 3657, 3656, 6217, 6218, 21935]  # trigo, flores de luna, heaven blossom, flor blanca, pastitos
FIREFLIES = [6490, 6493, 6497]
HEDGES = [2702, 2703, 2704, 2705, 2708, 2709]  # setos con flores (flowery wall)
BIG_MORELS = [25392, 25390]
GLIMMER = [3918, 3919, 3920]
LAMPION = 25409
FOUNTAIN = 25411
BENCH = 25240
PLANT_HOUSES = [25312, 25314, 25316, 25318, 25320]
MUSHROOM_HOUSE = 25332
DEPOT_LOCKER = 3499
CHESTS = [2472, 2480, 2481, 2482]
CRATE = 2471
TARGETS = [5777, 5778]
STUCK_ARROWS = [5779, 5780, 5781, 5782, 5783, 5784]
CAULDRON = 9176
ANVIL = 7843
CRYSTALS = [7809, 7810, 7811, 7812]
BLACK_CRYSTALS = 10847
STONE_PILES = [8503, 8504, 8505, 8506]
BONES = [6394, 6395, 6396, 6397, 6398, 6399, 6400, 6401, 4317]
RUBBLE = [5618, 5619, 5620, 5621, 5622, 5623]
STONE_PILLAR = 7708
BROKEN_PILLAR = 8389
BIG_STONES = [1772, 1791]
STREET_LAMP = 2108

AID_FIXED = b"\x04" + struct.pack("<H", 100)  # action id 100 = no se puede mover (como en Lorencia v3)


def depot_attr(depot_id):
    return b"\x0a" + struct.pack("<H", depot_id)


# Casas de árbol copiadas de Ab'dendriel (z7). 'F' = piso de corteza; el resto va sobre el suelo del lugar.
HOUSE_SMALL = [[[6134], [6133], [6135], [6449], [6135], [6147], []], [[6136], ['F', 6137], ['F'], ['F'], ['F', 6152], [6148], [18534, 3618]], [[6450], ['F', 6153], ['F'], ['F'], ['F'], [6450], [11778, 6179]], [[6132], ['F'], ['F'], ['F'], ['F'], [6132, 2709], [11781, 6188, 6179]], [[6132], ['F'], ['F'], ['F'], ['F'], [6450], [6153]], [[6150, 18449], ['F', 6151], ['F', 6199], ['F', 6135, 2719], ['F', 6449], [6149, 6225, 6230, 2702], [6156, 18534, 3682]], [[19062], [6158, 18473, 18533, 18874], [18470], [18472, 15211, 6182, 6180], [6152, 15206], [15212, 6180], []]]
HOUSE_BIG = [[[6134], [6133], [6135], [6449], [6135], [6135], [18870, 6147], []], [[6136], ['F', 6137], ['F', 6152], ['F', 6152], ['F', 6152], ['F', 6152], [6148], [6188]], [[6132], ['F', 6153], ['F'], ['F'], ['F'], ['F'], [6132, 6220], [6153, 15211, 6186, 6179]], [[6132], ['F', 6153], ['F'], ['F'], ['F'], ['F'], [6132, 2703], [15211, 6179]], [[6132], ['F', 6153], ['F'], ['F'], ['F'], ['F'], [6450], [6153]], [[6132], ['F', 6153], ['F'], ['F'], ['F'], ['F'], [6132, 2702], [6187, 6179]], [[6150], [6151], ['F', 6199], ['F', 6449], [6135, 2728], [6135, 6219], [6149, 6226, 6229, 6227, 6219], [18534, 6179]], [[3617], [6158, 18473, 18533], [18470], [18472, 6180], [6152, 6181], [6180], [6157, 6218], []]]

ground = [["meadow"] * W for _ in range(H)]
items = {}
attrs = {}
flags = {}
blocked = set()


def add(lx, ly, iid, attr=b""):
    items.setdefault((lx, ly), []).append(iid)
    if attr:
        attrs[(lx, ly, len(items[(lx, ly)]))] = attr


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


edge_noise = make_noise(21, 9)
forest_noise = make_noise(22, 14)
detail_noise = make_noise(23, 5)
glade_noise = make_noise(24, 11)
ring_noise = make_noise(25, 6)

# ---------- la ciudad: abajo al centro-izquierda, como en el mapa de MU ----------
CITY = (110, 185)


def city_r(a):
    # un poco más ancha que alta, con bordes irregulares
    return 25 + 2.2 * math.sin(a * 3 + 0.7) + 1.4 * math.sin(a * 5 + 2.1)


def city_d(x, y):
    """Distancia (aprox.) al borde de la ciudad: negativa adentro."""
    dx, dy = x - CITY[0], (y - CITY[1]) * 1.04
    return math.hypot(dx, dy) - city_r(math.atan2(dy, dx))


MOAT = (1.6, 5.0)   # el agua rodea la ciudad entre estas distancias
TREES = (5.0, 13.0)  # anillo de árboles alrededor del agua

# Las 3 salidas: oeste (arriba a la izquierda), norte y este (abajo a la derecha)
EXIT_W = [(97, 179), (88, 172), (80, 167), (74, 163)]
EXIT_N = [(117, 174), (118, 162), (119, 152), (121, 145)]
EXIT_E = [(121, 196), (129, 202), (136, 208), (142, 212)]

# Caminos de afuera, trazados sobre el mapa oficial (coordenadas de MU = coordenadas locales)
ROADS = [
    # oeste: de la salida oeste hasta el borde izquierdo
    [(74, 163), (68, 168), (62, 176), (54, 180), (46, 180), (36, 175), (28, 170), (20, 163), (12, 158), (4, 155)],
    # norte: de la salida norte, por el bosque del noreste, hasta el camino de arriba
    [(121, 145), (126, 138), (136, 131), (148, 128), (157, 124), (162, 113), (165, 101), (167, 89), (171, 77), (168, 63),
     (171, 51), (181, 43), (193, 36), (204, 28), (210, 22)],
    # este: de la salida este hacia el sureste
    [(142, 212), (149, 217), (158, 224), (170, 226), (180, 222), (188, 214), (195, 207), (207, 205), (218, 210), (225, 219), (229, 230), (233, 240)],
    # rama este que bordea el campo de ruinas
    [(146, 214), (152, 200), (163, 196), (176, 198), (188, 201), (195, 207)],
    # camino de arriba (de oeste a este)
    [(40, 30), (44, 19), (56, 15), (70, 16), (84, 14), (98, 20), (112, 24), (128, 20), (144, 22), (160, 18), (176, 20), (192, 18),
     (206, 22), (216, 15), (232, 13), (240, 15)],
    # camino de la derecha (baja por el borde este)
    [(240, 15), (238, 27), (234, 40), (232, 56), (230, 68), (233, 80), (239, 92), (241, 100), (232, 104), (222, 108), (216, 116),
     (218, 130), (222, 145), (228, 158), (226, 172), (226, 190), (228, 210), (230, 232), (233, 240)],
    # camino de la izquierda (baja por el borde oeste)
    [(40, 30), (34, 40), (23, 44), (13, 50), (11, 62), (16, 72), (14, 82), (9, 94), (12, 106), (14, 120), (9, 136), (5, 150), (4, 155)],
    # sendero en diagonal del noroeste
    [(64, 16), (72, 28), (82, 42), (92, 56)],
]

# Bosques (manchas oscuras del mapa oficial): (x, y, radio)
WOODS = [(200, 47, 5), (207, 54, 4), (188, 62, 5), (167, 72, 4), (150, 72, 4), (157, 81, 4), (193, 83, 5), (177, 90, 5),
         (147, 97, 4), (157, 98, 4), (173, 100, 5), (187, 100, 4), (153, 118, 5), (167, 127, 5), (180, 127, 4), (147, 137, 4),
         (167, 140, 5), (183, 140, 4), (160, 153, 4), (173, 160, 5), (217, 100, 4), (220, 117, 4), (130, 75, 3), (205, 140, 4),
         (58, 50, 5), (72, 53, 4), (58, 68, 5), (77, 67, 4), (60, 85, 4), (62, 95, 3), (40, 43, 4), (28, 110, 3),
         (13, 203, 5), (33, 213, 5), (10, 230, 5), (43, 230, 4), (100, 230, 4), (127, 230, 4), (110, 220, 3), (75, 205, 3),
         (195, 230, 4), (215, 195, 4), (150, 245, 3)]
# fila de árboles sueltos que baja hacia la ciudad (los puntitos del mapa de MU)
TREE_LINE = [(73, 118), (77, 123), (80, 128), (83, 134), (85, 140), (88, 147)]

# Lugares especiales del mapa oficial
STONE_RINGS = [(12, 8), (25, 10), (13, 22), (24, 22)]
RUIN_H = (24, 80)          # ruina en forma de H (oeste)
SUN_ALTAR = (115, 9)        # el "sol" de arriba
RIGHT_RUIN = (238, 52)      # ruina grande del este
PILLARS = (84, 108)         # columnas
BONE_FIELD_W = (24, 142, 14)
BONE_FIELD_E = (168, 210, 11)
BOULDERS_SW = (18, 236, 14)
SMALL_PONDS = [(186, 62, 2), (172, 120, 2), (60, 210, 3), (210, 175, 2)]

# ---------- terreno base ----------
for y in range(H):
    for x in range(W):
        d = min(x, y, W - 1 - x, H - 1 - y)
        if d < 3 + edge_noise(x, y) * 3:
            ground[y][x] = "mtn"

for y in range(H):
    for x in range(W):
        if ground[y][x] != "meadow":
            continue
        for (wx, wy, wr) in WOODS:
            if math.hypot(x - wx, (y - wy) * 1.15) < wr * (0.7 + 0.6 * forest_noise(x, y)):
                ground[y][x] = "forest"
                break

for y in range(H):
    for x in range(W):
        if ground[y][x] == "meadow" and glade_noise(x, y) > 0.66:
            ground[y][x] = "grass"

for (px, py, pr) in SMALL_PONDS:
    for y in range(py - pr - 3, py + pr + 4):
        for x in range(px - pr - 3, px + pr + 4):
            if math.hypot(x - px, (y - py) * 1.2) < pr + edge_noise(x * 3, y * 3) * 1.5 and ground[y][x] != "mtn":
                ground[y][x] = "water"

# ---------- ciudad, agua y anillo de árboles ----------
ring_trees = set()
for y in range(H):
    for x in range(W):
        d = city_d(x, y)
        n = (ring_noise(x, y) - 0.5) * 1.6
        if d <= 0.5:
            ground[y][x] = "grass" if d > -5.5 + n else "plaza"
            flags[(x, y)] = 1
        elif MOAT[0] + n * 0.4 < d <= MOAT[1] + n:
            ground[y][x] = "water"
        elif d <= MOAT[0] + n * 0.4:
            ground[y][x] = "grass"
            flags[(x, y)] = 1
        elif d <= TREES[1] + n * 2:
            if ground[y][x] not in ("mtn",):
                ground[y][x] = "forest"
                ring_trees.add((x, y))


def stroke(points, width, fn, wobble=1.5):
    for (ax, ay), (bx, by) in zip(points, points[1:]):
        steps = int(max(abs(bx - ax), abs(by - ay)) * 2) + 1
        for i in range(steps + 1):
            t = i / steps
            px = ax + (bx - ax) * t + (detail_noise(ax + i, ay) - 0.5) * wobble
            py = ay + (by - ay) * t + (detail_noise(ax, ay + i) - 0.5) * wobble
            for y in range(int(py - width - 1), int(py + width + 2)):
                for x in range(int(px - width - 1), int(px + width + 2)):
                    if 0 <= x < W and 0 <= y < H and math.hypot(x - px, y - py) <= width:
                        fn(x, y)


def road_cell(x, y):
    g = ground[y][x]
    if g == "water":
        ground[y][x] = "bridge"
    elif g in ("meadow", "forest", "grass", "plaza"):
        ground[y][x] = "path"
    elif g == "mtn" and min(x, y, W - 1 - x, H - 1 - y) > 0:
        ground[y][x] = "path"
    blocked.add((x, y))


for exit_pts in (EXIT_W, EXIT_N, EXIT_E):
    stroke(exit_pts, 1.3, road_cell, wobble=0)
for r in ROADS:
    stroke(r, 0.9, road_cell)


def straighten_bridges():
    """Cada cruce de agua queda como un puente recto de 3 de ancho."""
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
                    nb = (cx + dx, cy + dy)
                    if nb not in seen and 0 <= nb[0] < W and 0 <= nb[1] < H and ground[nb[1]][nb[0]] == "bridge":
                        seen.add(nb)
                        stack.append(nb)
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
                    blocked.add((k, y))
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
                    blocked.add((x, k))


straighten_bridges()

# ---------- adentro de la ciudad ----------
# Jardines (islas de pasto en la plaza de piedra, como en Noria de MU)
GARDENS = [((113, 188), 6.0, 4.6), ((121, 194), 3.0, 2.6), ((104, 192), 2.2, 1.8), ((118, 180), 2.4, 2.0), ((100, 178), 2.0, 1.6),
           ((123, 174), 3.2, 2.2), ((108, 203), 3.4, 2.2), ((96, 192), 1.8, 1.6), ((107, 179), 2.2, 1.8)]


def in_garden(x, y, pad=0.0):
    return any(((x - cx) / (rx + pad)) ** 2 + ((y - cy) / (ry + pad)) ** 2 <= 1 for (cx, cy), rx, ry in GARDENS)


for y in range(H):
    for x in range(W):
        if ground[y][x] == "plaza" and in_garden(x, y):
            ground[y][x] = "grass"
        if ground[y][x] == "plaza":
            ground[y][x] = "path"
            blocked.add((x, y))

# Puntos de la ciudad (según las marcas de Genaro sobre la foto de Noria)
TEMPLE = (97, 200)          # donde aparece el jugador (la flechita roja)
RETURN_TP = (93, 202)       # teleport de vuelta a Strongarm
DEPOT = (89, 194)           # el baúl (marca marrón)
CHARON = (94, 186)          # marca roja (Devil Square)
MESSENGER = (94, 182)       # Messenger of Archangel (Blood Castle), al lado de Charon
CHAOS = (102, 198)          # marca amarilla
BUFF_ELF = (100, 171)       # marca rosa: elfa del buff (NPC para más adelante)
LALA = (110, 170)           # marca azul
EO = (124, 192)             # blanco
LALA_HOUSE = (106, 162)     # casa grande (8x8) detrás de Lala
EO_HOUSE = (126, 182)       # casa chica (7x7) detrás de Eo
FOUNTAIN_POS = (113, 188)


def reserve(x, y, r=1):
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            blocked.add((x + dx, y + dy))


def stamp(house, x0, y0):
    for j, row in enumerate(house):
        for i, st in enumerate(row):
            x, y = x0 + i, y0 + j
            if not st:
                continue
            if st[0] == 'F':
                ground[y][x] = "bark"
                st = st[1:]
            elif ground[y][x] in ("path", "water"):
                ground[y][x] = "grass"
            for iid in st:
                add(x, y, iid)
            blocked.add((x, y))
    for j in range(len(house)):
        for i in range(len(house[0])):
            flags[(x0 + i, y0 + j)] = 1


stamp(HOUSE_BIG, *LALA_HOUSE)
stamp(HOUSE_SMALL, *EO_HOUSE)
# el frente de las casas (puerta) da a la plaza: piso de piedra delante
for (hx, hy, door_dx, h) in ((LALA_HOUSE[0], LALA_HOUSE[1], 2, 8), (EO_HOUSE[0], EO_HOUSE[1], 2, 7)):
    dx, dy = hx + door_dx, hy + h - 1 + (0 if h == 8 else 1)
    for yy in range(dy, dy + 2):
        if ground[yy][dx] in ("grass", "meadow", "forest"):
            ground[yy][dx] = "path"
        blocked.add((dx, yy))


def pergola(x0, y0, x1, y1, door):
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
            if y == y0 and x0 < x < x1:
                add(x, y, rng.choice(HANGING_FLOWERS))
    for y in range(y0 + 1, y1):
        for x in (x0, x1):
            if (side == "W" and x == x0 or side == "E" and x == x1) and a <= y <= b:
                continue
            add(x, y, PERGOLA["V"])


# Pérgola con flores para la elfa del buff (rosa)
pergola(97, 167, 103, 172, ("S", 99, 101))
# Porche de Lala: arco de flores delante de su casa
for x in (108, 112):
    add(x, 170, PERGOLA["V"])
    add(x, 170, rng.choice(HANGING_FLOWERS))
    blocked.add((x, 170))

# Baúl (depot) con cofres, cajas y faroles alrededor
add(*DEPOT, DEPOT_LOCKER, depot_attr(10))
for (dx, dy, it) in ((-1, -1, CHESTS[1]), (1, -1, CRATE), (-1, 1, CHESTS[2]), (1, 1, CRATE), (0, -2, LAMPION)):
    add(DEPOT[0] + dx, DEPOT[1] + dy, it, AID_FIXED if it in CHESTS or it == CRATE else b"")
reserve(DEPOT[0], DEPOT[1], 1)

# Charon: piedras oscuras y cristales negros (la entrada a Devil Square)
for (dx, dy) in ((-2, -1), (-2, 1), (2, -1), (2, 1)):
    add(CHARON[0] + dx, CHARON[1] + dy, BLACK_CRYSTALS)
    blocked.add((CHARON[0] + dx, CHARON[1] + dy))
add(CHARON[0] - 2, CHARON[1], STONE_PILLAR)
for (dx, dy, st) in ((-1, -2, 2035), (1, -2, 2036)):
    add(CHARON[0] + dx, CHARON[1] + dy, st)
    blocked.add((CHARON[0] + dx, CHARON[1] + dy))
reserve(CHARON[0], CHARON[1], 0)
reserve(MESSENGER[0], MESSENGER[1], 0)

# Chaos Goblin: caldero, yunque y cristales (la Chaos Machine)
add(CHAOS[0] + 1, CHAOS[1] - 1, CAULDRON)
add(CHAOS[0] + 2, CHAOS[1], ANVIL)
add(CHAOS[0] + 1, CHAOS[1] + 1, rng.choice(CRYSTALS))
add(CHAOS[0] - 1, CHAOS[1] - 1, rng.choice(CRYSTALS))
for (dx, dy) in ((1, -1), (2, 0), (1, 1), (-1, -1)):
    blocked.add((CHAOS[0] + dx, CHAOS[1] + dy))
reserve(CHAOS[0], CHAOS[1], 0)

# Eo the Craftsman: blancos de tiro con flechas clavadas, cajas y arcos
for k, (tx, ty) in enumerate(((129, 194), (131, 196), (129, 198))):
    add(tx, ty, TARGETS[k % 2])
    add(tx, ty, rng.choice(STUCK_ARROWS))
    blocked.add((tx, ty))
for (tx, ty) in ((121, 190), (121, 191)):
    add(tx, ty, CRATE, AID_FIXED)
    blocked.add((tx, ty))
reserve(EO[0], EO[1], 0)

# Templo y teleport: el jugador aparece al lado del Chaos Goblin
reserve(TEMPLE[0], TEMPLE[1], 1)
reserve(RETURN_TP[0], RETURN_TP[1], 0)

# Fuente de las hadas en el jardín del centro, bancos y faroles-árbol
add(*FOUNTAIN_POS, FOUNTAIN)
reserve(FOUNTAIN_POS[0], FOUNTAIN_POS[1], 1)
for (dx, dy) in ((-3, 3), (3, 3), (-3, -3), (3, -3)):
    add(FOUNTAIN_POS[0] + dx, FOUNTAIN_POS[1] + dy, BENCH)
    blocked.add((FOUNTAIN_POS[0] + dx, FOUNTAIN_POS[1] + dy))
LAMPS = [(98, 176), (106, 176), (116, 175), (124, 177), (90, 188), (99, 192), (107, 203), (117, 205), (126, 199), (133, 189),
         (89, 180), (112, 197), (95, 196)]
for (x, y) in LAMPS:
    if ground[y][x] in ("path", "grass") and (x, y) not in items:
        add(x, y, LAMPION)
        blocked.add((x, y))

# Setos con flores alrededor de los jardines (Ab'dendriel), con dos entradas por jardín
HEDGE_H = [2706, 2707, 2712]
HEDGE_V = [2708, 2709, 2713]
HEDGE_CORNER = 2711
for (cx, cy), rx, ry in GARDENS:
    if rx < 3:
        continue
    for y in range(int(cy - ry - 1), int(cy + ry + 2)):
        for x in range(int(cx - rx - 1), int(cx + rx + 2)):
            inside_ = ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1
            if not inside_ or ground[y][x] != "grass" or (x, y) in blocked or (x, y) in items:
                continue
            def ing(a, b):
                return ((a - cx) / rx) ** 2 + ((b - cy) / ry) ** 2 <= 1
            out_n, out_s, out_w, out_e = not ing(x, y - 1), not ing(x, y + 1), not ing(x - 1, y), not ing(x + 1, y)
            if not (out_n or out_s or out_w or out_e):
                continue
            if abs(x - cx) < 1 or abs(y - cy) < 1:  # entradas en los 4 puntos cardinales
                continue
            if (out_n and out_w):
                piece = HEDGE_CORNER
            elif out_n or out_s:
                piece = rng.choice(HEDGE_H)
            else:
                piece = rng.choice(HEDGE_V)
            add(x, y, piece)
            blocked.add((x, y))

# Faroles azules alrededor del jardín central y estatuas de las cazadoras elfas en las entradas
for k in range(12):
    a = k * math.pi / 6 + 0.26
    x, y = int(round(FOUNTAIN_POS[0] + math.cos(a) * 9.5)), int(round(FOUNTAIN_POS[1] + math.sin(a) * 8.0))
    if ground[y][x] == "path" and (x, y) not in items:
        add(x, y, STREET_LAMP)
        blocked.add((x, y))
for (x, y, st) in ((90, 168, 2104), (93, 175, 2105), (115, 165, 2106), (122, 165, 2107), (125, 202, 2104), (131, 198, 2105)):
    if ground[y][x] in ("grass", "path") and (x, y) not in items:
        add(x, y, st)
        blocked.add((x, y))

# ---------- decoración general ----------
def free(x, y):
    return ground[y][x] in ("meadow", "forest", "grass") and (x, y) not in blocked and (x, y) not in items


tree_spots = set()


def can_tree(x, y):
    return not any((x + dx, y + dy) in tree_spots for dx in (-1, 0, 1) for dy in (-1, 0, 1))


def near(x, y, kind, r=1):
    return any(0 <= x + dx < W and 0 <= y + dy < H and ground[y + dy][x + dx] == kind for dx in range(-r, r + 1) for dy in range(-r, r + 1))


for (x, y) in TREE_LINE:
    add(x, y, rng.choice(BEECHES))
    tree_spots.add((x, y))

for y in range(1, H - 1):
    for x in range(1, W - 1):
        if not free(x, y):
            continue
        r = rng.random()
        g = ground[y][x]
        if (x, y) in flags:
            # jardines y bordes de la ciudad: flores de Feyrist y Ab'dendriel, luciérnagas y algún árbol
            if near(x, y, "path") and r < 0.12:
                add(x, y, rng.choice(AB_FLOWERS + MEADOW_SMALL[:6]))
            elif not near(x, y, "path") and r < 0.10 and can_tree(x, y):
                add(x, y, rng.choice([CHERRY, CHERRY, CHERRY] + BEECHES[:3] + AB_TREES[:2] + [25467]))
                tree_spots.add((x, y))
            elif r < 0.40:
                add(x, y, rng.choice(AB_FLOWERS + MEADOW_SMALL + GLIMMER))
            elif r < 0.46:
                add(x, y, rng.choice(FIREFLIES))
            continue
        if (x, y) in ring_trees and g == "forest":
            # el anillo de árboles alrededor del agua: bien tupido
            if r < 0.55 and can_tree(x, y):
                add(x, y, rng.choice(BEECHES + BEECHES + AB_TREES + AB_TREES + [CHERRY] + MAGIC_TREES[:3]))
                tree_spots.add((x, y))
            elif r < 0.85:
                add(x, y, rng.choice(FOREST_SMALL))
            continue
        if g == "forest":
            if r < 0.32 and can_tree(x, y):
                add(x, y, rng.choice(BEECHES + BEECHES + AB_TREES + AB_TREES + MAGIC_TREES[:5]))
                tree_spots.add((x, y))
            elif r < 0.47:
                add(x, y, rng.choice(FOREST_SMALL))
            elif r < 0.48:
                add(x, y, rng.choice(BIG_MORELS))
            elif r < 0.50:
                add(x, y, rng.choice(FIREFLIES))
        else:
            if r < 0.035 and can_tree(x, y):
                add(x, y, rng.choice(BEECHES + AB_TREES + MAGIC_TREES))
                tree_spots.add((x, y))
            elif r < 0.10:
                add(x, y, rng.choice(MEADOW_SMALL + AB_FLOWERS))
            elif r < 0.105:
                add(x, y, rng.choice(BIG_MORELS))

# ---------- lugares especiales (ruinas, círculos de piedras, huesos) ----------
def scatter(cx, cy, rad, pool, prob):
    for y in range(cy - rad, cy + rad + 1):
        for x in range(cx - rad, cx + rad + 1):
            if 0 < x < W - 1 and 0 < y < H - 1 and math.hypot(x - cx, y - cy) <= rad and free(x, y) and rng.random() < prob:
                add(x, y, rng.choice(pool))


for (cx, cy) in STONE_RINGS:
    for k in range(8):
        a = k * math.pi / 4
        x, y = int(round(cx + 3 * math.cos(a))), int(round(cy + 3 * math.sin(a)))
        if free(x, y):
            add(x, y, rng.choice(BIG_STONES))
            blocked.add((x, y))
# ruina en H: columnas y escombros
hx, hy = RUIN_H
for (x, y) in [(hx, hy + k) for k in range(9)] + [(hx + 8, hy + k) for k in range(9)] + [(hx + k, hy + 4) for k in range(1, 8)]:
    ground[y][x] = "path"
    blocked.add((x, y))
    if rng.random() < 0.5:
        add(x, y, rng.choice([STONE_PILLAR, BROKEN_PILLAR] + RUBBLE))
# el "sol": altar de piedra con cristales
sx, sy = SUN_ALTAR
for y in range(sy - 3, sy + 4):
    for x in range(sx - 3, sx + 4):
        if math.hypot(x - sx, y - sy) <= 3.2 and ground[y][x] != "mtn":
            ground[y][x] = "path"
            blocked.add((x, y))
add(sx, sy, FOUNTAIN)
for (dx, dy) in ((-3, 0), (3, 0), (0, -3), (0, 3)):
    add(sx + dx, sy + dy, rng.choice(CRYSTALS))
# ruina grande del este y columnas
rx, ry = RIGHT_RUIN
for y in range(ry, ry + 26):
    for x in range(rx - 4, rx + 6):
        if ground[y][x] not in ("mtn", "water") and (x in (rx - 4, rx + 5) or y in (ry, ry + 25) or (y - ry) % 8 == 0):
            ground[y][x] = "path"
            if rng.random() < 0.45:
                add(x, y, rng.choice([STONE_PILLAR, BROKEN_PILLAR] + RUBBLE))
            blocked.add((x, y))
px_, py_ = PILLARS
for k in range(4):
    add(px_ + 2 * k, py_ + (k % 2), STONE_PILLAR)
    blocked.add((px_ + 2 * k, py_ + (k % 2)))
scatter(*BONE_FIELD_W, BONES + RUBBLE + STONE_PILES, 0.10)
scatter(*BONE_FIELD_E, BONES + RUBBLE, 0.10)
scatter(*BOULDERS_SW, BIG_STONES + STONE_PILES, 0.12)

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
        if t in ("meadow", "forest", "path", "grass", "bark"):
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
        elif t == "forest":
            gid = rng.choice(FOREST_VAR) if rng.random() < 0.15 else FOREST
        elif t == "bark":
            gid = rng.choice(BARK)
        else:
            gid = dict(water=WATER, mtn=MOUNTAIN, bridge=BRIDGE)[t]
        bl = borders.get((x, y), [])
        it = items.get((x, y), [])
        stack = [gid] + bl + it
        at = {len(bl) + k: attrs[(x, y, k)] for k in range(1, len(it) + 1) if (x, y, k) in attrs}
        tiles[(OX + x, OY + y, Z)] = (flags.get((x, y), 0), stack, at)


def G(p):
    return (OX + p[0], OY + p[1], Z)


POIS = {
    "temple": G(TEMPLE),
    "return_tp": G(RETURN_TP),
    "depot": G(DEPOT),
    "npcs": {
        "Elf Lala": G(LALA),
        "Eo the Craftsman": G(EO),
        "Chaos Goblin": G(CHAOS),
        "Charon": G(CHARON),
        "Messenger of Archangel": G(MESSENGER),
    },
    "buff_elf": G(BUFF_ELF),
    "ground": ground,
}
