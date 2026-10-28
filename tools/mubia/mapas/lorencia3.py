"""Lorencia v3: decora la ciudad de Lorencia (cuadrado de piedra x905-950, y631-676) según el boceto de Genaro.
Trabaja sobre los tiles actuales del mapa de Genaro: devuelve solo los tiles que cambian.
tiles: dict (x,y,z) -> [flags, [ground, items...], {indice_item: attrs_bytes}]"""
import random, struct

rng = random.Random(1924)
X0, Y0, X1, Y1 = 905, 631, 950, 676  # borde de la ciudad (incluye el borde con agua)
IX0, IY0, IX1, IY1 = 906, 632, 949, 675  # interior
PZ = 1
COBBLE = [17464, 17465, 17466, 17467, 17468]
GRASS = 4515
GRASS_VAR = [4515, 4515, 4515, 4518, 4519, 4520, 4521, 4524, 4526]
WATER = 4597
STONE_FLOOR = 416
STONE_TILE = 429
WOOD = 408
TEMPLE = (927, 654)
TP_STRONGARM = (924, 653)

# bordes: el pasto/agua está del lado indicado (N = el vecino de arriba es pasto/agua)
B_WATER = dict(N=4633, E=4634, S=4635, W=4636, dNW=4641, dNE=4642, dSW=4643, dSE=4644, NW=4637, NE=4638, SW=4639, SE=4640)
B_GRASS = dict(N=4531, E=4532, S=4533, W=4534, dNW=4535, dNE=4536, dSW=4537, dSE=4538, NW=4539, NE=4540, SW=4541, SE=4542)

FRAME = dict(V=1281, H=1282, ES=1283, SW=1284, NW=1285, NE=1286, NSW=1287, NES=1288, NEW=1289, ESW=1290, NESW=1291, door_H=1640, door_V=1638, win_H=6435, win_V=6436)
STONE = dict(V=1294, H=1295, ES=1296, SW=1297, NW=1298, NE=1299, NSW=1300, NES=1301, NEW=1302, ESW=1303, NESW=1304, door_H=6252, door_V=6249, win_H=6445, win_V=6446)

AID_FIXED = b"\x04" + struct.pack("<H", 100)  # action id 100 = no se puede mover


def depot_attr(depot_id):
    return b"\x0a" + struct.pack("<H", depot_id)


class Town:
    def __init__(self, cur):
        """cur: dict (x,y,z) -> lista de ids actuales (ground primero)"""
        self.cur = cur
        self.t = {}
        self.blocked = set()

    def tile(self, x, y, z=7):
        k = (x, y, z)
        if k not in self.t:
            items = list(self.cur.get(k, []))
            flags = PZ if z == 7 else 0
            self.t[k] = [flags, items, {}]
        return self.t[k]

    def ground(self, x, y, gid, z=7, keep_items=False):
        t = self.tile(x, y, z)
        t[1] = [gid] + (t[1][1:] if keep_items else [])
        t[2] = {}

    def add(self, x, y, iid, z=7, attrs=b"", block=True):
        t = self.tile(x, y, z)
        if not t[1]:
            raise ValueError(("sin suelo", x, y, z))
        t[1].append(iid)
        if attrs:
            t[2][len(t[1]) - 1] = attrs
        if block:
            self.blocked.add((x, y))

    def deco(self, x, y, iid, movable=False):
        self.add(x, y, iid, attrs=AID_FIXED if movable else b"")

    # paredes al estilo Tibia según vecinos
    def walls(self, kit, cells, z=7, doors=(), windows=()):
        for (x, y) in cells:
            n = (x, y - 1) in cells
            s = (x, y + 1) in cells
            e = (x + 1, y) in cells
            w = (x - 1, y) in cells
            if (x, y) in doors or (x, y) in windows:
                horiz = e or w
                key = ("door_" if (x, y) in doors else "win_") + ("H" if horiz else "V")
                self.add(x, y, kit[key], z)
                continue
            key = "".join(c for c, f in zip("NESW", (n, e, s, w)) if f)
            piece = {"NS": "V", "N": "V", "S": "V", "EW": "H", "E": "H", "W": "H", "": "ES"}.get(key, key)
            self.add(x, y, kit[piece], z)

    def borders(self, region, is_feature, table, on=None):
        """Pone bordes sobre los tiles de 'region' que no son 'feature' pero tocan uno.
        on: suelos sobre los que se permite poner borde (None = cualquiera)."""
        for (x, y) in region:
            if is_feature(x, y):
                continue
            t = self.tile(x, y)
            if not t[1] or (on is not None and t[1][0] not in on):
                continue
            n, e, s, w = is_feature(x, y - 1), is_feature(x + 1, y), is_feature(x, y + 1), is_feature(x - 1, y)
            if (n and s) or (e and w):
                out = [c for c, f in zip("NESW", (n, e, s, w)) if f]
            elif n and w:
                out = ["NW"]
            elif n and e:
                out = ["NE"]
            elif s and w:
                out = ["SW"]
            elif s and e:
                out = ["SE"]
            else:
                out = [c for c, f in zip("NESW", (n, e, s, w)) if f]
            if not out:
                for c, (dx, dy) in (("dNW", (-1, -1)), ("dNE", (1, -1)), ("dSW", (-1, 1)), ("dSE", (1, 1))):
                    if is_feature(x + dx, y + dy):
                        out.append(c)
            for c in out:
                # el borde va justo encima del suelo, debajo de cualquier otro objeto
                t[1].insert(1, table[c])
                t[2] = {k + 1: v for k, v in t[2].items()}


def rect(x0, y0, x1, y1):
    return [(x, y) for y in range(y0, y1 + 1) for x in range(x0, x1 + 1)]


def ring(x0, y0, x1, y1):
    return set((x, y) for (x, y) in rect(x0, y0, x1, y1) if x in (x0, x1) or y in (y0, y1))


def flat_roof(T, x0, y0, x1, y1, z):
    """techo plano (Thais): paredes x0..x1, y0..y1 -> techo x0..x1+1, y0..y1+1"""
    for y in range(y0, y1 + 2):
        for x in range(x0, x1 + 2):
            if y == y1 + 1:
                gid = 5054 if x == x0 else (5050 if x == x1 + 1 else 5052)
            elif x == x1 + 1:
                gid = 5048 if y == y0 else 5049
            elif y == y0:
                gid = 1155 if x == x0 else 1153
            elif x == x0:
                gid = 1154
            else:
                gid = 1152
            T.ground(x, y, gid, z)


def tiled_roof(T, x0, y0, x1, y1, z):
    """techo de tejas a dos aguas (Thais): paredes x0..x1, y0..y1 -> techo x0..x1+1, y0..y1"""
    ridge = (x0 + x1 + 1) // 2
    for y in range(y0, y1 + 1):
        top = y == y0
        for x in range(x0, x1 + 2):
            if x == x0:
                gid = 1162 if top else 1157
            elif x == x1 + 1:
                gid = 1165 if top else 1160
            elif x == ridge:
                gid = 1166 if top else 1161
            elif x < ridge:
                gid = 1163 if top else 1158
            else:
                gid = 1164 if top else 1159
            T.ground(x, y, gid, z)


def house(T, kit, x0, y0, x1, y1, floor, doors, windows, roof="tiled", floors=1):
    for (x, y) in rect(x0 + 1, y0 + 1, x1 - 1, y1 - 1):
        T.ground(x, y, floor)
    for (x, y) in ring(x0, y0, x1, y1):
        T.ground(x, y, floor)
    cells = ring(x0, y0, x1, y1)
    T.walls(kit, cells, 7, doors=doors, windows=windows)
    T.blocked |= set(rect(x0, y0, x1, y1))
    z = 6
    for _ in range(floors - 1):
        for (x, y) in rect(x0, y0, x1, y1):
            T.ground(x, y, floor, z)
        T.walls(kit, cells, z, windows=set(windows) | set(doors))
        z -= 1
    (tiled_roof if roof == "tiled" else flat_roof)(T, x0, y0, x1, y1, z)


def build(cur):
    T = Town(cur)
    # 1) toda la ciudad zona protegida
    for (x, y) in rect(X0, Y0, X1, Y1):
        if (x, y, 7) in cur:
            T.tile(x, y)

    # 2) templo: llegada sobre las baldosas amarillas
    T.blocked |= set(rect(926, 652, 929, 655)) | {TP_STRONGARM}

    # 3) gran fuente en el centro (agua con borde y fuente de mármol)
    water = set(rect(924, 658, 931, 662)) - {(924, 658), (931, 658), (924, 662), (931, 662)}
    for (x, y) in water:
        T.ground(x, y, WATER)
    fx, fy = 927, 659
    for (dx, dy), iid in zip(((0, 0), (1, 0), (0, 1), (1, 1)), (1936, 1937, 1938, 1939)):
        T.add(fx + dx, fy + dy, iid)
    T.borders(rect(922, 656, 933, 664), lambda x, y: (x, y) in water, B_WATER, on=COBBLE)
    T.blocked |= set(rect(922, 656, 933, 664))
    for (x, y) in ((922, 657), (933, 657), (922, 663), (933, 663)):
        T.deco(x, y, 2109)  # faroles
    for (x, y) in ((925, 656), (930, 656)):
        T.deco(x, y, 2370)  # bancos mirando a la fuente
    for (x, y) in ((925, 664), (930, 664)):
        T.deco(x, y, 2371)
    for (x, y) in ((921, 659), (921, 661)):
        T.deco(x, y, 2372)
    for (x, y) in ((934, 659), (934, 661)):
        T.deco(x, y, 2373)
    for (x, y) in ((921, 660), (934, 660), (923, 656), (932, 656), (923, 664), (932, 664)):
        T.deco(x, y, 3753 if (x + y) % 2 else 3750)  # arbustos con flores

    # 4) esquina superior izquierda: torre de mago (Pasi)
    tw = (908, 634, 913, 639)
    house(T, STONE, *tw, STONE_FLOOR, doors={(910, 639)}, windows={(912, 639), (908, 636), (913, 636)}, roof="tiled", floors=3)
    for x in (909, 911, 912):
        T.deco(x, 635, 2435)  # bibliotecas contra la pared norte
    T.deco(912, 637, 3885)  # caldero de bruja
    T.deco(909, 637, 27665, movable=True)  # mesa de alquimia
    T.deco(909, 638, 27679, movable=True)  # atril
    # explanada mágica delante de la torre
    for (x, y) in rect(907, 641, 914, 645):
        T.ground(x, y, STONE_TILE)
    T.deco(907, 641, 2199)  # obeliscos
    T.deco(914, 641, 2199)
    T.deco(908, 644, 3485, movable=True)  # telescopio (observatorio)
    T.deco(913, 644, 2979, movable=True)  # globo terráqueo
    T.deco(908, 641, 3753)
    T.deco(913, 641, 3753)
    T.deco(915, 643, 27666, movable=True)
    T.deco(916, 643, 27680, movable=True)
    for (x, y), iid in zip(((916, 636), (917, 636), (916, 637), (917, 637)), (2008, 2009, 2010, 2011)):
        T.add(x, y, iid)  # caldero grande
    T.deco(917, 639, 2111)  # brasero
    T.deco(915, 634, 2109)
    for (x, y) in ((906, 633), (906, 638), (906, 643), (915, 638)):
        T.deco(x, y, 3682)  # abetos chicos

    # 5) esquina superior derecha: herrería (Hanzo)
    for (x, y) in rect(939, 634, 948, 642):
        T.ground(x, y, STONE_FLOOR)
    back = set((x, 634) for x in range(940, 949)) | set((948, y) for y in range(634, 641))
    T.walls(FRAME, back)
    T.blocked |= back
    T.deco(941, 635, 2115)  # fragua de piedra
    T.deco(942, 635, 2115)
    T.deco(943, 635, 7821)  # lava caliente
    T.deco(944, 635, 7813)  # crisol
    T.deco(945, 635, 7842)  # fuelle
    T.deco(942, 637, 3458)  # yunques
    T.deco(944, 637, 7843)
    T.deco(946, 635, 6109, movable=True)  # estantes de armas
    T.deco(947, 636, 6110, movable=True)
    T.deco(947, 638, 6112, movable=True)  # estante de armaduras
    T.deco(940, 636, 2519, movable=True)  # barriles
    T.deco(940, 637, 2523, movable=True)
    T.deco(940, 638, 2519, movable=True)
    T.deco(946, 639, 35180, movable=True)  # piedra de afilar
    T.deco(947, 640, 8745)  # cajones
    T.deco(946, 641, 8745)
    T.deco(939, 642, 2113)  # braseros
    T.deco(948, 642, 2113)
    T.deco(939, 634, 2109)
    for y in range(636, 641):
        T.deco(939, y, 2174 if y != 638 else 2172)  # cerca baja (abertura en 939,641)
    T.blocked |= set(rect(939, 634, 948, 642))

    # 6) esquina inferior izquierda: casa, pasto y un depot
    grass = set(rect(906, 662, 916, 663)) | set(rect(906, 671, 913, 675)) | set(rect(914, 672, 917, 675))
    for (x, y) in grass:
        T.ground(x, y, rng.choice(GRASS_VAR))
    house(T, FRAME, 906, 664, 914, 669, WOOD, doors={(910, 669)}, windows={(908, 669), (912, 669), (914, 666)}, roof="tiled")
    T.deco(907, 665, 2519, movable=True)
    T.deco(908, 665, 2523, movable=True)
    T.deco(913, 665, 2435)
    T.deco(912, 667, 2322, movable=True)
    T.deco(907, 668, 8745)
    # depot delante de la casa
    T.ground(910, 670, STONE_TILE)
    T.ground(911, 670, STONE_TILE)
    T.ground(912, 670, STONE_TILE)
    T.add(912, 670, 3499, attrs=depot_attr(9))
    T.deco(913, 670, 2109)
    for (x, y) in ((906, 662), (909, 662), (913, 663), (916, 662), (907, 673), (910, 675), (915, 674), (912, 672)):
        T.deco(x, y, rng.choice([3681, 3747, 3748, 3753, 3750]))
    T.deco(906, 674, 3619)
    T.deco(917, 673, 3617)

    # 7) esquina inferior derecha: dos casitas y un depot
    house(T, FRAME, 943, 659, 948, 664, WOOD, doors={(943, 662)}, windows={(945, 664), (948, 661)}, roof="tiled")
    house(T, STONE, 943, 668, 948, 673, WOOD, doors={(943, 670)}, windows={(945, 668), (948, 671)}, roof="flat")
    T.deco(947, 660, 2435)
    T.deco(944, 663, 2519, movable=True)
    T.deco(947, 669, 2523, movable=True)
    T.deco(946, 672, 2322, movable=True)
    T.ground(944, 666, STONE_TILE)
    T.ground(945, 666, STONE_TILE)
    T.ground(946, 666, STONE_TILE)
    T.add(946, 666, 3499, attrs=depot_attr(9))
    T.deco(947, 666, 2109)
    T.deco(948, 666, 8551, movable=True)
    for (x, y) in ((941, 660), (941, 664), (941, 669), (941, 673), (949, 675)):
        T.deco(x, y, rng.choice([3681, 3747, 3753, 3750]))
    T.deco(942, 675, 3682)
    T.deco(936, 675, 3682)

    # 8) camino sur: franjas de pasto con árboles y faroles
    strips = set(rect(919, 666, 921, 675)) | set(rect(934, 666, 936, 675))
    for (x, y) in strips:
        T.ground(x, y, rng.choice(GRASS_VAR))
    T.borders(rect(906, 660, 938, 675), lambda x, y: (x, y) in strips or (x, y) in grass, B_GRASS, on=COBBLE + [STONE_TILE])
    for (x, y) in ((920, 667), (935, 667), (920, 671), (935, 671), (920, 674), (935, 674)):
        T.deco(x, y, 3614 if y != 671 else 3617)
    for (x, y) in ((919, 669), (936, 669), (921, 673), (934, 673), (919, 672), (936, 672)):
        T.deco(x, y, rng.choice([3753, 3750, 3748, 3747]))
    for (x, y) in ((922, 667), (932, 667), (922, 672), (932, 672)):
        T.deco(x, y, 2109)

    # 9) faroles en la plaza y junto a la taberna
    for (x, y) in ((918, 648), (937, 648), (918, 657), (937, 657), (925, 650), (930, 650)):
        T.deco(x, y, 2109)
    for (x, y) in ((919, 641), (919, 645), (937, 641), (937, 645)):
        T.deco(x, y, rng.choice([3681, 3747, 3753]))
    return T
