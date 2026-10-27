"""Genera Tarkan (MU, World9) como un desierto de Tibia al estilo de Krailos, con lava donde MU tiene fuego.

La forma (zonas caminables, columnas, pozos y abismos) sale de Data/World9 del cliente de MU
(EncTerrain9.att + textura de EncTerrain9.map, decodificados en tarkan_mu.pkl), pero se dibuja con piezas de Tibia:
- piso caminable -> tierra seca de Krailos (dry floor) con pasto seco, piedras, escombros y cactus
- caminos de MU (líneas de textura) -> arena con el borde de tierra de Krailos
- plaza de ruinas (al oeste del punto blanco) -> piso de sal de Krailos
- zona roja del este, cuadrado del noreste y círculo del sureste -> suelo de roca con huesos y pozos de lava
- columnas chicas de MU -> cactus, rocas rojizas, enebros y arbustos secos
- bloques grandes y el borde -> montaña con borde de grava (como Krailos)
- manchas de fuego de MU (arriba a la izquierda, las dos rayas del centro, el este y el sureste) -> lava
- lo negro de MU -> vacío (sin casilla)

x local = índice // 256, y local = índice % 256 (igual que el minimapa de MU, norte arriba).
Tarkan 1 es la parte oeste y Tarkan 2 la parte este. La única zona protegida es la de MU (abajo a la izquierda),
igual a la que marcó Genaro, con Potion Girl Amy, el baúl (depot) y el teleport a Atlans 3.

Salida: tiles {(x, y, z): [flags, [ground, items...], attrs]} en coordenadas globales y POIS.
"""
import os
import pickle
import random
import struct
from collections import deque

HERE = os.path.dirname(os.path.abspath(__file__))
att, tex = pickle.load(open(os.path.join(HERE, 'tarkan_mu.pkl'), 'rb'))
rng = random.Random(9009)

OX, OY, Z = 1570, 1005, 7
PZ = 1

# puntos que marcó Genaro en el mapa de MU (x, y locales)
RED = (46, 250)      # teleport a Atlans 3
BLUE = (64, 200)     # llegada a Tarkan
PINK = (74, 197)     # Potion Girl Amy
VIOLET = (68, 191)   # baúl
WHITE = (164, 94)    # llegada a Tarkan 2

N4 = ((1, 0), (-1, 0), (0, 1), (0, -1))
AROUND = [(dx, dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1)]


def A(p):
    x, y = p
    if 0 <= x < 256 and 0 <= y < 256:
        return att[x * 256 + y]
    return 8


def TX(p):
    x, y = p
    if 0 <= x < 256 and 0 <= y < 256:
        return tex[x * 256 + y]
    return 0


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


WALK = flood(BLUE, lambda p: A(p) & 12 == 0)
assert len(WALK) > 20000, len(WALK)
SAFE = {p for p in WALK if A(p) & 1}


def nearest(cells, target, ok=lambda p: True):
    return min((p for p in cells if ok(p)), key=lambda p: (p[0] - target[0]) ** 2 + (p[1] - target[1]) ** 2)


def roomy(cells, p, r=1):
    return all((p[0] + dx, p[1] + dy) in cells for dx in range(-r, r + 1) for dy in range(-r, r + 1))


def tarkan2(p):
    x, y = p
    return x >= 115 and not (y >= 138 and x < 175)


# ---------- zonas ----------
def big_tex10(p):
    # zonas grandes de textura 10 (cuadrado NE y círculo SE): no son caminos
    n = sum(1 for dx in range(-3, 4) for dy in range(-3, 4) if TX((p[0] + dx, p[1] + dy)) == 10)
    return n >= 30


def zone(p):
    x, y = p
    if p in SAFE:
        return 'safe'
    if x >= 190 and y <= 60:
        return 'ne'
    if x >= 175 and y >= 135:
        return 'se'
    if x >= 208 and 66 <= y <= 132:
        return 'east'
    if TX(p) == 3:
        return 'plaza'
    return 'desert'


ROAD = set()
for p in WALK:
    if TX(p) == 10 and zone(p) == 'desert' and not big_tex10(p):
        for dx, dy in AROUND:
            q = (p[0] + dx, p[1] + dy)
            if q in WALK and zone(q) == 'desert':
                ROAD.add(q)

# ---------- bloqueados: columnas, montaña, lava ----------
near = {}   # bloqueado -> distancia (chebyshev) a lo caminable, hasta 3
for (x, y) in WALK:
    for dx in range(-3, 4):
        for dy in range(-3, 4):
            q = (x + dx, y + dy)
            if q not in WALK:
                d = max(abs(dx), abs(dy))
                if d < near.get(q, 9):
                    near[q] = d
# componentes de bloqueados pegados al piso
comps = []
seen = set()
for p in sorted(near):
    if p in seen or near[p] != 1:
        continue
    comp, q, closed = {p}, deque([p]), True
    seen.add(p)
    while q:
        c = q.popleft()
        for dx, dy in N4:
            nb = (c[0] + dx, c[1] + dy)
            if nb in WALK:
                continue
            if nb not in near:
                closed = False
                continue
            if nb not in seen:
                seen.add(nb)
                comp.add(nb)
                q.append(nb)
    comps.append((comp, closed))

# manchas de fuego de MU (rectángulos locales)
LAVA_BOXES = [
    (50, 42, 70, 62),      # pozo de fuego arriba a la izquierda
    (164, 76, 176, 93),    # raya de lava del centro (izquierda)
    (175, 84, 188, 115),   # raya de lava del centro (derecha)
    (212, 66, 252, 132),   # resplandor rojo del este
]


def in_lava_box(p):
    return any(a <= p[0] <= c and b <= p[1] <= d for a, b, c, d in LAVA_BOXES)


OBST = set()     # columnas chicas -> cactus / rocas
LAVA = set()
MOUNT = set()
for comp, closed in comps:
    if closed and len(comp) <= 4:
        OBST |= comp
        continue
    fiery = any(in_lava_box(c) for c in comp) or (closed and len(comp) <= 120 and
                                                     any(zone(nb) in ('east', 'se') for c in comp for nb in
                                                         [(c[0] + 1, c[1]), (c[0] - 1, c[1])] if nb in WALK))
    for c in comp:
        if fiery and (closed or (in_lava_box(c) and A(c) & 8 == 0)):
            # la lava queda adentro y la montaña alrededor si el pozo es abierto
            LAVA.add(c)
        else:
            MOUNT.add(c)
# el resto de lo bloqueado cerca del piso (anillos de más de 1 de distancia) es montaña
for p, d in near.items():
    if p not in OBST and p not in LAVA:
        MOUNT.add(p)
# las manchas de fuego grandes (arriba a la izquierda y el este) se llenan enteras de lava hasta 6 casillas del
# piso, y alrededor de la lava queda montaña
for a, b, c, d in LAVA_BOXES[::3]:
    for x in range(a, c + 1):
        for y in range(b, d + 1):
            p = (x, y)
            if p in WALK or p in OBST:
                continue
            if any((x + dx, y + dy) in WALK for dx in range(-6, 7) for dy in range(-6, 7)):
                LAVA.add(p)
MOUNT -= LAVA
for p in list(LAVA):
    for dx in range(-2, 3):
        for dy in range(-2, 3):
            q = (p[0] + dx, p[1] + dy)
            if q not in WALK and q not in LAVA and q not in OBST:
                MOUNT.add(q)

# ---------- piezas de Tibia ----------
GRASS = [22348, 22349, 22350]
DIRT = [22355] * 33 + [22356] * 33 + [22357] * 33 + [22358, 22360, 22542, 22543]
SAND = [231] * 6 + [614]
SALT = [22414] * 10 + [22415] * 5 + [22416] * 10 + [22417]      # sal amarilla de Krailos
RED_FLOOR = [12379] * 5 + [12380, 12382, 12384, 12385, 12386] * 2 + [12381, 12383]   # suelo rocoso rojo
MOUNTAIN = 1128
LAVA_G = [21477] * 18 + [729, 730]
BRUSH = {  # nombre: (z-order, borde exterior)
    'red': (4200, [158]),
    'salt': (800, [207]),
    'grass': (3000, [202]),
    'sand': (4300, [16]),
    'dirt': (4400, [203]),
    'lava': (7700, [211]),
    'mount': (9900, [29, 10]),
}
BORDERS = {
    16: dict(n=4761, e=4764, s=4762, w=4763, cnw=4765, cne=4766, csw=4767, cse=4768, dnw=4769, dne=4770, dsw=4771, dse=4772),
    158: dict(n=12357, e=12358, s=12356, w=12359, cnw=12366, cne=12367, csw=12365, cse=12364, dnw=12362, dne=12363, dsw=12361, dse=12360),
    202: dict(n=22362, e=22373, s=22372, w=22363, cnw=22364, cne=22365, csw=22366, cse=22367, dnw=22368, dne=22369, dsw=22370, dse=22371),
    203: dict(n=22386, e=22397, s=22396, w=22387, cnw=22388, cne=22389, csw=22390, cse=22391, dnw=22392, dne=22393, dsw=22394, dse=22395),
    207: dict(n=22446, e=22447, s=22448, w=22449, cnw=22450, cne=22451, csw=22452, cse=22453, dnw=22454, dne=22455, dsw=22456, dse=22457),
    211: dict(n=14100, e=14101, s=14102, w=14103, cnw=14106, cne=14107, csw=14105, cse=14104, dnw=14110, dne=14111, dsw=14109, dse=14108),
    29: dict(n=4460, e=4457, s=4458, w=4461, cnw=4464, cne=4463, csw=4462, cse=4459, dnw=4465, dne=4467, dsw=4466, dse=4468),
    10: dict(n=4445, e=4446, s=4447, w=4448, cnw=4449, cne=4450, cse=4451, csw=4452, dnw=4453, dne=4454, dse=4455, dsw=4456),
}
# obstáculos del desierto (no se pasan)
CACTUS = [22290, 22291, 22290, 22291, 22284, 22285, 22286, 22287, 22288, 22289, 22293, 22294, 3698, 1852]
ROCK_OBST = [22284, 22285, 22286, 22287, 22288, 22289, 1852, 1852]
# decoración suelta que se pisa
DESERT_DECOR = [9820, 9821, 9822, 9823] * 3 + [6378, 6379, 6380, 6381, 6480, 6481, 6482, 6483, 6484, 6485, 6486, 6487] + \
    [1855, 1856, 1857, 1865, 1866, 1867, 7487, 7488, 7489, 22298, 22299, 22644, 22298, 22299, 22644, 9824]
BONES = [3114, 3115, 3116, 3115, 3116, 6378, 6379, 6380, 6381, 7487, 7488, 7489, 1855, 1857]
CAMPFIRE = [1998, 1999, 2000]
COAL_BASIN = 2110
BLAZING = 19092
DEPOT = 3499
DEPOT_ID = 11
AID_FIXED = b"\x04" + struct.pack("<H", 100)   # action id 100 = no se puede mover

# ---------- lugares especiales ----------
ARRIVE1 = nearest(SAFE, BLUE, lambda p: roomy(SAFE, p, 1))
AMY = nearest(SAFE, PINK, lambda p: roomy(WALK, p, 1) and max(abs(p[0] - ARRIVE1[0]), abs(p[1] - ARRIVE1[1])) >= 3)
CHEST = nearest(SAFE, VIOLET, lambda p: roomy(WALK, p, 1) and max(abs(p[0] - ARRIVE1[0]), abs(p[1] - ARRIVE1[1])) >= 3
                and max(abs(p[0] - AMY[0]), abs(p[1] - AMY[1])) >= 3)
TP_ATLANS = nearest(SAFE, RED, lambda p: roomy(SAFE, p, 1))
ARRIVE2 = nearest(WALK, WHITE, lambda p: roomy(WALK, p, 2) and p not in ROAD)
KEEP = [ARRIVE1, AMY, CHEST, TP_ATLANS, ARRIVE2]


def near_keep(p, r=2):
    return any(abs(p[0] - k[0]) <= r and abs(p[1] - k[1]) <= r for k in KEEP)


# ---------- manchas de pasto seco (ruido suave) ----------
_cell = 14
_grid = {(i, j): rng.random() for i in range(-1, 256 // _cell + 3) for j in range(-1, 256 // _cell + 3)}


def noise(p):
    fx, fy = p[0] / _cell, p[1] / _cell
    i, j = int(fx), int(fy)
    tx, ty = fx - i, fy - j
    a = _grid[(i, j)] * (1 - tx) + _grid[(i + 1, j)] * tx
    b = _grid[(i, j + 1)] * (1 - tx) + _grid[(i + 1, j + 1)] * tx
    return a * (1 - ty) + b * ty


# ---------- casillas ----------
brush = {}
for p in WALK:
    z = zone(p)
    if z in ('ne', 'se', 'east'):
        brush[p] = 'red'
    elif z == 'plaza':
        brush[p] = 'salt'
    elif z == 'safe' or p in ROAD:
        brush[p] = 'sand'
    elif noise(p) > 0.68:
        brush[p] = 'grass'
    else:
        brush[p] = 'dirt'
for p in OBST:
    nbs = [brush.get((p[0] + dx, p[1] + dy)) for dx, dy in N4]
    brush[p] = 'red' if 'red' in nbs else 'dirt'
for p in LAVA:
    brush[p] = 'lava'
for p in MOUNT:
    brush[p] = 'mount'

ground, items, attrs = {}, {}, {}
for p, b in brush.items():
    ground[p] = rng.choice({'grass': GRASS, 'red': RED_FLOOR, 'salt': SALT, 'sand': SAND, 'dirt': DIRT, 'lava': LAVA_G, 'mount': [MOUNTAIN]}[b])

EDGE_ORDER = ['dnw', 'dne', 'dsw', 'dse']


def edges(has):
    n, e, s, w = has['n'], has['e'], has['s'], has['w']
    out = []
    used = set()
    for name, a, b in (('dnw', 'n', 'w'), ('dne', 'n', 'e'), ('dsw', 's', 'w'), ('dse', 's', 'e')):
        if has[a] and has[b] and a not in used and b not in used:
            out.append(name)
            used |= {a, b}
    for side in ('n', 'e', 's', 'w'):
        if has[side] and side not in used:
            out.append(side)
            used.add(side)
    for name, a, b in (('cnw', 'n', 'w'), ('cne', 'n', 'e'), ('csw', 's', 'w'), ('cse', 's', 'e')):
        if has[name[1:]] and not has[a] and not has[b]:
            out.append(name)
    return out


OFF = dict(n=(0, -1), e=(1, 0), s=(0, 1), w=(-1, 0), nw=(-1, -1), ne=(1, -1), sw=(-1, 1), se=(1, 1))
border_items = {}
for p, b in brush.items():
    if b == 'mount':
        continue
    zb = BRUSH[b][0]
    higher = sorted({brush.get((p[0] + dx, p[1] + dy)) for dx, dy in OFF.values()} - {None, b},
                    key=lambda k: BRUSH[k][0])
    out = []
    for hb in higher:
        if BRUSH[hb][0] <= zb:
            continue
        has = {k: brush.get((p[0] + d[0], p[1] + d[1])) == hb for k, d in OFF.items()}
        for bid in BRUSH[hb][1]:
            out += [BORDERS[bid][e] for e in edges(has)]
    if out:
        border_items[p] = out

# ---------- decoración ----------
torches = []
for p in sorted(WALK):
    if near_keep(p, 2):
        continue
    z = zone(p)
    r = rng.random()
    if z == 'safe':
        continue
    touching_mount = any(brush.get((p[0] + dx, p[1] + dy)) == 'mount' for dx, dy in N4)
    free5 = sum(1 for dx in range(-2, 3) for dy in range(-2, 3) if (p[0] + dx, p[1] + dy) in WALK)
    if z in ('ne', 'se', 'east'):
        if r < 0.05:
            items[p] = [rng.choice(BONES)]
            attrs[p] = AID_FIXED
        elif r < 0.058 and free5 >= 22 and p not in border_items:
            items[p] = [rng.choice(ROCK_OBST)]
        elif r < 0.062 and free5 >= 22 and p not in border_items and \
                all(abs(p[0] - t[0]) + abs(p[1] - t[1]) > 9 for t in torches):
            items[p] = [rng.choice(CAMPFIRE)]   # fuego suelto (da luz)
            attrs[p] = AID_FIXED
            torches.append(p)
    elif z == 'plaza':
        if r < 0.02:
            items[p] = [rng.choice([1855, 1857, 6378, 6380, 7488])]
            attrs[p] = AID_FIXED
    else:
        if p in ROAD:
            if r < 0.01:
                items[p] = [rng.choice([1855, 1857, 6380])]
                attrs[p] = AID_FIXED
            continue
        if r < 0.11:
            items[p] = [rng.choice(DESERT_DECOR)]
            attrs[p] = AID_FIXED
        elif r < 0.125 and free5 >= 20 and (touching_mount or r < 0.117):
            items[p] = [rng.choice(CACTUS)]
for p in OBST:
    items[p] = [rng.choice(ROCK_OBST if brush[p] == 'red' else CACTUS)]

# rocas rojizas grandes sobre el borde de la montaña (como en Krailos)
for p in sorted(MOUNT):
    if any((p[0] + dx, p[1] + dy) in WALK for dx, dy in N4) and rng.random() < 0.12:
        items[p] = [rng.choice(ROCK_OBST[:6])]

# plaza de ruinas: braseros en las esquinas
plaza = [p for p in WALK if zone(p) == 'plaza']
if plaza:
    xs = sorted(p[0] for p in plaza)
    ys = sorted(p[1] for p in plaza)
    for corner in ((xs[0], ys[0]), (xs[-1], ys[0]), (xs[0], ys[-1]), (xs[-1], ys[-1])):
        c = nearest(plaza, corner, lambda p: roomy(WALK, p, 1) and not near_keep(p, 2))
        items[c] = [COAL_BASIN]

# ---------- zona segura: Amy, baúl, teleport a Atlans 3 ----------
for p in SAFE:
    if p in border_items:
        continue
    wall = any(brush.get((p[0] + dx, p[1] + dy)) == 'mount' for dx, dy in N4)
    if wall and rng.random() < 0.10 and not near_keep(p, 2):
        items[p] = [rng.choice([22295, 22296, 22297])]   # palmeras contra las rocas
    elif rng.random() < 0.03 and not near_keep(p, 2):
        items[p] = [rng.choice([1855, 1857, 9820, 9822, 6380])]
        attrs[p] = AID_FIXED


def clear(p, r=1):
    for dx in range(-r, r + 1):
        for dy in range(-r, r + 1):
            q = (p[0] + dx, p[1] + dy)
            if q in WALK:
                items.pop(q, None)
                attrs.pop(q, None)


for k in KEEP:
    clear(k)
items[CHEST] = [DEPOT]
attrs[CHEST] = b"\x0a" + struct.pack("<H", DEPOT_ID)
for dx in (-1, 1):
    q = (CHEST[0] + dx, CHEST[1])
    if q in SAFE:
        items[q] = [COAL_BASIN]   # brasero a cada lado del baúl
# braseros ardientes a los costados del teleport (el teleport lo crea teleports.lua al arrancar)
for dx in (-1, 1):
    q = (TP_ATLANS[0] + dx, TP_ATLANS[1] - 1)
    if q in WALK and q != TP_ATLANS:
        items[q] = [BLAZING]
# fogata cerca de la llegada
fire = nearest(SAFE, (ARRIVE1[0] - 3, ARRIVE1[1] + 3), lambda p: roomy(SAFE, p, 1) and not near_keep(p, 1))
items[fire] = [rng.choice(CAMPFIRE)]
attrs[fire] = AID_FIXED

tiles = {}
for p, g in ground.items():
    stack = [g] + border_items.get(p, []) + items.get(p, [])
    flags = PZ if p in SAFE else 0
    a = attrs.get(p, b'') if p in items else b''
    tiles[(OX + p[0], OY + p[1], Z)] = [flags, stack, a]


def G(p):
    return (OX + p[0], OY + p[1], Z)


POIS = {
    'arrive1': G(ARRIVE1),
    'arrive2': G(ARRIVE2),
    'amy': G(AMY),
    'chest': G(CHEST),
    'tp_atlans': G(TP_ATLANS),
}


def walkable_global():
    return {G(p) for p in WALK}


def safe_global():
    return {G(p) for p in SAFE}


def is_tarkan2(gp):
    return tarkan2((gp[0] - OX, gp[1] - OY))


def zone_global(gp):
    return zone((gp[0] - OX, gp[1] - OY))


if __name__ == '__main__':
    print('tiles', len(tiles), 'walk', len(WALK), 'safe', len(SAFE), 'lava', len(LAVA), 'mount', len(MOUNT),
          'obst', len(OBST), 'road', len(ROAD))
    xs = [k[0] for k in tiles]
    ys = [k[1] for k in tiles]
    print('x', min(xs), max(xs), 'y', min(ys), max(ys))
    for k, v in POIS.items():
        print(k, v)
