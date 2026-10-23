# Mubia Online: Devil's Eye, Devil's Key y Devil's Invitation (+1 a +7) para entrar a Devil Square.
#
# Uso: python3 tools/mubia/devil_square_items.py
#   - agrega los items a data/items/appearances.dat con el dibujo de un item de Tibia
#   - agrega los items a data/items/items.xml (antes de las alas)
# Si ya existen, los reemplaza. Lo que hace cada uno está en data/libs/systems/mubia_devil_square.lua.
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from gear import DAT, XML, enc_varint, fields, ld  # noqa: E402

FIRST_ID, LAST_ID = 60601, 60627

# (primer id, nombre, dibujo de Tibia, descripción)
KINDS = [
    (60601, "Devil's Eye", 10280, "Ojo del demonio. Con la Devil's Key del mismo nivel y una Jewel of Chaos se arma una Devil's Invitation."),
    (60611, "Devil's Key", 2972, "Llave del demonio. Con el Devil's Eye del mismo nivel y una Jewel of Chaos se arma una Devil's Invitation."),
    (60621, "Devil's Invitation", 7933, "Entrada a Devil Square del mismo nivel. Llevala a Charon."),
]
LEVELS = 7

ITEMS = []
for first, name, sprite, description in KINDS:
    for level in range(1, LEVELS + 1):
        ITEMS.append((first + level - 1, f"{name} +{level}", sprite, description))

# del item base se copia: luz, desplazamiento, altura y animación. Se apila (6) y se levanta (18).
KEEP_FLAGS = {23, 26, 27, 29}


def build_dat():
    data = open(DAT, "rb").read()
    objects = {}
    pieces = []
    for f, w, v, raw in fields(data):
        if f == 1:
            sub = list(fields(v))
            object_id = [x[2] for x in sub if x[0] == 1][0]
            if FIRST_ID <= object_id <= LAST_ID:
                continue  # se vuelve a generar
            objects[object_id] = sub
        pieces.append((f, raw))

    new = b""
    for item_id, name, sprite, _ in ITEMS:
        base = objects[sprite]
        frames = b"".join(x[3] for x in base if x[0] == 2)
        flags = b""
        for x in base:
            if x[0] == 3:
                for ff, fw, fv, fraw in fields(x[2]):
                    if ff in KEEP_FLAGS:
                        flags += fraw
        for flag in (6, 18):
            flags += enc_varint(flag << 3) + enc_varint(1)
        new += ld(1, enc_varint(1 << 3) + enc_varint(item_id) + frames + ld(3, flags) + ld(4, name.lower().encode()))

    out = b""
    last_object = max(i for i, (f, _) in enumerate(pieces) if f == 1)
    for i, (f, raw) in enumerate(pieces):
        out += raw
        if i == last_object:
            out += new
    open(DAT, "wb").write(out)
    print(f"appearances.dat: {len(ITEMS)} items de Devil Square ({len(data)} -> {len(out)} bytes)")


BEGIN = "\t<!-- Mubia: Devil Square, Devil's Eye, Key e Invitation (generado por tools/mubia/devil_square_items.py) -->\n"
END = "\t<!-- Mubia: fin de Devil Square -->\n"


def build_xml():
    s = open(XML, encoding="utf-8").read()
    if BEGIN in s:
        s = s[: s.index(BEGIN)] + s[s.index(END) + len(END):]
    lines = [BEGIN]
    for item_id, name, _, description in ITEMS:
        assert f'id="{item_id}"' not in s, item_id
        lines.append(f'\t<item id="{item_id}" article="a" name="{name.lower()}">\n')
        lines.append('\t\t<attribute key="primarytype" value="valuables"/>\n')
        lines.append(f'\t\t<attribute key="description" value="{description}"/>\n')
        lines.append('\t\t<attribute key="weight" value="10"/>\n')
        lines.append("\t</item>\n")
    lines.append(END)
    anchor = s.index('\t<item id="60401"')
    s = s[:anchor] + "".join(lines) + s[anchor:]
    open(XML, "w", encoding="utf-8").write(s)
    print(f"items.xml: {len(ITEMS)} items de Devil Square")


if __name__ == "__main__":
    build_dat()
    build_xml()
