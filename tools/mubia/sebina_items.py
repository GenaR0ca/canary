"""Mubia Online: items de la misión de Sebina the Priest (segunda evolución, 2026-10-27).

Agrega a appearances.dat los items nuevos (copiando el dibujo de un item de Tibia) y escribe sus bloques en items.xml.
Se puede correr de nuevo sin duplicar nada.

Uso: python3 sebina_items.py <appearances.dat entrada> <appearances.dat salida> <items.xml entrada> <items.xml salida>
"""
import re
import sys

sys.path.insert(0, "/tmp/claude-0/gen")
import appearances_pb2 as A  # generado con protoc desde src/protobuf/appearances.proto

# id: (artículo, nombre, item de Tibia del que se copia el dibujo, descripción sin tildes: el cliente las muestra mal)
ITEMS = {
    60801: ("a", "Scroll of Emperor", 22771, "Pergamino sellado por el emperador. Sebina the Priest lo pide para despertar tu verdadero poder."),
    60802: ("a", "Broken Sword", 3119, "Espada rota de un antiguo caballero. La pide Sebina the Priest a los Dark Knight."),
    60803: ("a", "Tear of Elf", 3233, "Llanto cristalizado de una antigua elfa. Lo pide Sebina the Priest a las Fairy Elf."),
    60804: ("a", "Soul of Wizard", 5944, "Alma de un antiguo mago. La pide Sebina the Priest a los Dark Wizard."),
    60805: ("an", "Abyssal Eye", 16262, "Ojo del abismo. Lo pide Sebina the Priest a las Summoner."),
}

QUEST_NOTE = " Item de la quest de Sebina: no se puede vender, intercambiar ni tirar."


def build_dat(src, dst):
    data = A.Appearances()
    data.ParseFromString(open(src, "rb").read())
    by_id = {o.id: o for o in data.object}
    for item_id, (_, name, base, _) in ITEMS.items():
        if item_id in by_id:
            obj = by_id[item_id]
            obj.Clear()
        else:
            obj = data.object.add()
        obj.id = item_id
        obj.name = name.encode()
        obj.frame_group.extend(by_id[base].frame_group)
        obj.flags.take = True
    open(dst, "wb").write(data.SerializeToString())


def build_xml(src, dst):
    xml = open(src, encoding="utf-8").read()
    for item_id, (article, name, _, description) in ITEMS.items():
        xml = re.sub(r'\t<item id="%d".*?</item>\n' % item_id, "", xml, flags=re.S)
        block = (
            '\t<item id="%d" article="%s" name="%s">\n'
            '\t\t<attribute key="primarytype" value="valuables"/>\n'
            '\t\t<attribute key="description" value="%s"/>\n'
            '\t\t<attribute key="weight" value="10"/>\n'
            "\t</item>\n" % (item_id, article, name, description + QUEST_NOTE)
        )
        xml = xml.replace("</items>", block + "</items>")
    open(dst, "w", encoding="utf-8").write(xml)


if __name__ == "__main__":
    build_dat(sys.argv[1], sys.argv[2])
    build_xml(sys.argv[3], sys.argv[4])
