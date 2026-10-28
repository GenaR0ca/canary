# Mubia Online: Scroll of Archangel, Blood Bone y Cloak of Invisibility (+1 a +8) para entrar a Blood Castle,
# y las 3 armas del Archangel que se rescatan dentro del castillo.
#
# Uso: python3 tools/mubia/blood_castle_items.py
#   - agrega los items a data/items/appearances.dat con el dibujo de un item de Tibia
#   - agrega los items a data/items/items.xml (antes de las alas)
# Si ya existen, los reemplaza. Lo que hace cada uno está en data/libs/systems/mubia_blood_castle.lua.
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from gear import DAT, XML, enc_varint, fields, ld  # noqa: E402

FIRST_ID, LAST_ID = 60631, 60663

# (primer id, nombre, dibujo de Tibia, descripción)
KINDS = [
    (60631, "Scroll of Archangel", 2815, "Pergamino del Archangel. Con la Blood Bone del mismo nivel y una Jewel of Chaos se arma una Cloak of Invisibility."),
    (60641, "Blood Bone", 3115, "Hueso de sangre. Con el Scroll of Archangel del mismo nivel y una Jewel of Chaos se arma una Cloak of Invisibility."),
    (60651, "Cloak of Invisibility", 3565, "Entrada a Blood Castle del mismo nivel. Llevala al Messenger of Archangel."),
]
LEVELS = 8

ITEMS = []
for first, name, sprite, description in KINDS:
    for level in range(1, LEVELS + 1):
        ITEMS.append((first + level - 1, f"{name} +{level}", sprite, description))

# armas del Archangel: salen de la Statue of Saint y se le devuelven al Archangel (no se pueden equipar)
WEAPON_DESCRIPTION = "Arma sagrada robada al Archangel. Llevasela al Archangel en la entrada del Blood Castle antes de que termine el tiempo."
ITEMS += [
    (60661, "Divine Sword of Archangel", 3288, WEAPON_DESCRIPTION),
    (60662, "Divine Staff of Archangel", 3071, WEAPON_DESCRIPTION),
    (60663, "Divine Crossbow of Archangel", 3349, WEAPON_DESCRIPTION),
]

# del item base se copia: luz, desplazamiento, altura y animación. Se apila (6, menos las armas) y se levanta (18).
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
        for flag in ((18,) if item_id >= 60661 else (6, 18)):
            flags += enc_varint(flag << 3) + enc_varint(1)
        new += ld(1, enc_varint(1 << 3) + enc_varint(item_id) + frames + ld(3, flags) + ld(4, name.lower().encode()))

    out = b""
    last_object = max(i for i, (f, _) in enumerate(pieces) if f == 1)
    for i, (f, raw) in enumerate(pieces):
        out += raw
        if i == last_object:
            out += new
    open(DAT, "wb").write(out)
    print(f"appearances.dat: {len(ITEMS)} items de Blood Castle ({len(data)} -> {len(out)} bytes)")


BEGIN = "\t<!-- Mubia: Blood Castle, Scroll of Archangel, Blood Bone, Cloak of Invisibility y armas del Archangel (generado por tools/mubia/blood_castle_items.py) -->\n"
END = "\t<!-- Mubia: fin de Blood Castle -->\n"


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
    print(f"items.xml: {len(ITEMS)} items de Blood Castle")


if __name__ == "__main__":
    build_dat()
    build_xml()
