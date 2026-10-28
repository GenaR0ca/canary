# Mubia Online: items nuevos de la Chaos Machine (Jewel of Creation, plumas, paquetes de joyas y Fruits).
#
# Uso: python3 tools/mubia/chaos_machine.py
#   - agrega los items a data/items/appearances.dat con el dibujo de un item de Tibia parecido
#   - agrega los items a data/items/items.xml (después de la Jewel of Chaos)
# Si ya existen, los reemplaza. Las recetas están en data/libs/systems/mubia_chaos.lua.
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from gear import DAT, XML, enc_varint, fields, ld  # noqa: E402

FIRST_ID, LAST_ID = 60305, 60318

# (id, nombre, dibujo de Tibia, se apila, se usa, descripción)
ITEMS = [
    (60305, "Jewel of Creation", 3028, True, False, "Joya de MU. Se usa en la Chaos Machine para crear Fruits y alas de 3ra generacion."),
    (60306, "Loch's Feather", 3254, True, False, "Pluma de MU. Con alas de 1ra generacion y una Jewel of Chaos crea alas de 2da generacion en la Chaos Machine."),
    (60307, "Feather of Condor", 18993, True, False, "Pluma de MU. Junto con la Flame of Condor crea alas de 3ra generacion en la Chaos Machine."),
    (60308, "Flame of Condor", 9636, True, False, "Llama de MU. Junto con la Feather of Condor crea alas de 3ra generacion en la Chaos Machine."),
    (60309, "Bless Bundle x10", 675, False, False, "Paquete de 10 Jewels of Bless. En la Chaos Machine se puede volver a desarmar."),
    (60310, "Bless Bundle x20", 675, False, False, "Paquete de 20 Jewels of Bless. En la Chaos Machine se puede volver a desarmar."),
    (60311, "Bless Bundle x30", 675, False, False, "Paquete de 30 Jewels of Bless. En la Chaos Machine se puede volver a desarmar."),
    (60312, "Soul Bundle x10", 678, False, False, "Paquete de 10 Jewels of Soul. En la Chaos Machine se puede volver a desarmar."),
    (60313, "Soul Bundle x20", 678, False, False, "Paquete de 20 Jewels of Soul. En la Chaos Machine se puede volver a desarmar."),
    (60314, "Soul Bundle x30", 678, False, False, "Paquete de 30 Jewels of Soul. En la Chaos Machine se puede volver a desarmar."),
    (60315, "Fruit of Strength", 3585, True, True, "Fruta de MU. Usala para sumar de 1 a 3 puntos de Strength."),
    (60316, "Fruit of Agility", 3584, True, True, "Fruta de MU. Usala para sumar de 1 a 3 puntos de Agility."),
    (60317, "Fruit of Vitality", 3586, True, True, "Fruta de MU. Usala para sumar de 1 a 3 puntos de Vitality."),
    (60318, "Fruit of Energy", 3588, True, True, "Fruta de MU. Usala para sumar de 1 a 3 puntos de Energy."),
]

# del item base se copia: luz, desplazamiento, altura y animación (lo demás lo decide la tabla de arriba)
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
    for item_id, name, sprite, stackable, usable, _ in ITEMS:
        base = objects[sprite]
        frames = b"".join(x[3] for x in base if x[0] == 2)
        flags = b""
        for x in base:
            if x[0] == 3:
                for ff, fw, fv, fraw in fields(x[2]):
                    if ff in KEEP_FLAGS:
                        flags += fraw
        if stackable:
            flags += enc_varint(6 << 3) + enc_varint(1)
        if usable:
            flags += enc_varint(7 << 3) + enc_varint(1)
        flags += enc_varint(18 << 3) + enc_varint(1)
        new += ld(1, enc_varint(1 << 3) + enc_varint(item_id) + frames + ld(3, flags) + ld(4, name.lower().encode()))

    out = b""
    last_object = max(i for i, (f, _) in enumerate(pieces) if f == 1)
    for i, (f, raw) in enumerate(pieces):
        out += raw
        if i == last_object:
            out += new
    open(DAT, "wb").write(out)
    print(f"appearances.dat: {len(ITEMS)} items de la Chaos Machine ({len(data)} -> {len(out)} bytes)")


BEGIN = "\t<!-- Mubia: items de la Chaos Machine (generado por tools/mubia/chaos_machine.py) -->\n"
END = "\t<!-- Mubia: fin de items de la Chaos Machine -->\n"


def build_xml():
    s = open(XML, encoding="utf-8").read()
    if BEGIN in s:
        s = s[: s.index(BEGIN)] + s[s.index(END) + len(END):]
    lines = [BEGIN]
    for item_id, name, _, _, _, description in ITEMS:
        assert f'id="{item_id}"' not in s, item_id
        article = "" if name.startswith("Bless") or name.startswith("Soul") else ' article="a"'
        lines.append(f'\t<item id="{item_id}"{article} name="{name.lower()}">\n')
        lines.append('\t\t<attribute key="primarytype" value="valuables"/>\n')
        lines.append(f'\t\t<attribute key="description" value="{description}"/>\n')
        lines.append('\t\t<attribute key="weight" value="10"/>\n')
        lines.append("\t</item>\n")
    lines.append(END)
    anchor = s.index('\t<item id="60401"')
    s = s[:anchor] + "".join(lines) + s[anchor:]
    open(XML, "w", encoding="utf-8").write(s)
    print(f"items.xml: {len(ITEMS)} items de la Chaos Machine")


if __name__ == "__main__":
    build_dat()
    build_xml()
