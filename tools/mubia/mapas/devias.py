"""Genera Devias (MU, la ciudad de la nieve) como tiles de Tibia 15.x.
La forma (barrancos, caminos, río, lagos, edificios, zona segura) sale de Data/World3 del cliente de MU
(EncTerrain3.att/.map decodificados en devias_mu.pkl), pero se dibuja a mano con piezas de Tibia (estilo Noria).
Lo bloqueado de MU (el negro del minimapa) es un vacío: casillas sin piso con un borde de roca, cruzado por puentes
de troncos con baranda de soga y pilares de piedra en cada punta (como el puente al este del pueblo en MU).
Salida: dict (x,y,z) -> (flags, [ground, items...]) en coordenadas globales, y metadatos (POIS, ZONES)."""
import math, os, pickle, random

OX, OY, Z = 1560, 520, 7
W = H = 256
rng = random.Random(3303)

HERE = os.path.dirname(os.path.abspath(__file__))
att, tex = pickle.load(open(os.path.join(HERE, 'devias_mu.pkl'), 'rb'))


def mu(x, y):
    """Atributo y textura de MU en la casilla local (x, y). x local = y de MU, y local = x de MU."""
    i = x * 256 + y
    return att[i], tex[i]


# ---------- piezas (de los pinceles de RME) ----------
SNOW = [799] * 24 + list(range(6580, 6594))
ICE = [800, 800, 6683, 6684, 6685, 6686]
SEA = 4597
ROAD = [103]  # tierra
COBBLE = 870
WOOD = 408
MARBLE = 409

# bordes: n e s w, esquinas exteriores c*, interiores d*
BORDERS = {
    'snow': {'n': 4726, 'e': 4727, 's': 4728, 'w': 4729, 'cnw': 4730, 'cne': 4731, 'csw': 4732, 'cse': 4733, 'dnw': 4734, 'dne': 4735, 'dsw': 4736, 'dse': 4737},
    'water': {'n': 6627, 'e': 6628, 's': 6629, 'w': 6630, 'cnw': 6635, 'cne': 6636, 'csw': 6638, 'cse': 6637, 'dnw': 6634, 'dne': 6633, 'dsw': 6632, 'dse': 6631},
    'ice': {'n': 6695, 'e': 6696, 's': 6697, 'w': 6698, 'cnw': 6699, 'cne': 6700, 'csw': 6701, 'cse': 6702, 'dnw': 6703, 'dne': 6704, 'dsw': 6705, 'dse': 6706},
}
# qué suelo dibuja su borde encima de cuál (el de más arriba tapa al de más abajo)
ZORD = {'pave': 1, 'cobble': 1, 'wood': 1, 'marble': 1, 'road': 10, 'ice': 3900, 'snow': 4000, 'water': -1}

STONE_WALL = dict(H=1295, V=1294, CORNER=1298, POLE=1296)
SNOW_TREES = [3609, 3609, 7023, 7023, 4433]
DEAD_TREES = [3608, 7020, 7021, 7022]
SNOWY_STONES = [7000, 7001, 7002, 7003, 7004, 7005]
SNOW_HEAP = 611
SNOWMAN = 7171
LAMP = 2109
BENCH = 2371
BARREL = 2519
CRATE = 2471
STATUE = 2026
FOUNTAIN = 1922
RED_CARPET = 2572
# vacío: borde de roca sobre la casilla vacía que toca tierra
RIM = {'n': 4445, 'e': 4446, 's': 4447, 'w': 4448, 'cnw': 4449, 'cne': 4450, 'cse': 4451, 'csw': 4452,
       'dnw': 4453, 'dne': 4454, 'dse': 4455, 'dsw': 4456}
BRIDGE = {'H': 2253, 'V': 2254}  # troncos atados con soga (H: se cruza de oeste a este)
RAIL = {'H': 2240, 'V': 2236}  # baranda oscura
PILLAR = 1296

ground = [['snow'] * W for _ in range(H)]
items = {}
flags = {}
blocked = set()  # casillas donde no va decoración
walk = [[False] * W for _ in range(H)]


def add(x, y, iid):
    items.setdefault((x, y), []).append(iid)


def neighbors4(x, y):
    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        if 0 <= x + dx < W and 0 <= y + dy < H:
            yield x + dx, y + dy


# ---------- 1) forma de MU ----------
safe = set()
for y in range(H):
    for x in range(W):
        a, t = mu(x, y)
        if a & 1:
            safe.add((x, y))
        if a & 8 or a & 4:
            ground[y][x] = 'water' if t == 5 else 'mtn'  # 'mtn' = bloqueado de MU; al final se dibuja como vacío
        else:
            walk[y][x] = True
            if t == 5:
                ground[y][x] = 'ice'
            elif t in (2, 3, 4, 6, 8, 9, 10, 11, 12, 13):
                ground[y][x] = 'road'


def components(pred):
    seen = set()
    out = []
    for y in range(H):
        for x in range(W):
            if (x, y) in seen or not pred(x, y):
                continue
            stack, comp = [(x, y)], []
            seen.add((x, y))
            while stack:
                c = stack.pop()
                comp.append(c)
                for n in neighbors4(*c):
                    if n not in seen and pred(*n):
                        seen.add(n)
                        stack.append(n)
            out.append(comp)
    return out


# ---------- 1b) fortalezas (piso de piedra de MU) con murallas alrededor ----------
FORTS = [(0, 0, 50, 48), (200, 200, 255, 249)]  # entrada a Lost Tower (noroeste) y fortaleza del sureste
fort_walls = set()
for (fx0, fy0, fx1, fy1) in FORTS:
    for y in range(fy0, fy1 + 1):
        for x in range(fx0, fx1 + 1):
            if walk[y][x] and mu(x, y)[1] in (8, 9, 10, 11, 12, 13):
                ground[y][x] = 'pave'
    for y in range(fy0, fy1 + 1):
        for x in range(fx0, fx1 + 1):
            if ground[y][x] == 'mtn' and any(ground[y + dy][x + dx] == 'pave' for dx in (-1, 0, 1) for dy in (-1, 0, 1)
                                             if 0 <= x + dx < W and 0 <= y + dy < H):
                fort_walls.add((x, y))
for (x, y) in fort_walls:
    ground[y][x] = 'snow'

# ---------- 2) edificios del pueblo (posiciones de MU) ----------
# nombre, x0, y0, x1, y1, puertas [(lado, desde, hasta)], piso
BUILDINGS = [
    ('salon', 12, 203, 32, 215, [('S', 24, 27)], 'marble'),  # salón del Arcángel
    ('zienna', 42, 185, 51, 194, [('S', 45, 46)], 'wood'),  # tienda de armas
    ('izabel', 36, 222, 44, 232, [('S', 39, 40)], 'wood'),  # pociones
    ('casa1', 19, 223, 28, 236, [('W', 229, 230)], 'wood'),
    ('casa2', 54, 201, 63, 208, [('W', 204, 205)], 'wood'),
    ('torre', 38, 238, 46, 245, [('N', 41, 42)], 'wood'),
]
in_building = set()
ring = set()  # orilla del pueblo entre las casas, el río y el vacío
for name, x0, y0, x1, y1, doors, floor in BUILDINGS:
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            in_building.add((x, y))

# ---------- 3) pueblo: la orilla bloqueada de MU alrededor del pueblo pasa a ser nieve abierta ----------
TOWN = (5, 166, 78, 255)


def in_town_box(x, y):
    return TOWN[0] <= x <= TOWN[2] and TOWN[1] <= y <= TOWN[3]


for y in range(H):
    for x in range(W):
        if (x, y) in in_building:
            ground[y][x] = dict(marble='marble', wood='wood')[[b for b in BUILDINGS if b[1] <= x <= b[3] and b[2] <= y <= b[4]][0][6]]
            walk[y][x] = True
        elif (x, y) in safe and ground[y][x] == 'mtn' and in_town_box(x, y):
            ground[y][x] = 'snow'  # orilla / jardines: nieve abierta con pocos árboles (más abajo)
            walk[y][x] = True
            flags[(x, y)] = 1
            ring.add((x, y))
        elif (x, y) in safe and walk[y][x]:
            flags[(x, y)] = 1
            if ground[y][x] == 'road':
                ground[y][x] = 'cobble'

# ---------- 4) limpiar ruido: islas chicas ----------
# bloqueos sueltos de 1 a 6 casillas en el campo: piedras/árboles sobre nieve
for comp in components(lambda x, y: ground[y][x] == 'mtn'):
    if len(comp) <= 6:
        for (x, y) in comp:
            ground[y][x] = 'snow'
            add(x, y, rng.choice(SNOWY_STONES + SNOW_TREES))
            blocked.add((x, y))
# huecos caminables de 1 a 3 casillas dentro de montaña: montaña
for comp in components(lambda x, y: walk[y][x] and ground[y][x] != 'water' and (x, y) not in in_building):
    if len(comp) <= 3:
        for (x, y) in comp:
            ground[y][x] = 'mtn'
            walk[y][x] = False
# agua bloqueada en medio del campo (lagos congelados chicos): agujero en el hielo
for comp in components(lambda x, y: ground[y][x] == 'water'):
    if len(comp) <= 4:
        for (x, y) in comp:
            ground[y][x] = 'ice'
            add(x, y, 7236)
            blocked.add((x, y))

# suavizar montañas: casilla de montaña con 3+ vecinos caminables -> nieve (evita dientes)
for _ in range(2):
    change = []
    for y in range(1, H - 1):
        for x in range(1, W - 1):
            if ground[y][x] == 'mtn' and not in_town_box(x, y):
                open4 = sum(1 for n in neighbors4(x, y) if ground[n[1]][n[0]] in ('snow', 'road', 'ice'))
                if open4 >= 3:
                    change.append((x, y))
    for (x, y) in change:
        ground[y][x] = 'snow'
        add(x, y, rng.choice(SNOW_TREES + SNOWY_STONES))
        blocked.add((x, y))


# vacío de una casilla de ancho (rendijas): piedra o pino sobre nieve
for _ in range(2):
    thin = [(x, y) for y in range(1, H - 1) for x in range(1, W - 1) if ground[y][x] == 'mtn' and (x, y) not in fort_walls
            and ((ground[y][x - 1] != 'mtn' and ground[y][x + 1] != 'mtn') or (ground[y - 1][x] != 'mtn' and ground[y + 1][x] != 'mtn'))]
    for (x, y) in thin:
        ground[y][x] = 'snow'
        add(x, y, rng.choice(SNOW_TREES + SNOWY_STONES))
        blocked.add((x, y))


# ---------- 5) paredes, puertas y muebles ----------
def wall_piece(cells, x, y):
    n = (x, y - 1) in cells
    s = (x, y + 1) in cells
    e = (x + 1, y) in cells
    w = (x - 1, y) in cells
    if e and s:
        return STONE_WALL['CORNER']  # esquina noroeste
    if (n or s) and (e or w):
        return STONE_WALL['POLE']
    if n or s:
        return STONE_WALL['V']
    return STONE_WALL['H']


for name, x0, y0, x1, y1, doors, floor in BUILDINGS:
    cells = set()
    for x in range(x0, x1 + 1):
        cells.add((x, y0))
        cells.add((x, y1))
    for y in range(y0, y1 + 1):
        cells.add((x0, y))
        cells.add((x1, y))
    for side, a, b in doors:
        for k in range(a, b + 1):
            cells.discard({'S': (k, y1), 'N': (k, y0), 'E': (x1, k), 'W': (x0, k)}[side])
    for (x, y) in cells:
        add(x, y, wall_piece(cells, x, y))
        blocked.add((x, y))
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            blocked.add((x, y))
            flags[(x, y)] = 1

for (x, y) in fort_walls:
    add(x, y, wall_piece(fort_walls, x, y))
    blocked.add((x, y))

# salón: alfombra roja de la puerta al altar, estatuas a los lados
for y in range(206, 215):
    for x in (25, 26):
        add(x, y, RED_CARPET)
add(22, 205, STATUE)
add(29, 205, STATUE)
for x in (15, 18, 33 - 4, 33 - 7):
    add(x, 207, LAMP)
# tienda de Zienna: barriles y cajas
for x in (43, 50):
    add(x, 186, CRATE)
add(50, 192, BARREL)
# casa de Izabel
add(37, 223, BARREL)
add(43, 223, CRATE)
for name, x0, y0, x1, y1, doors, floor in BUILDINGS[3:]:
    add(x0 + 1, y0 + 1, BARREL)
    add(x1 - 1, y1 - 1, CRATE)

# plaza: fuente donde MU tiene la columna, faroles y bancos
add(46, 213, FOUNTAIN)
blocked |= {(46, 213), (47, 213), (46, 214), (47, 214)}
for p in ((36, 214), (47, 197)):
    add(*p, STATUE)
for p in ((22, 217), (33, 217), (39, 200), (52, 213), (60, 217), (38, 172), (44, 172)):
    if (p[0], p[1]) not in in_building:
        add(*p, LAMP)
        blocked.add(p)
add(30, 228, SNOWMAN)
add(57, 228, SNOWMAN + 1)

# calles de piedra: puente norte -> plaza -> salida este, y hasta cada puerta
STREETS = [
    [(40, 166), (41, 200), (41, 219)],
    [(9, 219), (77, 219)],
    [(25, 216), (25, 219)],
    [(45, 195), (45, 200), (41, 200)],
    [(39, 233), (39, 236), (36, 236), (36, 219)],
    [(53, 204), (48, 204), (48, 219)],
    [(18, 229), (14, 229), (14, 219)],
]


def street(points, width=1):
    for (ax, ay), (bx, by) in zip(points, points[1:]):
        steps = max(abs(bx - ax), abs(by - ay))
        for i in range(steps + 1):
            px = round(ax + (bx - ax) * i / max(steps, 1))
            py = round(ay + (by - ay) * i / max(steps, 1))
            for dx in range(0, width + 1):
                for dy in range(0, width + 1):
                    x, y = px + dx, py + dy
                    if walk[y][x] and (x, y) not in in_building and not items.get((x, y)):
                        ground[y][x] = 'cobble'
                        blocked.add((x, y))


for st in STREETS:
    street(st)
# la orilla del pueblo: pocos pinos y alguna piedra nevada, lejos de las calles
for (x, y) in sorted(ring):
    if ground[y][x] != 'snow' or items.get((x, y)) or (x, y) in blocked:
        continue
    if any(ground[y + dy][x + dx] == 'cobble' for dx in (-1, 0, 1) for dy in (-1, 0, 1) if 0 <= x + dx < W and 0 <= y + dy < H):
        continue
    r = rng.random()
    if r < 0.07:
        add(x, y, rng.choice(SNOW_TREES))
        blocked.add((x, y))
    elif r < 0.09:
        add(x, y, rng.choice(SNOWY_STONES))
        blocked.add((x, y))
    elif r < 0.11:
        add(x, y, SNOW_HEAP)

# ---------- 6) campo: árboles y piedras al pie de las montañas, nieve suelta ----------
def near(x, y, kind, r):
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            if 0 <= x + dx < W and 0 <= y + dy < H and ground[y + dy][x + dx] == kind:
                return True
    return False


for y in range(H):
    for x in range(W):
        if ground[y][x] != 'snow' or (x, y) in blocked or items.get((x, y)) or (x, y) in flags:
            continue
        if near(x, y, 'road', 1) or near(x, y, 'cobble', 2):
            continue
        r = rng.random()
        foot = near(x, y, 'mtn', 1)
        if foot and r < 0.10:
            add(x, y, rng.choice(SNOW_TREES))
        elif r < 0.035:
            add(x, y, rng.choice(SNOW_TREES))
        elif r < 0.045:
            add(x, y, rng.choice(DEAD_TREES))
        elif r < 0.055:
            add(x, y, rng.choice(SNOWY_STONES))
        elif r < 0.065:
            add(x, y, SNOW_HEAP)

# ---------- 6b) puentes: pasos angostos (hasta 4 casillas) con vacío a los dos lados ----------
def is_void(x, y):
    return not (0 <= x < W and 0 <= y < H) or ground[y][x] == 'mtn'


def open_cell(x, y):
    return 0 <= x < W and 0 <= y < H and walk[y][x] and ground[y][x] not in ('water', 'mtn')


def narrow(x, y, dx, dy):
    a = b = 0
    while a < 6 and open_cell(x - dx * (a + 1), y - dy * (a + 1)):
        a += 1
    while b < 6 and open_cell(x + dx * (b + 1), y + dy * (b + 1)):
        b += 1
    return a + b + 1 <= 4 and is_void(x - dx * (a + 1), y - dy * (a + 1)) and is_void(x + dx * (b + 1), y + dy * (b + 1))


BRIDGES = []  # (orientación, casillas)
for kind, (dx, dy) in (('H', (0, 1)), ('V', (1, 0))):
    cand = {(x, y) for y in range(H) for x in range(W) if open_cell(x, y) and narrow(x, y, dx, dy)}
    for comp in components(lambda x, y: (x, y) in cand):
        along = [p[0] for p in comp] if kind == 'H' else [p[1] for p in comp]
        if max(along) - min(along) + 1 >= 6:
            BRIDGES.append((kind, set(comp)))

bridge_cells = set()
for kind, cells in BRIDGES:
    rails = set()
    for (x, y) in cells:
        for side in (-1, 1):
            p = (x, y + side) if kind == 'H' else (x + side, y)
            if p not in cells and is_void(*p):
                rails.add(p)
    for (x, y) in cells | rails:
        ground[y][x] = 'bridge_' + kind
        items.pop((x, y), None)
        bridge_cells.add((x, y))
    for (x, y) in rails:
        add(x, y, RAIL[kind])
        walk[y][x] = False
    # pilares de piedra en las cuatro puntas, sobre la tierra de cada orilla
    along = [p[0] for p in rails] if kind == 'H' else [p[1] for p in rails]
    for end, step in ((min(along), -1), (max(along), 1)):
        for (x, y) in rails:
            if (x if kind == 'H' else y) != end:
                continue
            px, py = (x + step, y) if kind == 'H' else (x, y + step)
            if is_void(px, py):
                ground[py][px] = 'bridge_' + kind
                bridge_cells.add((px, py))
            items[(px, py)] = [PILLAR]
            walk[py][px] = False
            blocked.add((px, py))

# ---------- 7) bordes ----------
DIRS = dict(nw=(-1, -1), n=(0, -1), ne=(1, -1), e=(1, 0), se=(1, 1), s=(0, 1), sw=(-1, 1), w=(-1, 0))


def g(x, y):
    if 0 <= x < W and 0 <= y < H:
        return ground[y][x]
    return 'mtn'


def g_land(x, y):
    """Casilla con piso (para el borde de roca del vacío). Los puentes no llevan borde."""
    return g(x, y) != 'mtn' and not g(x, y).startswith('bridge')


def border_pieces(x, y, is_other):
    o = {k: is_other(x + dx, y + dy) for k, (dx, dy) in DIRS.items()}
    n, e, s, w = o['n'], o['e'], o['s'], o['w']
    out = []
    if n and w:
        out.append('dnw')
    if n and e:
        out.append('dne')
    if s and e:
        out.append('dse')
    if s and w:
        out.append('dsw')
    if n and not (w or e):
        out.append('n')
    if s and not (w or e):
        out.append('s')
    if w and not (n or s):
        out.append('w')
    if e and not (n or s):
        out.append('e')
    if o['nw'] and not n and not w:
        out.append('cnw')
    if o['ne'] and not n and not e:
        out.append('cne')
    if o['se'] and not s and not e:
        out.append('cse')
    if o['sw'] and not s and not w:
        out.append('csw')
    return out


borders = {}
ORDER = ['ice', 'snow']  # de abajo hacia arriba
for y in range(H):
    for x in range(W):
        t = ground[y][x]
        b = []
        if t == 'mtn':
            for p in border_pieces(x, y, g_land):
                b.append(RIM[p])
        elif t.startswith('bridge'):
            pass
        elif t == 'water':
            for p in border_pieces(x, y, lambda a, c: g(a, c) not in ('water', 'mtn') and not g(a, c).startswith('bridge')):
                b.append(BORDERS['water'][p])
        else:
            for kind in ORDER:
                if ZORD[kind] > ZORD[t]:
                    for p in border_pieces(x, y, lambda a, c, k=kind: g(a, c) == k):
                        b.append(BORDERS[kind][p])
        if b:
            borders[(x, y)] = b

# ---------- armar tiles ----------
tiles = {}
for y in range(H):
    for x in range(W):
        t = ground[y][x]
        if t == 'mtn':  # vacío: sin piso, solo el borde de roca (si no toca tierra, ni se guarda la casilla)
            if borders.get((x, y)):
                tiles[(OX + x, OY + y, Z)] = (0, borders[(x, y)])
            continue
        gid = {'snow': rng.choice(SNOW), 'ice': rng.choice(ICE), 'water': SEA, 'road': rng.choice(ROAD),
               'cobble': COBBLE, 'pave': 429, 'wood': WOOD, 'marble': MARBLE,
               'bridge_H': BRIDGE['H'], 'bridge_V': BRIDGE['V']}[t]
        stack = [gid] + borders.get((x, y), []) + items.get((x, y), [])
        tiles[(OX + x, OY + y, Z)] = (flags.get((x, y), 0), stack)


def G(p):
    return (OX + p[0], OY + p[1], Z)


TEMPLE = (27, 219)
POIS = {
    'temple': G(TEMPLE),
    'return_tp': G((30, 220)),
    'npcs': {
        'Zienna': G((47, 188)),
        'Izabel': G((41, 225)),
        'Guild Master': G((44, 214)),
        'Spirit of Archangel': G((25, 205)),
        'Sevina': G((40, 182)),
    },
}


def zone(x, y):
    """Zona de monstruos (mismo reparto que el boceto)."""
    if x >= 175 and y < 85:
        return 'Elite Yeti'
    if x >= 125 and y >= 165:
        return 'Ice Queen' if x >= 205 and y >= 205 else 'Elite Yeti S'
    if x < 90 and y < 100:
        return 'Assassin'
    if x >= 90 and y < 95:
        return 'Yeti'
    if x >= 140 and y < 165:
        return 'Yeti'
    if x < 64 and y < 175:
        return 'Ice Monster'
    if x < 125 and y >= 165:
        return 'Worm'
    return 'Hommerd'
