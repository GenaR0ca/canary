"""Mubia Online: las 7 arenas de Devil Square (estilo Tibia, inspiradas en MU).

Cada arena es una sala cerrada de piedra oscura con pozos de lava en las esquinas, estatuas y braseros.
No tiene puertas: se entra y se sale solo con el NPC Charon (data/scripts/mubia/devil_square.lua).
Región vacía x2310-2547, y600-627, z7. Uso: ver build_devil_square.py.
"""
import random

Z = 7
OX, OY = 2310, 600
SIZE = 28          # con paredes; adentro quedan 26x26
GAP = 6
LEVELS = 7

DARK_WALL = dict(H=[22545, 22547], V=[22544, 22549], CORNER=22548, POLE=22546)
DARK_FLOOR = [9849] * 25 + [9850] * 20 + [9851] * 20 + [9852] * 10 + [9853] * 5 + [9855] * 25 + [9856] * 25 + [9857] * 25
MARBLE = [410]
LAVA = [21477] * 100 + [729] * 5 + [730] * 5  # lava que no se puede pisar
LAVA_BORDER = dict(n=14100, e=14101, s=14102, w=14103, cnw=14106, cne=14107, csw=14105, cse=14104,
                   dnw=14110, dne=14111, dsw=14109, dse=14108)
BASIN = 2110        # brasero encendido
STATUE = 746        # estatua de obsidiana (parece un demonio)
GARGOYLE = [2035, 2036]

DIRS = dict(nw=(-1, -1), n=(0, -1), ne=(1, -1), e=(1, 0), se=(1, 1), s=(0, 1), sw=(-1, 1), w=(-1, 0))


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


def wall_piece(cells, x, y, rng):
    n = (x, y - 1) in cells
    s = (x, y + 1) in cells
    e = (x + 1, y) in cells
    w = (x - 1, y) in cells
    if e and s:
        return DARK_WALL['CORNER']
    if (n or s) and (e or w):
        return DARK_WALL['POLE']
    if n or s:
        return rng.choice(DARK_WALL['V'])
    return rng.choice(DARK_WALL['H'])


def arena(level, rng):
    """Devuelve (tiles locales {(x,y): [ids]}, centro local, casillas libres para monstruos)."""
    floor = MARBLE if level in (3, 4) else DARK_FLOOR
    lava = set()
    # pozos de lava en las 4 esquinas; desde la +5 también una cruz de lava cortada alrededor del centro
    pool = 4 if level < 4 else 5
    for (cx, cy) in ((3, 3), (SIZE - 3 - pool, 3), (3, SIZE - 3 - pool), (SIZE - 3 - pool, SIZE - 3 - pool)):
        for y in range(cy, cy + pool):
            for x in range(cx, cx + pool):
                lava.add((x, y))
    if level >= 5:
        c = SIZE // 2
        for k in range(4, 8):
            for (x, y) in ((c - k, c - 1), (c - k, c), (c + k - 1, c - 1), (c + k - 1, c),
                           (c - 1, c - k), (c, c - k), (c - 1, c + k - 1), (c, c + k - 1)):
                lava.add((x, y))
    if level >= 7:
        # el +7 tiene un anillo extra de lava al pie de las paredes (con huecos)
        for k in range(2, SIZE - 2):
            if k % 6 not in (0, 1):
                lava.update({(k, 1), (k, SIZE - 2), (1, k), (SIZE - 2, k)})

    walls = set()
    for k in range(SIZE):
        walls.update({(k, 0), (k, SIZE - 1), (0, k), (SIZE - 1, k)})

    tiles, items, blocked = {}, {}, set(walls) | lava
    for (x, y) in walls:
        items[(x, y)] = [wall_piece(walls, x, y, rng)]

    def put(x, y, iid):
        if (x, y) in lava or (x, y) in walls:
            return
        items.setdefault((x, y), []).append(iid)
        blocked.add((x, y))

    # estatuas mirando al centro en la punta interior de cada pozo, braseros en las paredes
    for (x, y) in ((3 + pool, 3 + pool), (SIZE - 4 - pool, 3 + pool), (3 + pool, SIZE - 4 - pool), (SIZE - 4 - pool, SIZE - 4 - pool)):
        put(x, y, STATUE)
    inner = 2 if level >= 7 else 1
    for k in range(5, SIZE - 5, 6):
        put(k, inner, BASIN)
        put(k, SIZE - 1 - inner, BASIN)
        put(inner, k, BASIN)
        put(SIZE - 1 - inner, k, BASIN)
    c = SIZE // 2
    for (x, y) in ((c - 3, c - 3), (c + 2, c - 3), (c - 3, c + 2), (c + 2, c + 2)):
        put(x, y, GARGOYLE[(x + y) % 2])

    for y in range(SIZE):
        for x in range(SIZE):
            if (x, y) in lava:
                ground = rng.choice(LAVA)
                stack = [ground]
            else:
                ground = rng.choice(floor)
                stack = [ground]
                if (x, y) not in walls:
                    for p in border_pieces(x, y, lambda a, b: (a, b) in lava):
                        stack.append(LAVA_BORDER[p])
            stack += items.get((x, y), [])
            tiles[(x, y)] = stack

    free = [(x, y) for y in range(1, SIZE - 1) for x in range(1, SIZE - 1) if (x, y) not in blocked]
    return tiles, (c, c), free


def build():
    rng = random.Random(666)
    tiles = {}
    info = []
    for level in range(1, LEVELS + 1):
        x0 = OX + (level - 1) * (SIZE + GAP)
        local, center, free = arena(level, rng)
        for (x, y), stack in local.items():
            # 8 = no se puede desloguear adentro
            flags = 8 if 0 < x < SIZE - 1 and 0 < y < SIZE - 1 else 0
            tiles[(x0 + x, OY + y, Z)] = (flags, stack)
        info.append(dict(level=level, center=(x0 + center[0], OY + center[1], Z),
                         fromPos=(x0 + 1, OY + 1, Z), toPos=(x0 + SIZE - 2, OY + SIZE - 2, Z), free=len(free)))
    return tiles, info


tiles, INFO = build()

if __name__ == '__main__':
    for a in INFO:
        print(a)
