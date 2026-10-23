# Mubia Online: Jewel of Chaos (se usa en la Chaos Machine del Chaos Goblin).
#
# Uso: python3 tools/mubia/chaos.py
#   - agrega la joya a data/items/appearances.dat con el dibujo de la Sage Gem de Tibia
#   - agrega la joya a data/items/items.xml (al lado de las otras joyas)
# Si ya existe, la reemplaza.
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from gear import DAT, XML, enc_varint, fields, ld  # noqa: E402

CHAOS = dict(id=60304, name="Jewel of Chaos", sprite=44609)  # 44609 = sage gem
DESCRIPTION = "Joya de MU. Se usa en la Chaos Machine del Chaos Goblin para combinar items."


def build_dat():
    data = open(DAT, "rb").read()
    base = None
    pieces = []
    for f, w, v, raw in fields(data):
        if f == 1:
            sub = list(fields(v))
            object_id = [x[2] for x in sub if x[0] == 1][0]
            if object_id == CHAOS["id"]:
                continue  # se vuelve a generar
            if object_id == CHAOS["sprite"]:
                base = sub
        pieces.append((f, raw))

    # copia el dibujo y los flags básicos de la Sage Gem: se apila, se levanta, luz, desplazamiento y animación
    frames = b"".join(x[3] for x in base if x[0] == 2)
    flags = b""
    for x in base:
        if x[0] == 3:
            for ff, fw, fv, fraw in fields(x[2]):
                if ff in (6, 18, 23, 26, 27, 29):
                    flags += fraw
    new = ld(1, enc_varint(1 << 3) + enc_varint(CHAOS["id"]) + frames + ld(3, flags) + ld(4, CHAOS["name"].lower().encode()))

    out = b""
    last_object = max(i for i, (f, _) in enumerate(pieces) if f == 1)
    for i, (f, raw) in enumerate(pieces):
        out += raw
        if i == last_object:
            out += new
    open(DAT, "wb").write(out)
    print(f"appearances.dat: {CHAOS['name']} ({len(data)} -> {len(out)} bytes)")


def build_xml():
    s = open(XML, encoding="utf-8").read()
    entry = (
        f'\t<item id="{CHAOS["id"]}" article="a" name="{CHAOS["name"].lower()}">\n'
        '\t\t<attribute key="primarytype" value="valuables"/>\n'
        f'\t\t<attribute key="description" value="{DESCRIPTION}"/>\n'
        '\t\t<attribute key="weight" value="10"/>\n'
        "\t</item>\n"
    )
    start = s.find(f'\t<item id="{CHAOS["id"]}"')
    if start >= 0:
        s = s[:start] + s[s.index("\t</item>\n", start) + len("\t</item>\n"):]
    anchor = s.index('\t<item id="60401"')
    s = s[:anchor] + entry + s[anchor:]
    open(XML, "w", encoding="utf-8").write(s)
    print(f"items.xml: {CHAOS['name']}")


if __name__ == "__main__":
    build_dat()
    build_xml()
