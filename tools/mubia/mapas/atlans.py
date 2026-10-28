"""Genera Atlans (MU, World8) como un fondo de mar estilo Calassa de Tibia (piso 7).

La forma (por dónde se camina, la zona segura y las rocas sueltas) sale de Data/World8 del cliente de MU
(EncTerrain8.att, decodificado en atlans_mu.pkl), pero se dibuja con piezas de Calassa:
- piso caminable de MU -> fondo de mar (5405-5409) con algas, corales chicos, estrellas, peces y conchas
- rocas sueltas de MU (bloqueadas y rodeadas de piso) -> arrecifes de coral y algas que no se pasan
- borde de lo caminable -> borde de tierra de Calassa (5638-5653) con corales, y detrás tierra (101)
- lo negro de MU -> vacío (sin casilla)
- barcos hundidos copiados del Calassa real (atlans_calassa.pkl) en los lugares abiertos.

x local = índice // 256, y local = índice % 256 (igual que el minimapa de MU, norte arriba).
Atlans 1 = zona segura de arriba a la izquierda (única zona protegida), Atlans 2 = abajo a la izquierda,
Atlans 3 = centro arriba. Arriba a la derecha queda reservado el portal a Tarkan.

Salida: tiles {(x, y, z): (flags, [ground, items...])} en coordenadas globales, WALK (casillas locales
caminables), POIS (llegadas del menú M, portal de Tarkan).
"""
import os
import pickle
import random
from collections import deque

HERE = os.path.dirname(os.path.abspath(__file__))
att, l2 = pickle.load(open(os.path.join(HERE, 'atlans_mu.pkl'), 'rb'))
STAMPS = pickle.load(open(os.path.join(HERE, 'atlans_calassa.pkl'), 'rb'))
rng = random.Random(808)

OX, OY, Z = 1300, 1040, 7
PZ = 1   # flag de zona protegida en el otbm


def A(x, y):
    if 0 <= x < 256 and 0 <= y < 256:
        return att[x * 256 + y]
    return 4


def walk_mu(p):
    return A(*p) & 4 == 0


# ---------- piezas de Calassa ----------
SEABED = [5405, 5406, 5407, 5408, 5409]
EARTH = 101
BORDER = dict(N=5639, S=5641, E=5640, W=5638, iNE=5651, iNW=5647, iSE=5652, iSW=5653,
              NW=5644, NE=5645, SE=5642, SW=5643)
REEF = [5412, 5412, 5412, 5410, 5421, 5422, 5413, 5414, 5415, 5420, 5420, 5411]   # no se pasan
KELP = [5420]
DECOR = [5418, 5418, 5419, 5419, 5553, 5416, 5417, 1855, 1856, 1857, 1865, 1866, 1867, 5679, 5681, 5682]
VORTEX = 9158   # remolino de agua: marca el lugar del futuro portal a Tarkan

AROUND = [(dx, dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1)]
N4 = ((1, 0), (-1, 0), (0, 1), (0, -1))

# ---------- zonas ----------
WALK = {(x, y) for x in range(256) for y in range(256) if walk_mu((x, y))}
SAFE = {p for p in WALK if A(*p) & 1}


def flood(start, cells):
    dist = {start: 0}
    q = deque([start])
    while q:
        c = q.popleft()
        for dx, dy in N4:
            n = (c[0] + dx, c[1] + dy)
            if n in cells and n not in dist:
                dist[n] = dist[c] + 1
                q.append(n)
    return dist


def nearest(cells, target, ok=lambda p: True):
    return min((p for p in cells if ok(p)), key=lambda p: (p[0] - target[0]) ** 2 + (p[1] - target[1]) ** 2)


def roomy(p, r=1):
    return all((p[0] + dx, p[1] + dy) in WALK for dx in range(-r, r + 1) for dy in range(-r, r + 1))


sx = sum(p[0] for p in SAFE) / len(SAFE)
sy = sum(p[1] for p in SAFE) / len(SAFE)
# puntos marcados por Genaro en el mapa de MU (rojo, verde, amarillo, blanco)
ARRIVE = {
    1: nearest(SAFE, (sx, sy), lambda p: roomy(p, 2)),
    2: nearest(WALK, (52, 230), lambda p: roomy(p, 2)),
    3: nearest(WALK, (162, 67), lambda p: roomy(p, 2)),
}
TARKAN = nearest(WALK, (231, 13), lambda p: roomy(p, 2))           # remolino (portal futuro)
TARKAN_FRONT = (TARKAN[0], TARKAN[1] + 1)                           # donde se para el jugador

# ---------- bloqueados: rocas sueltas (arrecifes) o borde ----------
blocked_near = set()
for (x, y) in WALK:
    for dx in range(-3, 4):
        for dy in range(-3, 4):
            p = (x + dx, y + dy)
            if p not in WALK:
                blocked_near.add(p)

reefs = set()
seen = set()
for p in blocked_near:
    if p in seen:
        continue
    comp, q, closed = {p}, deque([p]), True
    seen.add(p)
    while q:
        c = q.popleft()
        for dx, dy in N4:
            n = (c[0] + dx, c[1] + dy)
            if n in WALK:
                continue
            if n not in blocked_near or not (0 <= n[0] < 256 and 0 <= n[1] < 256):
                closed = False
                continue
            if n not in seen:
                seen.add(n)
                comp.add(n)
                q.append(n)
    if closed and len(comp) <= 60:
        reefs |= comp

SEA = WALK | reefs
ring1 = {p for p in blocked_near - reefs if any((p[0] + dx, p[1] + dy) in SEA for dx, dy in AROUND)}
SEA_EXT = SEA | ring1
earth = {p for p in blocked_near - SEA_EXT
         if any(max(abs(dx), abs(dy)) <= 2 and (p[0] + dx, p[1] + dy) in ring1
                for dx in range(-2, 3) for dy in range(-2, 3))}
# huecos chicos encerrados por el borde: todo tierra (para que no queden cuadrados negros sueltos)
_rest = {(x, y) for x in range(-3, 259) for y in range(-3, 259)} - SEA_EXT - earth
_seen = set()
for p in sorted(_rest):
    if p in _seen:
        continue
    comp, q = {p}, deque([p])
    _seen.add(p)
    while q:
        c = q.popleft()
        for dx, dy in N4:
            n = (c[0] + dx, c[1] + dy)
            if n in _rest and n not in _seen:
                _seen.add(n)
                comp.add(n)
                q.append(n)
    if len(comp) <= 300 and not any(c[0] < 0 or c[1] < 0 or c[0] > 255 or c[1] > 255 for c in comp):
        earth |= comp

DIRS = dict(NW=(-1, -1), N=(0, -1), NE=(1, -1), E=(1, 0), SE=(1, 1), S=(0, 1), SW=(-1, 1), W=(-1, 0))


def border_pieces(x, y):
    o = {k: (x + dx, y + dy) not in SEA_EXT for k, (dx, dy) in DIRS.items()}
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
    return [BORDER[k] for k in out]


ground, items, flags = {}, {}, {}
for p in SEA_EXT:
    ground[p] = rng.choice(SEABED)
for p in earth:
    ground[p] = EARTH

# borde: tierra de Calassa por encima del fondo de mar y a veces un coral (siempre bloqueado)
for p in ring1:
    b = border_pieces(*p)
    extra = [rng.choice(REEF)] if (not b or rng.random() < 0.45) else []
    items[p] = b + extra

# arrecifes: rocas sueltas de MU -> corales y algas (no se pasan)
for p in reefs:
    items[p] = [rng.choice(REEF)]
    if rng.random() < 0.25:
        items[p].append(rng.choice(KELP))

# ---------- barcos hundidos de Calassa ----------
KEEP_CLEAR = [ARRIVE[1], ARRIVE[2], ARRIVE[3], TARKAN]
SAFE_BOX = (min(p[0] for p in SAFE) - 6, min(p[1] for p in SAFE) - 6,
            max(p[0] for p in SAFE) + 6, max(p[1] for p in SAFE) + 6)
UNPASS = None   # se completa desde build_atlans con iteminfo (si no, se usa una lista fija)
UNPASS_FALLBACK = set(REEF) | set(range(5441, 5459)) | set(BORDER.values()) | {4894, 4932, 4933, VORTEX}


def is_unpass(i):
    return i in (UNPASS if UNPASS is not None else UNPASS_FALLBACK)


placed = []


def try_stamp(s, x0, y0):
    cells = [(x0 + dx, y0 + dy) for (dx, dy) in s['tiles']]
    # todo el barco (y un margen de 2) tiene que caer sobre piso caminable de MU
    for (dx, dy) in s['tiles']:
        for mx, my in ((0, 0), (2, 0), (-2, 0), (0, 2), (0, -2)):
            if (x0 + dx + mx, y0 + dy + my) not in WALK:
                return False
    if any(SAFE_BOX[0] <= c[0] <= SAFE_BOX[2] and SAFE_BOX[1] <= c[1] <= SAFE_BOX[3] for c in cells):
        return False
    if any(abs(c[0] - k[0]) <= 8 and abs(c[1] - k[1]) <= 8 for c in cells for k in KEEP_CLEAR):
        return False
    if any(abs(x0 - px) < pw + 14 and abs(y0 - py) < ph + 14 for (px, py, pw, ph) in placed):
        return False
    # que no deje casillas encerradas: el piso del barco tiene que seguir conectado con el resto
    local_walk = {(x0 + dx, y0 + dy) for (dx, dy), st in s['tiles'].items() if not any(is_unpass(i) for i in st)}
    ring = set()
    for c in cells:
        for dx, dy in AROUND:
            n = (c[0] + dx, c[1] + dy)
            if n not in s_cells(s, x0, y0):
                ring.add(n)
    area = local_walk | ring
    start = next(iter(ring))
    reach = flood(start, area)
    if len(reach) < len(area) * 0.97:
        return False
    for (dx, dy), st in s['tiles'].items():
        p = (x0 + dx, y0 + dy)
        ground[p] = st[0]
        items[p] = list(st[1:])
    placed.append((x0, y0, s['w'], s['h']))
    return True


def s_cells(s, x0, y0):
    return {(x0 + dx, y0 + dy) for (dx, dy) in s['tiles']}


def place_wrecks(count=12):
    order = list(range(len(STAMPS)))
    rng.shuffle(order)
    walk_list = sorted(WALK)
    for i in order:
        s = STAMPS[i]
        if len(placed) >= count:
            break
        for _ in range(400):
            x, y = rng.choice(walk_list)
            if try_stamp(s, x - s['w'] // 2, y - s['h'] // 2):
                break


# ---------- decoración del piso ----------
def decorate():
    for p in WALK:
        if p in items:
            continue
        r = rng.random()
        tex = l2[p[0] * 256 + p[1]]
        # algas y corales grandes solo en casillas con lugar alrededor (para no cerrar pasillos)
        if p not in SAFE and r < 0.035 and roomy(p, 2) and \
                all(abs(p[0] - k[0]) > 3 or abs(p[1] - k[1]) > 3 for k in KEEP_CLEAR):
            items[p] = [rng.choice(REEF)]
        elif r < (0.13 if tex in (7, 8, 9, 10) else 0.08):
            items[p] = [rng.choice(DECOR)]


def build():
    place_wrecks()
    decorate()
    # nada que bloquee al lado de las llegadas
    for k in (ARRIVE[1], ARRIVE[2], ARRIVE[3], TARKAN_FRONT):
        for dx in range(-1, 2):
            for dy in range(-1, 2):
                p = (k[0] + dx, k[1] + dy)
                if p in items:
                    items[p] = [i for i in items[p] if not is_unpass(i)]
    # zona segura (Atlans 1): conchas y estrellas alrededor de la llegada
    for p in SAFE:
        flags[p] = PZ
        if p not in items and rng.random() < 0.12:
            items[p] = [rng.choice([5416, 5417, 5679, 5681, 5682, 5419])]
    items[TARKAN] = [VORTEX]
    for p in (ARRIVE[1], ARRIVE[2], ARRIVE[3], TARKAN_FRONT):
        items.pop(p, None)
    out = {}
    for p, g in ground.items():
        out[(OX + p[0], OY + p[1], Z)] = (flags.get(p, 0), [g] + items.get(p, []))
    return out


def G(p):
    return (OX + p[0], OY + p[1], Z)


POIS = {
    'arrive': {f: G(p) for f, p in ARRIVE.items()},
    'tarkan_vortex': G(TARKAN),
    'tarkan_front': G(TARKAN_FRONT),
}


def walkable_global():
    return {G(p) for p in WALK}


def safe_global():
    return {G(p) for p in SAFE}


if __name__ == '__main__':
    tiles = build()
    print('tiles', len(tiles), 'caminables', len(WALK), 'zona segura', len(SAFE), 'arrecifes', len(reefs),
          'borde', len(ring1), 'tierra', len(earth), 'barcos', len(placed))
    for k, v in POIS.items():
        print(k, v)
