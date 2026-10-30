"""Mubia: agrega la Sala del GOD (11x11, z=7, esquina NW 3095,3095) a canary.otbm.

Uso:
    python godzone.py --check [mapa.otbm] [--base original.otbm]  # verifica (mapa con o sin sala); no escribe
    python godzone.py --apply [mapa.otbm]   # escribe la sala; solo sobre un mapa sin ella (haz copia antes)
"""
import shutil
import struct
import sys

DEFAULT_MAP = r"C:\Mubia\canary\data-canary\world\canary.otbm"

X0, Y0, Z, SIZE = 3095, 3095, 7, 11
FLOOR, CENTER = 454, 596  # wooden floor / strange carving (como el centro del templo)
WALL_H, WALL_V, WALL_C = 1294, 1295, 1296  # stone wall (items.xml 1294..1304)

TILE_AREA, TILE, ITEM = 4, 5, 6
ATTR_FLAGS, ATTR_ITEM = 3, 9
TILESTATE_PROTECTIONZONE = 1


def parse(d):
    pos = 4

    def node():
        nonlocal pos
        assert d[pos] == 0xFE
        t = d[pos + 1]
        pos += 2
        props, kids = bytearray(), []
        while True:
            b = d[pos]
            if b == 0xFE:
                kids.append(node())
            elif b == 0xFF:
                pos += 1
                return [t, bytes(props), kids]
            elif b == 0xFD:
                props.append(d[pos + 1])
                pos += 2
            else:
                props.append(b)
                pos += 1

    return node()


def serialize(tree):
    out = bytearray(d_header(tree))

    def esc(b):
        o = bytearray()
        for x in b:
            if x in (0xFD, 0xFE, 0xFF):
                o.append(0xFD)
            o.append(x)
        return o

    def w(n):
        out.append(0xFE)
        out.append(n[0])
        out.extend(esc(n[1]))
        for c in n[2]:
            w(c)
        out.append(0xFF)

    w(tree)
    return bytes(out)


def d_header(_tree):
    return b"\0\0\0\0"


def build_area():
    kids = []
    for dy in range(SIZE):
        for dx in range(SIZE):
            props = bytes([dx, dy, ATTR_FLAGS]) + struct.pack("<I", TILESTATE_PROTECTIONZONE)
            ground = CENTER if (dx, dy) == (SIZE // 2, SIZE // 2) else FLOOR
            props += bytes([ATTR_ITEM]) + struct.pack("<H", ground)
            tile_kids = []
            edge_x, edge_y = dx in (0, SIZE - 1), dy in (0, SIZE - 1)
            if edge_x or edge_y:
                wall = WALL_C if (edge_x and edge_y) else (WALL_V if edge_x else WALL_H)
                tile_kids.append([ITEM, struct.pack("<H", wall), []])
            kids.append([TILE, props, tile_kids])
    return [TILE_AREA, struct.pack("<HHB", X0, Y0, Z), kids]


def tiles(data_node):
    """(x,y,z) -> (props, tuple(hijos)) de todos los tiles del mapa."""
    out = {}
    for a in data_node[2]:
        if a[0] != TILE_AREA:
            continue
        ax, ay, az = struct.unpack("<HHB", a[1][:5])
        for t in a[2]:
            if t[0] in (5, 14):
                out[(ax + t[1][0], ay + t[1][1], az)] = (t[1], tuple((k[0], k[1]) for k in t[2]))
    return out


def apply(tree):
    data = tree[2][0]
    last = max(i for i, c in enumerate(data[2]) if c[0] == TILE_AREA)
    data[2].insert(last + 1, build_area())


def region_keys():
    return [(X0 + dx, Y0 + dy, Z) for dy in range(SIZE) for dx in range(SIZE)]


def verify_existing(tree, base_path):
    """Verifica un mapa que YA tiene la sala: 121 tiles exactos y, con --base, nada mas cambio."""
    after = tiles(tree[2][0])
    expected = tiles([0, b"", [build_area()]])
    for k in region_keys():
        assert k in after, f"falta el tile {k}"
        assert after[k] == expected[k], f"el tile {k} no coincide con lo esperado"
    print(f"OK la sala existe: {len(expected)} tiles exactos (PZ, suelo, paredes)")
    if base_path:
        base_raw = open(base_path, "rb").read()
        room = struct.pack("<HHB", X0, Y0, Z)
        data = tree[2][0]
        areas = [c for c in data[2] if c[0] == TILE_AREA and c[1] == room]
        assert len(areas) == 1, "debe haber exactamente un area de la sala"
        data[2] = [c for c in data[2] if c is not areas[0]]
        assert serialize(tree) == base_raw, "quitando la sala, el mapa NO es byte-identico al base"
        print(f"OK quitando la sala, el mapa es byte-identico al base ({len(base_raw)} bytes)")


def main():
    argv = sys.argv[1:]
    base_path = None
    if "--base" in argv:
        i = argv.index("--base")
        base_path = argv[i + 1]
        del argv[i : i + 2]
    args = [a for a in argv if not a.startswith("--")]
    path = args[0] if args else DEFAULT_MAP
    mode = "--apply" if "--apply" in argv else "--check"
    raw = open(path, "rb").read()
    tree = parse(raw)
    assert serialize(tree) == raw, "round-trip del mapa no es identico"
    print("OK round-trip")
    before = tiles(tree[2][0])
    occupied = any((X0 + dx, Y0 + dy, z) in before for dx in range(-2, SIZE + 2) for dy in range(-2, SIZE + 2) for z in range(16))
    if occupied:
        assert mode == "--check", "la region ya tiene tiles: --apply solo funciona sobre un mapa sin la sala"
        verify_existing(tree, base_path)
        return
    print("OK region libre (todos los pisos, con margen de 2)")
    apply(tree)
    new = serialize(tree)
    tree2 = parse(new)
    assert serialize(tree2) == new
    after = tiles(tree2[2][0])
    assert len(after) == len(before) + SIZE * SIZE
    assert all(after[k] == before[k] for k in before), "se altero un tile existente"
    verify_existing(tree2, None)
    if mode == "--apply":
        tmp = path + ".tmp"
        open(tmp, "wb").write(new)
        shutil.move(tmp, path)
        print("Mapa escrito:", path, f"({len(raw)} -> {len(new)} bytes)")


if __name__ == "__main__":
    main()
