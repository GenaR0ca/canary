# Mubia Online: genera el inventario de 40 lugares y las mascotas de MU Online (Season 6).
#
# Uso: python3 tools/mubia/pets.py
#   - agrega los items a data/items/appearances.dat (con el dibujo de un item de Tibia parecido)
#   - agrega los items a data/items/items.xml
# Si los items ya existen, los reemplaza. Lo que hace cada mascota está en data/libs/systems/mubia_pets.lua.
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from gear import DAT, XML, enc_varint, fields, ld  # noqa: E402

FIRST_ID, LAST_ID = 60500, 60599

# El inventario: una bolsa de 40 lugares que va siempre en el slot de la mochila (oculto en el cliente).
BAG = dict(id=60500, name="Inventario", sprite=2854, size=40,
           description="Tu inventario de MU. Se abre con la tecla I.")

# (id, nombre, dibujo de Tibia, qué hace). Lo que hace de verdad está en Mubia.Pets; al mirarla se ve desde ahí.
PETS = [
    (60501, "Guardian Angel", 5799, "Mascota. Absorbe el 20% del daño recibido y da +50 de vida."),
    (60502, "Imp", 5894, "Mascota. Aumenta el daño un 30%."),
    (60503, "Horn of Uniria", 2957, "Montura. Aumenta la velocidad al caminar."),
    (60504, "Horn of Dinorant", 2958, "Montura. Aumenta el daño un 15%, absorbe el 10% del daño recibido y aumenta la velocidad."),
    (60505, "Horn of Fenrir", 5897, "Montura. Aumenta el daño un 10%, absorbe el 10% del daño recibido y aumenta mucho la velocidad."),
    (60506, "Demon", 5954, "Mascota. Aumenta el daño un 40% y la velocidad de ataque un 10%."),
    (60507, "Spirit of Guardian", 8146, "Mascota. Absorbe el 30% del daño recibido y da +50 de vida."),
    (60508, "Pet Skeleton", 3114, "Mascota. Aumenta el daño un 20% y la velocidad de ataque un 10%."),
    (60509, "Pet Panda", 5080, "Mascota. Da un 50% más de experiencia."),
]

# Flags del item de Tibia que se copian a las mascotas: take, light, shift, height y animate_always
PET_FLAGS = {18, 23, 26, 27, 29}


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

    def make(item_id, name, sprite, keep):
        base = objects[sprite]
        frames = b"".join(x[3] for x in base if x[0] == 2)
        flags = b""
        for x in base:
            if x[0] == 3:
                for ff, fw, fv, fraw in fields(x[2]):
                    if keep is None or ff in keep:
                        flags += fraw
        if 18 not in [ff for ff, *_ in fields(flags)]:
            flags += enc_varint(18 << 3) + enc_varint(1)
        return ld(1, enc_varint(1 << 3) + enc_varint(item_id) + frames + ld(3, flags) + ld(4, name.lower().encode()))

    # la bolsa copia todos los flags de la mochila (contenedor y slot de mochila)
    new = make(BAG["id"], BAG["name"], BAG["sprite"], None)
    for item_id, name, sprite, _ in PETS:
        new += make(item_id, name, sprite, PET_FLAGS)

    out = b""
    last_object = max(i for i, (f, _) in enumerate(pieces) if f == 1)
    for i, (f, raw) in enumerate(pieces):
        out += raw
        if i == last_object:
            out += new
    open(DAT, "wb").write(out)
    print(f"appearances.dat: inventario y {len(PETS)} mascotas ({len(data)} -> {len(out)} bytes)")


BEGIN = "\t<!-- Mubia: inventario y mascotas (generado por tools/mubia/pets.py) -->\n"
END = "\t<!-- Mubia: fin de inventario y mascotas -->\n"


def build_xml():
    s = open(XML, encoding="utf-8").read()
    if BEGIN in s:
        s = s[: s.index(BEGIN)] + s[s.index(END) + len(END):]
    lines = [BEGIN]
    lines.append(f'\t<item id="{BAG["id"]}" name="{BAG["name"].lower()}">\n')
    lines.append('\t\t<attribute key="primarytype" value="containers"/>\n')
    lines.append(f'\t\t<attribute key="containersize" value="{BAG["size"]}"/>\n')
    lines.append(f'\t\t<attribute key="description" value="{BAG["description"]}"/>\n')
    lines.append('\t\t<attribute key="weight" value="0"/>\n')
    lines.append("\t</item>\n")
    for item_id, name, _, _ in PETS:
        assert f'id="{item_id}"' not in s, item_id
        lines.append(f'\t<item id="{item_id}" name="{name.lower()}">\n')
        lines.append('\t\t<attribute key="slottype" value="pet"/>\n')
        lines.append('\t\t<attribute key="weight" value="100"/>\n')
        lines.append("\t</item>\n")
    lines.append(END)
    i = s.rindex("</items>")
    s = s[:i] + "".join(lines) + s[i:]
    open(XML, "w", encoding="utf-8").write(s)
    print(f"items.xml: inventario y {len(PETS)} mascotas")


if __name__ == "__main__":
    build_dat()
    build_xml()
