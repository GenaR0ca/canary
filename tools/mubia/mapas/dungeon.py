"""Genera Dungeon 1, 2 y 3 (MU, World2) como cuevas de Tibia 15.x, una debajo de la otra (z 8, 9 y 10).

La forma (pasillos, salas, cuevas y obstáculos) sale de Data/World2 del cliente de MU (EncTerrain2.att/.map,
decodificados en dungeon_mu.pkl), pero se dibuja con piezas de Tibia (estilo Lorencia v1):
- pasillos y salas construidos de MU (textura de piedra) -> piso de baldosas gastadas y paredes de piedra
- cuevas naturales de MU (textura de roca) -> piso de cueva y paredes de roca
- obstáculos chicos de MU (columnas, piedras) -> braseros, pilas de huesos, barriles o estalagmitas
- lo bloqueado/negro de MU -> vacío (sin casilla), como cualquier cueva de Tibia
- antorchas en las paredes, huesos, calaveras y piedritas sueltas.

Los tres pisos de MU están uno al lado del otro en World2; acá cada uno va en su propio piso (z) y se corre
en x/y para que las escaleras caigan una encima de la otra (escalera que baja arriba, rampa que sube abajo).
Dungeon 3 tiene dos escaleras a Dungeon 2: la oeste (la del respawn) y la este, que sube a un túnel nuevo
de Dungeon 2 que llega hasta la sala del norte.

Salida: tiles {(x, y, z): (flags, [ground, items...])} en coordenadas globales, WALK {piso: set de casillas
caminables}, POIS (llegadas del menú M, escaleras, teleport a Lorencia, puntos calientes de MU).
"""
import os
import pickle
import random
from collections import deque

HERE = os.path.dirname(os.path.abspath(__file__))
att, tex = pickle.load(open(os.path.join(HERE, 'dungeon_mu.pkl'), 'rb'))
rng = random.Random(2202)


def A(x, y):
    """Atributo de MU en la casilla local (x, y). x local = índice // 256, y local = índice % 256."""
    if 0 <= x < 256 and 0 <= y < 256:
        return att[x * 256 + y]
    return 8


def T(x, y):
    return tex[x * 256 + y]


def walk_mu(x, y):
    return A(x, y) & 12 == 0


# ---------- piezas de Tibia ----------
STONE_FLOOR = [416]                         # baldosas gastadas (drab tiled stone floor)
CAVE_FLOOR = [351] * 6 + [352, 353, 354, 355]
STONE_WALL = dict(H=1295, V=1294, CORNER=1298, POLE=1296)
ROCK_WALL = dict(H=1113, V=1112, CORNER=1116, POLE=1114)
CAVE_BORDER = {'N': 4785, 'E': 4786, 'S': 4787, 'W': 4788, 'NW': 4789, 'NE': 4790, 'SW': 4791, 'SE': 4792,
               'iNW': 4793, 'iNE': 4794, 'iSW': 4795, 'iSE': 4796}
TORCH_H = 2941      # antorcha encendida en pared horizontal
TORCH_V = 2943      # antorcha encendida en pared vertical
STAIRS_DOWN = 566   # escalera de piedra que baja
STAIRS_UP = 22565   # escalera de piedra que sube (hacia el norte)
STONE_OBSTACLES = [2110, 10205, 10336, 2522, 10205]      # brasero, pilas de huesos, barril
CAVE_OBSTACLES = [1006, 1090, 388, 389, 392, 5747]        # piedras filosas, estalagmitas, pila de tierra
STONE_DECOR = [3114, 3115, 3116, 3115, 3115]              # calavera, huesos
CAVE_DECOR = [3115, 3116, 3114]

# ---------- pisos ----------
SEEDS = {1: (248, 109), 2: (126, 233), 3: (90, 20)}
ZS = {1: 8, 2: 9, 3: 10}
O1 = (700, 520)


def flood(seed):
    seen = {seed}
    q = deque([seed])
    while q:
        x, y = q.popleft()
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            p = (x + dx, y + dy)
            if p not in seen and walk_mu(*p):
                seen.add(p)
                q.append(p)
    return seen


WALK = {f: flood(s) for f, s in SEEDS.items()}


def nearest(cells, target, ok=lambda p: True):
    best = min((p for p in cells if ok(p)), key=lambda p: (p[0] - target[0]) ** 2 + (p[1] - target[1]) ** 2)
    return best


def solid_ok(cells, p, need):
    """p y las casillas de need (desplazamientos) son caminables y con lugar alrededor."""
    return all((p[0] + dx, p[1] + dy) in cells for dx, dy in need)


AROUND = [(dx, dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1)]
# escalera que baja: casilla libre al norte (ahí llegas cuando subes desde abajo)
UPPER = AROUND + [(0, -2)]
# rampa que sube: casilla libre al sur (ahí llegas cuando bajas desde arriba)
LOWER = AROUND + [(0, 2)]

# Dungeon 1 "Floor 2" (abajo) <-> Dungeon 2 "Floor 1" (este)
S1 = nearest(WALK[1], (150, 239), lambda p: solid_ok(WALK[1], p, UPPER))
R2 = nearest(WALK[2], (126, 233), lambda p: solid_ok(WALK[2], p, LOWER))
# Dungeon 2 "Floor 3" (noroeste) <-> Dungeon 3 "Floor 2" oeste
S2 = nearest(WALK[2], (18, 5), lambda p: solid_ok(WALK[2], p, UPPER))
R3 = nearest(WALK[3], (54, 6), lambda p: solid_ok(WALK[3], p, LOWER))
# Dungeon 3 "Floor 2" este (sube a un túnel nuevo de Dungeon 2)
R3E = nearest(WALK[3], (127, 42), lambda p: solid_ok(WALK[3], p, LOWER))

O = {1: O1}
O[2] = (O[1][0] + S1[0] - R2[0], O[1][1] + S1[1] - R2[1])
O[3] = (O[2][0] + S2[0] - R3[0], O[2][1] + S2[1] - R3[1])

# punta de arriba de la escalera este, en coordenadas locales de Dungeon 2
S2E = (R3E[0] + O[3][0] - O[2][0], R3E[1] + O[3][1] - O[2][1])

# ---------- túnel nuevo de Dungeon 2 (desde la escalera este de Dungeon 3 hasta la sala del norte) ----------
TUNNEL = set()


def carve_tunnel():
    start = (S2E[0], S2E[1] - 1)
    goal = nearest(WALK[2], start)
    x, y = start
    path = [(x, y)]
    # primero baja/sube en y, después avanza en x, con un poco de zigzag para que parezca cueva
    while (x, y) != goal:
        if y != goal[1] and (x == goal[0] or rng.random() < 0.6):
            y += 1 if goal[1] > y else -1
        else:
            x += 1 if goal[0] > x else -1
        path.append((x, y))
    for (px, py) in path:
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                TUNNEL.add((px + dx, py + dy))
    for dx, dy in UPPER:
        TUNNEL.add((S2E[0] + dx, S2E[1] + dy))


carve_tunnel()
WALK[2] |= TUNNEL


# ---------- clase de piso: piedra (construido) o cueva (natural) ----------
def classify(cells, extra_cave=()):
    raw = {}
    for p in cells:
        if p in extra_cave:
            raw[p] = 'cave'
            continue
        t = T(*p)
        raw[p] = 'cave' if t in (7, 5) else ('stone' if t in (0, 1, 2, 3, 4, 8) else None)
    # textura 6 (escombros): toma la clase que más hay alrededor
    for p in cells:
        if raw[p] is None:
            votes = [raw.get((p[0] + dx, p[1] + dy)) for dx in range(-3, 4) for dy in range(-3, 4)]
            raw[p] = 'cave' if votes.count('cave') > votes.count('stone') else 'stone'
    # suavizado para que no queden casillas sueltas
    for _ in range(2):
        new = {}
        for p in cells:
            votes = [raw.get((p[0] + dx, p[1] + dy)) for dx, dy in AROUND]
            c, s = votes.count('cave'), votes.count('stone')
            new[p] = 'cave' if c > s + 1 else ('stone' if s > c + 1 else raw[p])
        raw = new
    return raw


DIRS = dict(NW=(-1, -1), N=(0, -1), NE=(1, -1), E=(1, 0), SE=(1, 1), S=(0, 1), SW=(-1, 1), W=(-1, 0))


def border_pieces(x, y, is_other):
    o = {k: is_other(x + dx, y + dy) for k, (dx, dy) in DIRS.items()}
    n, e, s, w = o['N'], o['E'], o['S'], o['W']
    out = []
    if n and w:
        out.append('iNW')
    if n and e:
        out.append('iNE')
    if s and e:
        out.append('iSE')
    if s and w:
        out.append('iSW')
    if n and not (w or e):
        out.append('N')
    if s and not (w or e):
        out.append('S')
    if w and not (n or s):
        out.append('W')
    if e and not (n or s):
        out.append('E')
    if o['NW'] and not n and not w:
        out.append('NW')
    if o['NE'] and not n and not e:
        out.append('NE')
    if o['SE'] and not s and not e:
        out.append('SE')
    if o['SW'] and not s and not w:
        out.append('SW')
    return out


def build_floor(f):
    walk = WALK[f]
    kind = classify(walk, TUNNEL if f == 2 else ())
    ox, oy = O[f]
    z = ZS[f]
    ground, items = {}, {}

    # obstáculos chicos de MU (rodeados de piso) -> decoración que no se pasa
    near = set()
    for (x, y) in walk:
        for dx, dy in AROUND:
            p = (x + dx, y + dy)
            if p not in walk:
                near.add(p)
    obstacles = set()
    seen = set()
    for p in near:
        if p in seen:
            continue
        comp, q, closed = {p}, deque([p]), True
        seen.add(p)
        while q:
            c = q.popleft()
            if A(*c) & 8 and c not in TUNNEL:
                closed = False
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nb = (c[0] + dx, c[1] + dy)
                if nb in walk:
                    continue
                if nb not in near:
                    closed = False
                    continue
                if nb not in seen:
                    seen.add(nb)
                    comp.add(nb)
                    q.append(nb)
        if closed and len(comp) <= 6:
            obstacles |= comp
    walls = near - obstacles

    def kind_near(p):
        votes = [kind.get((p[0] + dx, p[1] + dy)) for dx, dy in AROUND]
        return 'cave' if votes.count('cave') > votes.count('stone') else 'stone'

    def floor_id(k):
        return rng.choice(CAVE_FLOOR if k == 'cave' else STONE_FLOOR)

    for p in walk:
        ground[p] = floor_id(kind[p])
    for p in obstacles:
        k = kind_near(p)
        ground[p] = floor_id(k)
        items[p] = [rng.choice(CAVE_OBSTACLES if k == 'cave' else STONE_OBSTACLES)]

    # paredes
    torches = []
    for p in walls:
        x, y = p
        k = kind_near(p)
        piece = ROCK_WALL if k == 'cave' else STONE_WALL
        h = (x, y - 1) in walk or (x, y + 1) in walk
        v = (x - 1, y) in walk or (x + 1, y) in walk
        if h and v:
            iid = piece['CORNER']
        elif h:
            iid = piece['H']
        elif v:
            iid = piece['V']
        else:
            # esquina (solo toca el pasillo en diagonal): pieza solo si une una pared horizontal con una vertical
            ns = (x, y - 1) in walls or (x, y + 1) in walls
            ew = (x - 1, y) in walls or (x + 1, y) in walls
            if not (ns and ew):
                continue
            iid = piece['CORNER'] if ((x, y + 1) in walls and (x + 1, y) in walls) else piece['POLE']
        ground[p] = floor_id(k)
        items[p] = [iid]
        # antorcha en las paredes de piedra que miran al pasillo (al sur o al este)
        if k == 'stone' and iid in (piece['H'], piece['V']):
            facing = (x, y + 1) if iid == piece['H'] else (x + 1, y)
            if facing in walk and all(abs(x - tx) + abs(y - ty) > 9 for tx, ty in torches) and rng.random() < 0.45:
                items[p].append(TORCH_H if iid == piece['H'] else TORCH_V)
                torches.append(p)

    # bordes de cueva sobre el piso de piedra
    for p in walk:
        if kind[p] != 'stone':
            continue
        b = border_pieces(p[0], p[1], lambda a, c: kind.get((a, c)) == 'cave')
        if b:
            items.setdefault(p, [])[0:0] = [CAVE_BORDER[k] for k in b]

    # decoración suelta (no bloquea)
    for p in walk:
        if p in items:
            continue
        k = kind[p]
        r = rng.random()
        if r < (0.035 if k == 'cave' else 0.02):
            items[p] = [rng.choice(CAVE_DECOR if k == 'cave' else STONE_DECOR)]

    tiles = {}
    for p, g in ground.items():
        tiles[(ox + p[0], oy + p[1], z)] = [0, [g] + items.get(p, [])]
    return tiles


def G(f, p):
    return (O[f][0] + p[0], O[f][1] + p[1], ZS[f])


tiles = {}
for f in (1, 2, 3):
    tiles.update(build_floor(f))


def set_stairs(pos, iid, under=None):
    flags, stack = tiles[pos]
    if under is not None:
        stack[:] = [under]
    if iid in (STAIRS_DOWN,):
        stack[:] = [iid]
    else:
        stack[:] = [stack[0], iid]


# escaleras: la que baja reemplaza el piso; la que sube va arriba de un piso de piedra
for f, p in ((1, S1), (2, S2), (2, S2E)):
    set_stairs(G(f, p), STAIRS_DOWN)
for f, p in ((2, R2), (3, R3), (3, R3E)):
    set_stairs(G(f, p), STAIRS_UP, under=416)
# que no quede decoración que bloquee al lado de las escaleras
for f, p, need in ((1, S1, UPPER), (2, S2, UPPER), (2, S2E, UPPER), (2, R2, LOWER), (3, R3, LOWER), (3, R3E, LOWER)):
    for dx, dy in need:
        if (dx, dy) == (0, 0):
            continue
        pos = G(f, (p[0] + dx, p[1] + dy))
        stack = tiles[pos][1]
        stack[:] = [stack[0]] + [i for i in stack[1:] if i in CAVE_BORDER.values()]

# llegadas del menú M
ARRIVE = {
    1: nearest(WALK[1], (248, 109), lambda p: solid_ok(WALK[1], p, AROUND)),
    2: (R2[0], R2[1] + 2),
    3: (R3[0], R3[1] + 2),
}
# teleport de vuelta a Lorencia, al lado de la llegada de Dungeon 1
LORENCIA_TP = nearest(WALK[1], (ARRIVE[1][0] + 2, ARRIVE[1][1]),
                      lambda p: p != ARRIVE[1] and solid_ok(WALK[1], p, AROUND))
for f, p in ((1, ARRIVE[1]), (1, LORENCIA_TP), (2, ARRIVE[2]), (3, ARRIVE[3])):
    for dx, dy in AROUND:
        pos = G(f, (p[0] + dx, p[1] + dy))
        stack = tiles[pos][1]
        if stack[0] in (STAIRS_DOWN,) or STAIRS_UP in stack:
            continue
        stack[:] = [stack[0]] + [i for i in stack[1:] if i in CAVE_BORDER.values()]

# puntos de los minimapas de MU (x3 = poco, x4 = medio, x5 = mucho) para repartir monstruos
HOT = {
    1: [((211, 52), 3), ((183, 49), 5), ((189, 97), 3), ((152, 81), 3), ((223, 191), 3), ((172, 244), 3)],
    2: [((119, 164), 4), ((47, 120), 3), ((16, 243), 5)],
    3: [((90, 30), 3)],
}

POIS = {
    'arrive': {f: G(f, p) for f, p in ARRIVE.items()},
    'lorencia_tp': G(1, LORENCIA_TP),
    'stairs': {'d1_down': G(1, S1), 'd2_up': G(2, R2), 'd2_down': G(2, S2), 'd3_up': G(3, R3),
               'd2_down_east': G(2, S2E), 'd3_up_east': G(3, R3E)},
    'offsets': O,
}


def walkable_global(f):
    return {G(f, p) for p in WALK[f]}


if __name__ == '__main__':
    print('tiles', len(tiles))
    for f in (1, 2, 3):
        print('piso', f, 'z', ZS[f], 'origen', O[f], 'casillas', len(WALK[f]))
    print('túnel', len(TUNNEL), 'S2E', S2E)
    for k, v in POIS.items():
        print(k, v)
