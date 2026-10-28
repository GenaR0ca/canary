"""Mubia Online: los 8 castillos de Blood Castle (estilo Tibia, con el recorrido de MU).

Cada castillo, de sur a norte:
  - Zona de llegada (zona protegida): el Archangel espera ahí el arma.
  - Puente sobre el foso: cerrado con rejas hasta que empieza el evento.
  - Patio: salen los monstruos (hay que matar una cantidad para que aparezca la puerta).
  - Muralla con la puerta del castillo (3 casillas con rejas; la Castle Gate se rompe a golpes).
  - Salón del santo: salen los Magic Skeleton y, al final, la Statue of Saint en el altar.
Lo que pasa en cada parte está en data/libs/systems/mubia_blood_castle.lua.
Región vacía x2306-2605, y650-718, z7 (al sur de Devil Square). Uso: ver build_blood_castle.py.
"""
import random

Z = 7
OX, OY = 2306, 650
W, H = 31, 67       # un castillo, con muralla
STEP = 37           # distancia entre castillos (quedan 6 casillas de montaña en el medio)
LEVELS = 8
TOTAL_W = STEP * (LEVELS - 1) + W + 6
TOTAL_H = H + 4

# ---------- piezas ----------
MOUNTAIN = 1128
STONE_WALL = dict(H=1295, V=1294, CORNER=1298, POLE=1296)
BARS = dict(H=2185, V=2184)
YARD = [7355] * 6 + [499, 500, 501, 502, 503, 504]      # piedra gris del patio
HALL = 429                                               # mármol claro del salón del santo
CARPET = 2576                                            # alfombra roja hacia el altar
ARRIVAL = 8757                                           # piedra clara de la llegada
WATER = 4597
BRIDGE = 878
B_WATER = dict(N=4633, E=4634, S=4635, W=4636, NW=4641, NE=4642, SE=4644, SW=4643, iNW=4637, iNE=4638, iSE=4640, iSW=4639)
BASIN = 2110        # brasero encendido
GARGOYLE = 2035
ANGEL = 2031        # estatua de ángel (zona de llegada)
PILLAR = 2152
BONES = [3114, 6394]

# filas (y local) de cada parte
HALL_Y = (1, 14)
GATE_WALL_Y = 15
YARD_Y = (16, 44)
YARD_WALL_Y = 45
MOAT_Y = (46, 51)
ARRIVAL_Y = (52, 65)
GATE_X = (14, 16)          # puerta del castillo (3 casillas)
BRIDGE_X = (13, 17)        # puente (5 casillas)

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


def wall_piece(cells, x, y):
    n = (x, y - 1) in cells
    s = (x, y + 1) in cells
    e = (x + 1, y) in cells
    w = (x - 1, y) in cells
    if e and s:
        return STONE_WALL["CORNER"]
    if (n or s) and (e or w):
        return STONE_WALL["POLE"]
    if n or s:
        return STONE_WALL["V"]
    return STONE_WALL["H"]


def castle(level, rng):
    """Devuelve tiles locales {(x, y): (flags, [ids])} y los puntos importantes del castillo."""
    ground = {}
    for y in range(H):
        for x in range(W):
            if HALL_Y[0] <= y <= HALL_Y[1]:
                ground[(x, y)] = "hall"
            elif YARD_Y[0] <= y <= YARD_Y[1]:
                ground[(x, y)] = "yard"
            elif MOAT_Y[0] <= y <= MOAT_Y[1]:
                ground[(x, y)] = "bridge" if BRIDGE_X[0] <= x <= BRIDGE_X[1] else "water"
            else:
                ground[(x, y)] = "arrival"

    walls = set()
    for x in range(W):
        walls.update({(x, 0), (x, H - 1), (x, GATE_WALL_Y)})
        if not BRIDGE_X[0] <= x <= BRIDGE_X[1]:
            walls.add((x, YARD_WALL_Y))
    for y in range(H):
        if not MOAT_Y[0] <= y <= MOAT_Y[1]:
            walls.update({(0, y), (W - 1, y)})
    gate = {(x, GATE_WALL_Y) for x in range(GATE_X[0], GATE_X[1] + 1)}
    walls -= gate
    # el foso llega hasta el borde: a los costados del foso no hay muralla, hay agua
    for (x, y) in list(walls):
        if ground[(x, y)] == "water":
            walls.discard((x, y))

    items, blocked = {}, set(walls) | gate

    def add(x, y, iid, block=True):
        items.setdefault((x, y), []).append(iid)
        if block:
            blocked.add((x, y))

    for (x, y) in walls:
        add(x, y, wall_piece(walls | gate, x, y))
    for (x, y) in gate:
        add(x, y, BARS["H"])
    # rejas del puente: se sacan cuando empieza el evento
    barrier = [(x, MOAT_Y[0]) for x in range(BRIDGE_X[0], BRIDGE_X[1] + 1)]
    for (x, y) in barrier:
        add(x, y, BARS["H"])

    # ---- salón del santo ----
    cx = W // 2
    altar = (cx, 3)
    for y in range(altar[1] + 1, GATE_WALL_Y):
        if ground[(cx, y)] == "hall":
            ground[(cx, y)] = "carpet"
    for (x, y) in ((cx - 2, 2), (cx + 2, 2)):
        add(x, y, BASIN)
    for (x, y) in ((5, 4), (W - 6, 4), (5, 10), (W - 6, 10)):
        add(x, y, PILLAR)
    for (x, y) in ((2, 2), (W - 3, 2), (2, HALL_Y[1] - 1), (W - 3, HALL_Y[1] - 1)):
        add(x, y, BASIN)
    # estatuas a los costados de la puerta, mirando al salón
    add(GATE_X[0] - 2, GATE_WALL_Y - 1, GARGOYLE)
    add(GATE_X[1] + 2, GATE_WALL_Y - 1, GARGOYLE)

    # ---- patio ----
    for (x, y) in ((GATE_X[0] - 2, GATE_WALL_Y + 1), (GATE_X[1] + 2, GATE_WALL_Y + 1)):
        add(x, y, BASIN)
    for y in range(YARD_Y[0] + 5, YARD_Y[1] - 2, 7):
        for x in (6, W - 7):
            add(x, y, PILLAR)
    for y in range(YARD_Y[0] + 2, YARD_Y[1], 6):
        add(1, y, BASIN)
        add(W - 2, y, BASIN)
    # restos de batallas
    for y in range(YARD_Y[0], YARD_Y[1] + 1):
        for x in range(1, W - 1):
            if (x, y) not in blocked and abs(x - cx) > 2 and rng.random() < 0.025:
                add(x, y, rng.choice(BONES), block=False)

    # ---- llegada ----
    archangel = (cx, ARRIVAL_Y[0] + 3)
    for (x, y) in ((cx - 2, archangel[1] - 1), (cx + 2, archangel[1] - 1)):
        add(x, y, ANGEL)
    for (x, y) in ((2, ARRIVAL_Y[0] + 1), (W - 3, ARRIVAL_Y[0] + 1), (2, ARRIVAL_Y[1] - 1), (W - 3, ARRIVAL_Y[1] - 1)):
        add(x, y, BASIN)
    arrive = (cx, ARRIVAL_Y[1] - 3)

    # ---- armar ----
    def g(x, y):
        return ground.get((x, y), "outside")

    PROTECTION, NOLOGOUT = 1, 8
    tiles = {}
    for y in range(H):
        for x in range(W):
            t = ground[(x, y)]
            if t == "hall":
                gid = HALL
            elif t == "carpet":
                gid = CARPET
            elif t == "yard":
                gid = rng.choice(YARD)
            elif t == "water":
                gid = WATER
            elif t == "bridge":
                gid = BRIDGE
            else:
                gid = ARRIVAL
            stack = [gid]
            if t in ("yard", "arrival") and (x, y) not in walls:
                for p in border_pieces(x, y, lambda a, b: g(a, b) == "water"):
                    stack.append(B_WATER[p])
            stack += items.get((x, y), [])
            inside = 0 < x < W - 1 and 0 < y < H - 1
            flags = 0
            if inside:
                flags = NOLOGOUT
                if t == "arrival" and (x, y) not in walls:
                    flags |= PROTECTION
            tiles[(x, y)] = (flags, stack)

    def free(y0, y1):
        return [(x, y) for y in range(y0, y1 + 1) for x in range(1, W - 1)
                if (x, y) not in blocked and ground[(x, y)] in ("hall", "carpet", "yard")]

    pois = dict(
        arrive=arrive, archangel=archangel, altar=altar,
        gate=sorted(gate), gate_monster=(cx, GATE_WALL_Y), barrier=barrier,
        hall=((1, HALL_Y[0]), (W - 2, HALL_Y[1])), yard=((1, YARD_Y[0]), (W - 2, YARD_Y[1])),
        free_yard=len(free(*YARD_Y)), free_hall=len(free(*HALL_Y)),
    )
    return tiles, pois


def build():
    rng = random.Random(1551)
    tiles = {}
    info = []
    # montaña alrededor de todo y entre los castillos
    for y in range(TOTAL_H):
        for x in range(TOTAL_W):
            tiles[(OX + x - 3, OY + y - 2, Z)] = (0, [MOUNTAIN])
    for level in range(1, LEVELS + 1):
        x0 = OX + (level - 1) * STEP
        local, pois = castle(level, rng)
        for (x, y), tile in local.items():
            tiles[(x0 + x, OY + y, Z)] = tile

        def G(p):
            return (x0 + p[0], OY + p[1], Z)

        info.append(dict(level=level, x0=x0, fromPos=G((1, 1)), toPos=G((W - 2, H - 2)),
                         arrive=G(pois["arrive"]), archangel=G(pois["archangel"]), altar=G(pois["altar"]),
                         gate=[G(p) for p in pois["gate"]], gateMonster=G(pois["gate_monster"]),
                         barrier=[G(p) for p in pois["barrier"]],
                         hall=(G(pois["hall"][0]), G(pois["hall"][1])), yard=(G(pois["yard"][0]), G(pois["yard"][1])),
                         free_yard=pois["free_yard"], free_hall=pois["free_hall"]))
    return tiles, info


tiles, INFO = build()

if __name__ == "__main__":
    for a in INFO:
        print(a)
    xs = [p[0] for p in tiles]
    ys = [p[1] for p in tiles]
    print("region", min(xs), max(xs), min(ys), max(ys))
