"""Mubia Online: items de las tiendas de NPC de MU (hilo de NPCs, 2026-10-25).

Agrega a appearances.dat los items nuevos (copiando el dibujo de un item de Tibia) y cambia
el nombre de algunos de Tibia (pociones, antídoto, flechas). Escribe también el bloque para items.xml.

Uso: python3 npc_items.py <appearances.dat entrada> <appearances.dat salida> <items.xml entrada> <items.xml salida> [--sin-municion]
"""
import re
import sys

sys.path.insert(0, "/tmp/claude-0/gen")
import appearances_pb2 as A  # generado con protoc desde src/protobuf/appearances.proto

# id nuevo: (nombre, item de Tibia del que se copia el dibujo, tipo)
NEW_ITEMS = {
    60701: ("ale", 32072, "drink"),
    60702: ("olive of love", 24948, "drink"),
    62068: ("berdysh", 3269, "twohand"),
    62069: ("salamander sword", 3271, "hand"),
    63015: ("spiked shield", 17810, "shield"),
    63016: ("round shield", 3412, "shield"),
}

# items de Tibia que pasan a llamarse como en MU
RENAMES = {
    266: "small healing potion",
    236: "healing potion",
    239: "large healing potion",
    268: "small mana potion",
    237: "mana potion",
    238: "large mana potion",
    7644: "antidote",
    3447: "arrow +3",
    3446: "bolt +3",
}

DESCRIPTIONS = {
    60701: "Vino de Lorencia. Aumenta en 10 la velocidad de ataque y de magia por 80 segundos.",
    60702: "Aumenta en 10 la velocidad de ataque y de magia por 3 minutos.",
    7644: "Quita todos los efectos negativos (veneno, fuego, parálisis...).",
}

XML_NEW = {
    60701: '\t<item id="60701" article="an" name="ale">\n\t\t<attribute key="primarytype" value="food"/>\n\t\t<attribute key="description" value="{d}"/>\n\t\t<attribute key="weight" value="200"/>\n\t</item>\n',
    60702: '\t<item id="60702" article="an" name="olive of love">\n\t\t<attribute key="primarytype" value="food"/>\n\t\t<attribute key="description" value="{d}"/>\n\t\t<attribute key="weight" value="200"/>\n\t</item>\n',
    62068: '\t<item id="62068" name="berdysh">\n\t\t<attribute key="primarytype" value="axe weapons"/>\n\t\t<attribute key="weaponType" value="axe"/>\n\t\t<attribute key="slotType" value="two-handed"/>\n\t\t<attribute key="attack" value="54"/>\n\t\t<attribute key="weight" value="3000"/>\n\t\t<attribute key="script" value="weapon">\n\t\t\t<attribute key="weaponType" value="axe"/>\n\t\t</attribute>\n\t</item>\n',
    62069: '\t<item id="62069" name="salamander sword">\n\t\t<attribute key="primarytype" value="sword weapons"/>\n\t\t<attribute key="weaponType" value="sword"/>\n\t\t<attribute key="attack" value="46"/>\n\t\t<attribute key="weight" value="3000"/>\n\t\t<attribute key="script" value="weapon">\n\t\t\t<attribute key="weaponType" value="sword"/>\n\t\t</attribute>\n\t</item>\n',
    63015: '\t<item id="63015" name="spiked shield">\n\t\t<attribute key="primarytype" value="shields"/>\n\t\t<attribute key="weaponType" value="shield"/>\n\t\t<attribute key="weight" value="2000"/>\n\t</item>\n',
    63016: '\t<item id="63016" name="round shield">\n\t\t<attribute key="primarytype" value="shields"/>\n\t\t<attribute key="weaponType" value="shield"/>\n\t\t<attribute key="weight" value="2000"/>\n\t</item>\n',
}


# arcos (62038-62046) y ballestas (62047-62054) de MU: qué munición gastan
AMMO_WEAPONS = {item_id: "arrow" for item_id in range(62038, 62047)}
AMMO_WEAPONS.update({item_id: "bolt" for item_id in range(62047, 62055)})


def build_dat(src, dst):
    data = A.Appearances()
    data.ParseFromString(open(src, "rb").read())
    by_id = {o.id: o for o in data.object}
    for item_id, name in RENAMES.items():
        by_id[item_id].name = name.encode()
    for item_id, (name, base, kind) in NEW_ITEMS.items():
        if item_id in by_id:
            obj = by_id[item_id]
            obj.Clear()
        else:
            obj = data.object.add()
        obj.id = item_id
        obj.name = name.encode()
        obj.frame_group.extend(by_id[base].frame_group)
        obj.flags.take = True
        if kind == "drink":
            obj.flags.cumulative = True
            obj.flags.usable = True
        elif kind == "shield":
            obj.flags.clothes.slot = 5
        elif kind == "twohand":
            obj.flags.clothes.slot = 0
        elif kind == "hand":
            obj.flags.clothes.slot = 6
    open(dst, "wb").write(data.SerializeToString())


def build_xml(src, dst, ammo=True):
    xml = open(src, encoding="utf-8").read()
    for item_id, name in RENAMES.items():
        xml, count = re.subn(r'(<item id="%d"(?: article="[^"]*")?) name="[^"]*"' % item_id, r'\1 name="%s"' % name, xml)
        assert count == 1, item_id
    # artículo correcto para los nuevos nombres
    xml = re.sub(r'<item id="7644" article="[^"]*"', '<item id="7644" article="an"', xml)
    # descripción del antídoto
    if 'key="description" value="%s"' % DESCRIPTIONS[7644] not in xml:
        xml = re.sub(r'(<item id="7644"[^>]*>\n)', r'\1\t\t<attribute key="description" value="%s"/>\n' % DESCRIPTIONS[7644], xml)
    # flechas y bolts: pilas de 255 como en MU
    for item_id in (3447, 3446):
        block = re.search(r'<item id="%d".*?</item>' % item_id, xml, re.S).group(0)
        if 'key="stacksize"' not in block:
            xml = xml.replace(block, block.replace('\t</item>', '\t\t<attribute key="stacksize" value="255"/>\n\t</item>', 1) if block.endswith('\t</item>') else block.replace('</item>', '\t<attribute key="stacksize" value="255"/>\n\t</item>'))
    # flechas y bolts siempre pegan (el acierto lo decide el sistema de MU)
    for item_id in (3447, 3446):
        block = re.search(r'<item id="%d".*?</item>' % item_id, xml, re.S).group(0)
        xml = xml.replace(block, re.sub(r'key="maxhitchance" value="\d+"', 'key="hitchance" value="100"', block))
    # quiver (35562): lo usan las elfas (Fairy Elf y Muse Elf); va en la mano del escudo con las flechas adentro
    block = re.search(r'<item id="35562".*?</item>', xml, re.S).group(0)
    xml = xml.replace(block, re.sub(r'key="vocation" value="[^"]*"', 'key="vocation" value="Fairy Elf;true, Muse Elf;true"', block))
    # arcos gastan flechas y ballestas gastan bolts (desde el quiver en la mano del escudo)
    for item_id, ammo_type in (AMMO_WEAPONS.items() if ammo else ()):
        block = re.search(r'<item id="%d".*?</item>' % item_id, xml, re.S).group(0)
        if 'key="ammotype"' not in block:
            new = block.replace('<attribute key="shootType"', '<attribute key="ammotype" value="%s"/>\n\t\t<attribute key="shootType"' % ammo_type, 1)
            xml = xml.replace(block, new)
    # items nuevos (se reemplazan si ya estaban)
    for item_id, block in XML_NEW.items():
        block = block.replace("{d}", DESCRIPTIONS.get(item_id, ""))
        xml = re.sub(r'\t<item id="%d".*?</item>\n' % item_id, "", xml, flags=re.S)
        xml = xml.replace("</items>", block + "</items>")
    open(dst, "w", encoding="utf-8").write(xml)


if __name__ == "__main__":
    build_dat(sys.argv[1], sys.argv[2])
    # --sin-municion: los arcos no gastan flechas
    build_xml(sys.argv[3], sys.argv[4], ammo="--sin-municion" not in sys.argv)
