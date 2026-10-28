"""Genera Lost Tower 1 a 7 (MU, World5) como una torre de la muerte de Tibia, un piso encima del otro.

La forma (salas, pasillos, columnas y pozos) sale de Data/World5 del cliente de MU (EncTerrain5.att,
decodificado en lost_tower_mu.pkl), pero se dibuja con piezas de Tibia (estilo Lorencia v1 / Dungeon):
- piso caminable de MU -> mármol negro (a veces agrietado o con una losa con calavera)
- borde de lo caminable -> paredes de tumba con huesos y calaveras, con antorchas
- columnas chicas de MU (bloqueadas y rodeadas de piso) -> pilares de huesos, braseros, ataúdes, lápidas, estatuas
- pozos de MU (bloques grandes encerrados) -> pozo de lava con fuego, rodeado de pared
- lo negro de MU -> vacío (sin casilla)
- calaveras, huesos, telarañas y calaveras ardientes sueltas por el piso.

x local = índice // 256, y local = índice % 256 (igual que el minimapa de MU, norte arriba).
Lost Tower 1 es el piso de abajo (z 14) y Lost Tower 7 el de arriba (z 8): se sube la torre con escaleras
reales de Tibia (rampa que sube en el piso de abajo, escalera que baja justo encima en el piso de arriba).
Lost Tower 1 tiene la zona segura (única zona protegida) con Potion Girl Amy y el baúl (depot).
Quedan reservados (sin activar) el portal a Devias (Lost Tower 1) y la entrada a Icarus (Lost Tower 7).

Salida: tiles {(x, y, z): [flags, [ground, items...], attrs]} en coordenadas globales y POIS.
"""
import os
import pickle
import random
import struct
from collections import deque

HERE = os.path.dirname(os.path.abspath(__file__))
att, l1, l2 = pickle.load(open(os.path.join(HERE, 'lost_tower_mu.pkl'), 'rb'))
rng = random.Random(5005)

PZ = 1   # flag de zona protegida en el otbm


def A(x, y):
    if 0 <= x < 256 and 0 <= y < 256:
        return att[x * 256 + y]
    return 8


def walk_mu(p):
    return A(*p) & 12 == 0


# ---------- piezas de Tibia ----------
FLOOR = [410, 7351, 410, 7351, 410, 7351, 19145]            # mármol negro, a veces agrietado
SKULL_SLAB = 28473                                            # losa con calavera (piso)
WALL = dict(H=[11903, 11903, 11903, 11907, 11908, 11909, 11913, 11914],
            V=[11902, 11902, 11902, 11904, 11905, 11906, 11910, 11911],
            C=11917, P=11918)                                 # pared de tumba (con huesos y calaveras)
TORCH_H = 2941      # antorcha encendida en pared horizontal
TORCH_V = 2943      # antorcha encendida en pared vertical
STAIRS_DOWN = 566   # escalera de piedra que baja
STAIRS_UP = 22565   # escalera de piedra que sube (hacia el norte)
LAVA = 2144
PIT_FIRE = [1998, 1999, 2000]                                 # fogata dentro del pozo (da luz)
# columnas sueltas de MU (no se pasan)
PILLARS = [6412, 6412, 10837, 10838, 7059, 2110, 2110, 30965, 19092, 34058, 34059, 748, 19131,
           2035, 2036, 10336, 20179, 6972, 8525, 24435]
# cosas grandes contra las paredes de las salas (no se pasan)
ROOM_BLOCK = [31100, 31101, 1980, 1982, 30007, 10336, 10205, 20179, 2110, 8524, 31212, 31226, 19087,
              28517, 31947, 34058, 34059, 24435]
# decoración suelta que se pisa
FLOOR_DECOR = [3114, 3114, 3115, 3116, 3115, 3116, 5017, 5018, 2699, 2700, 5019, 5020, 10876, 7558]
DEATH_PORTAL = 25047   # portal de la muerte (solo decoración): marca un portal futuro
DEPOT = 3499
DEPOT_ID = 11          # mismo depot que Devias (Lost Tower está en Devias en MU)
CANDLES = [8595, 8596, 5024]
AID_FIXED = b"\x04" + struct.pack("<H", 100)   # action id 100 = no se puede mover

AROUND = [(dx, dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1)]
N4 = ((1, 0), (-1, 0), (0, 1), (0, -1))
# escalera que baja: casillas libres alrededor y al norte (ahí llegas cuando subes desde abajo)
UPPER = AROUND + [(0, -2)]
# rampa que sube: casillas libres alrededor y al sur (ahí llegas cuando bajas desde arriba)
LOWER = AROUND + [(0, 2)]

# ---------- pisos ----------
# semilla (una casilla caminable de cada piso), z, y los puntos marcados por Genaro en cada imagen
LEVELS = {
    1: dict(seed=(70, 200), z=14),
    2: dict(seed=(236, 240), z=13, enter=(236, 240), mark_exit=(167, 167)),
    3: dict(seed=(171, 91), z=12, enter=(171, 91)),
    4: dict(seed=(93, 89), z=11, enter=(93, 89)),
    5: dict(seed=(51, 126), z=10, enter=(51, 126)),
    6: dict(seed=(52, 51), z=9, enter=(52, 51)),
    7: dict(seed=(90, 6), z=8, enter=(90, 6)),
}
# salida (rampa que sube) de cada piso al siguiente
EXITS = {1: (6, 192), 2: (167, 167), 3: (240, 132), 4: (130, 128), 5: (19, 126), 6: (14, 5)}
DEVIAS_MARK = (3, 164)     # punto naranja (Lost Tower 1): portal a Devias, todavía no
ICARUS_MARK = (246, 18)    # punto rojo (Lost Tower 7): entrada a Icarus, todavía no
AMY_MARK = (78, 208)       # punto rosa
CHEST_MARK = (78, 202)     # punto marrón


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


def seed_of(mark):
    return min(ALL_WALK, key=lambda p: (p[0] - mark[0]) ** 2 + (p[1] - mark[1]) ** 2)


WALK = {f: flood(seed_of(v['seed']), walk_mu) for f, v in LEVELS.items()}
for f in WALK:
    assert len(WALK[f]) > 1000, (f, len(WALK[f]))
SAFE = {p for p in WALK[1] if A(*p) & 1}


def nearest(cells, target, ok=lambda p: True):
    return min((p for p in cells if ok(p)), key=lambda p: (p[0] - target[0]) ** 2 + (p[1] - target[1]) ** 2)


def solid_ok(cells, p, need):
    return all((p[0] + dx, p[1] + dy) in cells for dx, dy in need)


def roomy(cells, p, r):
    return all((p[0] + dx, p[1] + dy) in cells for dx in range(-r, r + 1) for dy in range(-r, r + 1))


# rampa que sube (S) en el piso f y escalera que baja (R) en el piso f + 1
S = {f: nearest(WALK[f], EXITS[f], lambda p, f=f: solid_ok(WALK[f], p, LOWER)) for f in EXITS}
R = {f: nearest(WALK[f], LEVELS[f]['enter'], lambda p, f=f: solid_ok(WALK[f], p, UPPER)) for f in range(2, 8)}

# origen de cada piso: la escalera que baja del piso f + 1 queda justo encima de la rampa del piso f
O = {1: (900, 1500)}
for f in range(1, 7):
    O[f + 1] = (O[f][0] + S[f][0] - R[f + 1][0], O[f][1] + S[f][1] - R[f + 1][1])


def G(f, p):
    return (O[f][0] + p[0], O[f][1] + p[1], LEVELS[f]['z'])


# ---------- lugares especiales ----------
SAFE_CENTER = nearest(SAFE, (sum(p[0] for p in SAFE) / len(SAFE), sum(p[1] for p in SAFE) / len(SAFE)),
                      lambda p: roomy(SAFE, p, 1))
AMY = nearest(SAFE, AMY_MARK, lambda p: roomy(WALK[1], p, 1))
CHEST = nearest(SAFE, CHEST_MARK, lambda p: roomy(WALK[1], p, 1) and abs(p[1] - AMY[1]) >= 3)
ARRIVE = {1: nearest(SAFE, SAFE_CENTER, lambda p: roomy(SAFE, p, 1) and max(abs(p[0] - AMY[0]), abs(p[1] - AMY[1])) >= 3
                     and max(abs(p[0] - CHEST[0]), abs(p[1] - CHEST[1])) >= 3)}
for f in range(2, 8):
    ARRIVE[f] = (R[f][0], R[f][1] - 2)
DEVIAS = nearest(WALK[1], DEVIAS_MARK, lambda p: solid_ok(WALK[1], p, AROUND + [(0, 2)]))
DEVIAS_FRONT = (DEVIAS[0], DEVIAS[1] + 1)
ICARUS = nearest(WALK[7], ICARUS_MARK, lambda p: solid_ok(WALK[7], p, AROUND + [(-2, 0)]))
ICARUS_FRONT = (ICARUS[0] - 1, ICARUS[1])

KEEP = {f: [] for f in LEVELS}   # casillas (y alrededor) que quedan libres
KEEP[1] += [ARRIVE[1], AMY, CHEST, DEVIAS, DEVIAS_FRONT, S[1], (S[1][0], S[1][1] + 1)]
for f in range(2, 8):
    KEEP[f] += [R[f], (R[f][0], R[f][1] - 1), ARRIVE[f]]
for f in range(2, 7):
    KEEP[f] += [S[f], (S[f][0], S[f][1] + 1)]
KEEP[7] += [ICARUS, ICARUS_FRONT]


def near_keep(f, p, r=2):
    return any(abs(p[0] - k[0]) <= r and abs(p[1] - k[1]) <= r for k in KEEP[f])


def build_floor(f):
    walk = WALK[f]
    z = LEVELS[f]['z']
    ground, items, flags, attrs = {}, {}, {}, {}

    # bloqueados al lado de lo caminable
    near = set()
    for (x, y) in walk:
        for dx, dy in AROUND:
            p = (x + dx, y + dy)
            if p not in walk:
                near.add(p)
    # componentes bloqueadas encerradas por piso: columnas chicas o pozos grandes
    blocked_near = set()
    for (x, y) in walk:
        for dx in range(-12, 13):
            for dy in range(-12, 13):
                p = (x + dx, y + dy)
                if p not in walk:
                    blocked_near.add(p)
    pillars, pits = set(), set()
    seen = set()
    for p in sorted(near):
        if p in seen:
            continue
        comp, q, closed = {p}, deque([p]), True
        seen.add(p)
        while q:
            c = q.popleft()
            if A(*c) & 8:
                closed = False
            for dx, dy in N4:
                nb = (c[0] + dx, c[1] + dy)
                if nb in walk:
                    continue
                if nb not in blocked_near:
                    closed = False
                    continue
                if nb not in seen:
                    seen.add(nb)
                    comp.add(nb)
                    q.append(nb)
        if not closed:
            continue
        if len(comp) <= 4:
            pillars |= comp
        elif len(comp) <= 400:
            pits.add(frozenset(comp))
    walls = near - pillars

    for p in walk:
        r = rng.random()
        ground[p] = SKULL_SLAB if r < 0.004 else rng.choice(FLOOR)
    for p in pillars:
        ground[p] = rng.choice(FLOOR)
        items[p] = [rng.choice(PILLARS)]

    # paredes de tumba
    torches = []
    for p in walls:
        x, y = p
        h = (x, y - 1) in walk or (x, y + 1) in walk
        v = (x - 1, y) in walk or (x + 1, y) in walk
        if h and v:
            iid = WALL['C']
        elif h:
            iid = rng.choice(WALL['H'])
        elif v:
            iid = rng.choice(WALL['V'])
        else:
            ns = (x, y - 1) in walls or (x, y + 1) in walls
            ew = (x - 1, y) in walls or (x + 1, y) in walls
            if not (ns and ew):
                continue
            iid = WALL['C'] if ((x, y + 1) in walls and (x + 1, y) in walls) else WALL['P']
        ground[p] = rng.choice(FLOOR)
        items[p] = [iid]
        # antorchas en las paredes que miran al piso (al sur o al este)
        if iid in WALL['H'] or iid in WALL['V']:
            hor = iid in WALL['H']
            facing = (x, y + 1) if hor else (x + 1, y)
            if facing in walk and all(abs(x - tx) + abs(y - ty) > 7 for tx, ty in torches) and rng.random() < 0.6:
                items[p].append(TORCH_H if hor else TORCH_V)
                torches.append(p)

    # pozos: lava con fuego dentro de las paredes
    for comp in pits:
        inner = [c for c in comp if c not in walls]
        for c in inner:
            ground[c] = LAVA
        if inner:
            cx = sum(c[0] for c in inner) / len(inner)
            cy = sum(c[1] for c in inner) / len(inner)
            mid = min(inner, key=lambda c: (c[0] - cx) ** 2 + (c[1] - cy) ** 2)
            items[mid] = [rng.choice(PIT_FIRE)]

    # cosas grandes contra las paredes de las salas (solo donde hay lugar, para no cerrar pasillos)
    for p in sorted(walk):
        if p in items or near_keep(f, p, 3) or (f == 1 and p in SAFE):
            continue
        touching = any((p[0] + dx, p[1] + dy) in walls for dx, dy in N4)
        if touching and rng.random() < 0.05:
            # que alrededor quede lugar: al menos un 5x5 casi todo caminable
            free = sum(1 for dx in range(-2, 3) for dy in range(-2, 3) if (p[0] + dx, p[1] + dy) in walk)
            if free >= 15 and not any((p[0] + dx, p[1] + dy) in items and
                                      any(i in ROOM_BLOCK or i in PILLARS for i in items[(p[0] + dx, p[1] + dy)])
                                      for dx in range(-2, 3) for dy in range(-2, 3)):
                items[p] = [rng.choice(ROOM_BLOCK)]
                attrs[p] = AID_FIXED

    # decoración suelta
    for p in walk:
        if p in items or near_keep(f, p, 1):
            continue
        if rng.random() < 0.045:
            items[p] = [rng.choice(FLOOR_DECOR)]
            attrs[p] = AID_FIXED

    tiles = {}
    for p, g in ground.items():
        tiles[(O[f][0] + p[0], O[f][1] + p[1], z)] = [flags.get(p, 0), [g] + items.get(p, []), attrs.get(p, b'')]
    return tiles, walls


tiles = {}
WALLS = {}
for f in LEVELS:
    t, w = build_floor(f)
    tiles.update(t)
    WALLS[f] = w


def T(f, p):
    return tiles[G(f, p)]


def clear_around(f, p, need=AROUND):
    for dx, dy in need:
        q = (p[0] + dx, p[1] + dy)
        if q in WALK[f]:
            t = T(f, q)
            t[1][:] = [t[1][0] if t[1][0] != SKULL_SLAB else 410]
            t[2] = b''


# ---------- escaleras ----------
for f in range(1, 7):
    clear_around(f, S[f], LOWER)
    T(f, S[f])[1][:] = [416, STAIRS_UP]
for f in range(2, 8):
    clear_around(f, R[f], UPPER)
    T(f, R[f])[1][:] = [STAIRS_DOWN]

# ---------- Lost Tower 1: zona segura, Potion Girl Amy, baúl y portal futuro a Devias ----------
for p in SAFE:
    t = T(1, p)
    t[0] = PZ
    t[1][:] = [t[1][0]]
    t[2] = b''
    if rng.random() < 0.08 and not near_keep(1, p, 1):
        t[1].append(rng.choice(CANDLES))
        t[2] = AID_FIXED
clear_around(1, AMY)
clear_around(1, CHEST)
clear_around(1, ARRIVE[1])
chest = T(1, CHEST)
chest[1][:] = [chest[1][0], DEPOT]
chest[2] = b"\x0a" + struct.pack("<H", DEPOT_ID)
for dx in (-1, 1):
    q = (CHEST[0] + dx, CHEST[1])
    if q in SAFE:
        T(1, q)[1][:] = [T(1, q)[1][0], 2110]   # brasero a cada lado del baúl
clear_around(1, DEVIAS, AROUND + [(0, 2)])
T(1, DEVIAS)[1].append(DEATH_PORTAL)
clear_around(7, ICARUS, AROUND + [(-2, 0)])
T(7, ICARUS)[1].append(DEATH_PORTAL)
for f, p in ((1, DEVIAS), (7, ICARUS)):
    # braseros a los costados del portal reservado
    for dx, dy in ((-1, -1), (1, -1)) if f == 1 else ((-1, -1), (-1, 1)):
        q = (p[0] + dx, p[1] + dy)
        if q in WALK[f] and q not in (DEVIAS_FRONT, ICARUS_FRONT):
            T(f, q)[1][:] = [T(f, q)[1][0], 19092]
for f in range(2, 8):
    clear_around(f, ARRIVE[f])

# ---------- vacío negro ----------
# Bajo tierra el cliente muestra hasta 2 pisos de abajo por donde no hay casilla. Como los pisos de la torre
# están uno encima del otro, donde un piso no tiene nada y el de abajo sí, se pone vacío negro (no se pasa).
VOID = 13775   # "deep black gap": negro y no se pasa
_fill = {}
for (x, y, z) in tiles:
    for dz in (1, 2):
        up = (x, y, z - dz)
        if 8 <= up[2] and up not in tiles:
            _fill[up] = [0, [VOID], b'']
tiles.update(_fill)

POIS = {
    'arrive': {f: G(f, p) for f, p in ARRIVE.items()},
    'amy': G(1, AMY),
    'chest': G(1, CHEST),
    'devias_portal': G(1, DEVIAS),
    'devias_front': G(1, DEVIAS_FRONT),
    'icarus_portal': G(7, ICARUS),
    'icarus_front': G(7, ICARUS_FRONT),
    'stairs_up': {f: G(f, p) for f, p in S.items()},
    'stairs_down': {f: G(f, p) for f, p in R.items()},
    'origins': O,
}


def walkable_global(f):
    return {G(f, p) for p in WALK[f]}


def safe_global():
    return {G(1, p) for p in SAFE}


if __name__ == '__main__':
    print('tiles', len(tiles))
    xs = [k[0] for k in tiles]
    ys = [k[1] for k in tiles]
    print('x', min(xs), max(xs), 'y', min(ys), max(ys))
    for f in LEVELS:
        print('Lost Tower', f, 'z', LEVELS[f]['z'], 'origen', O[f], 'casillas', len(WALK[f]))
    print('zona segura', len(SAFE))
    for k, v in POIS.items():
        print(k, v)
