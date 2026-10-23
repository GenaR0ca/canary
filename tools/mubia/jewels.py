# Mubia Online: Jewel of Harmony, Jewel of Luck y Jewel of Excellent (se usan sobre un item con "Usar con...").
#
# Uso: python3 tools/mubia/jewels.py
#   - agrega las joyas a data/items/appearances.dat con el dibujo de una gema de Tibia
#   - agrega las joyas a data/items/items.xml (antes de las alas)
# Si ya existen, las reemplaza. Lo que hace cada joya está en data/libs/systems/mubia_excellent.lua.
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from gear import DAT, XML, enc_varint, fields, ld  # noqa: E402

FIRST_ID, LAST_ID = 60319, 60321

# (id, nombre, dibujo de Tibia, descripción)
JEWELS = [
    (60319, "Jewel of Harmony", 32769, "Usala sobre un set, arma o escudo (Usar con...) para darle una opcion Harmony. Si ya tiene, la sube de nivel (hasta el nivel del item). Puede fallar."),
    (60320, "Jewel of Luck", 3038, "Usala sobre un item de MU (Usar con...) para darle Luck."),
    (60321, "Jewel of Excellent", 3037, "Usala sobre un item Excellent (Usar con...) para sumarle una opcion Excellent nueva."),
]

# del item base se copia: luz, desplazamiento, altura y animación. Se apila (6), "usar con" (9) y se levanta (18).
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
    for item_id, name, sprite, _ in JEWELS:
        base = objects[sprite]
        frames = b"".join(x[3] for x in base if x[0] == 2)
        flags = b""
        for x in base:
            if x[0] == 3:
                for ff, fw, fv, fraw in fields(x[2]):
                    if ff in KEEP_FLAGS:
                        flags += fraw
        for flag in (6, 9, 18):
            flags += enc_varint(flag << 3) + enc_varint(1)
        new += ld(1, enc_varint(1 << 3) + enc_varint(item_id) + frames + ld(3, flags) + ld(4, name.lower().encode()))

    out = b""
    last_object = max(i for i, (f, _) in enumerate(pieces) if f == 1)
    for i, (f, raw) in enumerate(pieces):
        out += raw
        if i == last_object:
            out += new
    open(DAT, "wb").write(out)
    print(f"appearances.dat: {len(JEWELS)} joyas ({len(data)} -> {len(out)} bytes)")


BEGIN = "\t<!-- Mubia: Jewel of Harmony, Luck y Excellent (generado por tools/mubia/jewels.py) -->\n"
END = "\t<!-- Mubia: fin de Jewel of Harmony, Luck y Excellent -->\n"


def build_xml():
    s = open(XML, encoding="utf-8").read()
    if BEGIN in s:
        s = s[: s.index(BEGIN)] + s[s.index(END) + len(END):]
    lines = [BEGIN]
    for item_id, name, _, description in JEWELS:
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
    print(f"items.xml: {len(JEWELS)} joyas")


if __name__ == "__main__":
    build_dat()
    build_xml()
