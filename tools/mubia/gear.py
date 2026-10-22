# Mubia Online: genera los sets, armas y escudos de MU Online (Season 6).
#
# Uso: python3 tools/mubia/gear.py
#   - agrega los items a data/items/appearances.dat (con el dibujo de un item de Tibia parecido)
#   - agrega los items a data/items/items.xml
#   - escribe data/libs/systems/mubia_gear.lua (clase, defensa, daño y requisitos de cada item)
# Si los items ya existen, los reemplaza. Para cambiar valores, editar las tablas de abajo y volver a correrlo.
import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
DAT = os.path.join(ROOT, "data/items/appearances.dat")
XML = os.path.join(ROOT, "data/items/items.xml")
LUA = os.path.join(ROOT, "data/libs/systems/mubia_gear.lua")

FIRST_ID, LAST_ID = 61001, 63999

DK, DW, ELF = "DK", "DW", "ELF"
CLASS_LUA = {DK: "Mubia.CLASS_DK", DW: "Mubia.CLASS_DW", ELF: "Mubia.CLASS_ELF"}

# --- Sets -------------------------------------------------------------------------------------------
# (nombre, defensa de la armadura, STR, AGI, nivel mínimo, dibujos de Tibia: casco, armadura, pantalón, guantes, botas)
# Las otras piezas tienen menos defensa que la armadura (PIECES).
SETS = {
    DK: [
        ("Leather", 10, 80, 0, 0, (3355, 3361, 3559, 17828, 3552)),
        ("Bronze", 14, 80, 20, 0, (3352, 3358, 3558, 17853, 3550)),
        ("Scale", 18, 110, 0, 0, (3353, 3377, 3362, 10405, 3556)),
        ("Brass", 22, 100, 30, 0, (3354, 3359, 3372, 17828, 3554)),
        ("Plate", 30, 130, 0, 0, (3351, 3357, 3557, 10405, 3554)),
        ("Dragon", 37, 120, 30, 0, (3400, 3386, 3363, 11691, 10201)),
        ("Ashcrow", 42, 160, 50, 0, (3405, 3370, 3371, 17853, 4033)),
        ("Black Dragon", 48, 170, 60, 0, (3384, 3383, 3389, 32705, 10323)),
        ("Dark Phoenix", 63, 198, 60, 0, (3387, 3388, 821, 50181, 9018)),
        ("Great Dragon", 75, 200, 58, 0, (3365, 3360, 3364, 50271, 3555)),
        ("Dragon Knight", 88, 230, 68, 380, (3392, 3381, 3382, 5875, 16112)),
    ],
    DW: [
        ("Pad", 7, 20, 0, 0, (3573, 3567, 3560, 17828, 3551)),
        ("Bone", 13, 30, 0, 0, (3408, 3566, 9383, 17853, 3549)),
        ("Sphinx", 17, 30, 0, 0, (3574, 8040, 645, 10405, 3246)),
        ("Legendary", 22, 40, 0, 0, (7992, 7991, 823, 11691, 819)),
        ("Eclipse", 27, 45, 10, 0, (830, 811, 812, 32705, 813)),
        ("Grand Soul", 33, 59, 20, 0, (828, 825, 822, 50181, 820)),
        ("Dark Soul", 43, 55, 25, 0, (827, 826, 821, 50271, 818)),
        ("Venom Mist", 57, 60, 30, 380, (9653, 10438, 10387, 17853, 19374)),
    ],
    ELF: [
        ("Vine", 8, 20, 40, 0, (3406, 3402, 9014, 17828, 3551)),
        ("Silk", 12, 25, 55, 0, (3393, 3394, 7464, 17853, 7457)),
        ("Wind", 16, 30, 65, 0, (3368, 3571, 8095, 10405, 3079)),
        ("Spirit", 21, 35, 70, 0, (9382, 8042, 3401, 11691, 3549)),
        ("Guardian", 29, 40, 80, 0, (3369, 3399, 14087, 32705, 10200)),
        ("Iris", 36, 40, 95, 0, (3407, 8041, 13999, 50181, 13997)),
        ("Divine", 44, 30, 100, 0, (3022, 8057, 16106, 50271, 6529)),
        ("Red Spirit", 55, 52, 115, 0, (11674, 8063, 8863, 5875, 9019)),
        ("Sylphid Ray", 68, 55, 140, 380, (16109, 16110, 16111, 5875, 16112)),
    ],
}

# (pieza, nombre en inglés, % de la defensa de la armadura, slot)
PIECES = [
    ("helm", "Helm", 80, "head"),
    ("armor", "Armor", 100, "armor"),
    ("pants", "Pants", 90, "legs"),
    ("gloves", "Gloves", 65, "gloves"),
    ("boots", "Boots", 75, "feet"),
]

# --- Armas ------------------------------------------------------------------------------------------
# (nombre, daño mín, daño máx, STR, AGI, dos manos, dibujo de Tibia)
WEAPONS = {
    ("sword", DK): [
        ("Short Sword", 3, 7, 60, 0, False, 3294),
        ("Kris", 6, 11, 10, 8, False, 3267),
        ("Rapier", 9, 15, 50, 40, False, 3272),
        ("Katana", 16, 26, 80, 40, False, 3300),
        ("Gladius", 20, 30, 110, 0, False, 3264),
        ("Falchion", 24, 34, 120, 0, False, 3273),
        ("Serpent Sword", 30, 42, 130, 0, False, 3297),
        ("Blade", 36, 47, 80, 50, False, 3285),
        ("Legendary Sword", 44, 61, 140, 0, False, 3295),
        ("Lighting Sword", 59, 75, 150, 45, False, 794),
        ("Giant Sword", 64, 82, 140, 50, True, 3281),
        ("Sword of Destruction", 82, 90, 124, 44, False, 7416),
        ("Knight Blade", 112, 125, 116, 38, False, 7417),
        ("Dark Reign Blade", 125, 140, 116, 53, False, 7418),
        ("Bone Blade", 140, 158, 192, 52, False, 3338),
    ],
    ("axe", DK): [
        ("Small Axe", 1, 6, 50, 0, False, 3276),
        ("Hand Axe", 4, 9, 70, 0, False, 3268),
        ("Double Axe", 14, 24, 90, 0, False, 3275),
        ("Tomahawk", 18, 28, 100, 0, False, 3316),
        ("Elven Axe", 26, 38, 50, 70, False, 3318),
        ("Battle Axe", 30, 44, 120, 0, True, 3266),
        ("Nikea Axe", 38, 50, 130, 0, True, 3303),
        ("Larkan Axe", 54, 67, 180, 0, True, 3342),
        ("Crescent Axe", 69, 89, 150, 40, True, 7420),
        ("Chaos Dragon Axe", 75, 130, 140, 50, True, 8098),
    ],
    ("club", DK): [
        ("Mace", 7, 13, 100, 0, False, 3286),
        ("Morning Star", 13, 22, 100, 0, False, 3282),
        ("Flail", 22, 32, 80, 50, False, 7421),
        ("Great Hammer", 45, 56, 150, 0, True, 3279),
        ("Crystal Morning Star", 78, 107, 130, 0, True, 3333),
    ],
    ("spear", DK): [
        ("Dragon Lance", 21, 31, 70, 50, True, 3302),
        ("Giant Trident", 35, 43, 90, 30, True, 12683),
        ("Serpent Spear", 46, 58, 90, 30, True, 3313),
        ("Light Spear", 50, 63, 60, 70, True, 3314),
        ("Great Scythe", 71, 92, 90, 30, True, 9384),
        ("Bill of Balrog", 76, 102, 80, 50, True, 3315),
        ("Dragon Spear", 112, 140, 170, 60, True, 10388),
    ],
    ("bow", ELF): [
        ("Short Bow", 3, 5, 20, 80, True, 9378),
        ("Bow", 9, 13, 30, 90, True, 3350),
        ("Elven Bow", 17, 24, 30, 90, True, 7438),
        ("Battle Bow", 28, 37, 30, 100, True, 8029),
        ("Tiger Bow", 42, 52, 30, 100, True, 8027),
        ("Silver Bow", 59, 71, 30, 100, True, 12733),
        ("Chaos Nature Bow", 88, 106, 40, 150, True, 8030),
        ("Celestial Bow", 92, 113, 54, 198, True, 8026),
        ("Albatross Bow", 120, 140, 50, 170, True, 19362),
    ],
    ("crossbow", ELF): [
        ("Crossbow", 5, 8, 20, 90, True, 3349),
        ("Golden Crossbow", 11, 14, 30, 90, True, 8021),
        ("Arquebus", 22, 30, 30, 90, True, 5803),
        ("Light Crossbow", 35, 44, 30, 90, True, 8022),
        ("Serpent Crossbow", 50, 60, 30, 100, True, 14247),
        ("Bluewing Crossbow", 68, 82, 30, 100, True, 8023),
        ("Aquagold Crossbow", 72, 88, 30, 100, True, 16163),
        ("Saint Crossbow", 102, 127, 50, 200, True, 8024),
    ],
}

# Bastones del DW: (nombre, daño mín, daño máx, % de daño mágico extra, STR, AGI, dibujo de Tibia)
STAFFS = [
    ("Skull Staff", 6, 11, 3, 40, 0, 3324),
    ("Angelic Staff", 18, 25, 10, 50, 0, 3341),
    ("Serpent Staff", 30, 40, 14, 50, 0, 7430),
    ("Thunder Staff", 42, 52, 20, 40, 10, 3321),
    ("Gorgon Staff", 56, 64, 25, 50, 0, 7424),
    ("Legendary Staff", 59, 66, 31, 50, 0, 7426),
    ("Staff of Resurrection", 64, 72, 32, 60, 10, 3343),
    ("Chaos Lightning Staff", 70, 80, 38, 60, 10, 13987),
    ("Staff of Destruction", 78, 88, 42, 60, 10, 17111),
    ("Dragon Soul Staff", 80, 92, 52, 60, 20, 8082),
    ("Staff of Kundun", 86, 97, 59, 60, 20, 8092),
    ("Grand Viper Staff", 90, 104, 65, 65, 20, 16096),
    ("Platina Staff", 96, 110, 71, 70, 25, 16115),
]

# Escudos: (nombre, defensa, STR, AGI, clases, dibujo de Tibia)
SHIELDS = [
    ("Small Shield", 3, 70, 0, (DK, DW, ELF), 3412),
    ("Buckler", 6, 80, 0, (DK, DW, ELF), 3430),
    ("Elven Shield", 8, 30, 100, (ELF,), 3427),
    ("Skull Shield", 9, 60, 0, (DK, DW), 3441),
    ("Horn Shield", 9, 100, 0, (DK,), 3443),
    ("Kite Shield", 12, 110, 0, (DK,), 3409),
    ("Large Round Shield", 17, 120, 0, (DK,), 3413),
    ("Legendary Shield", 18, 90, 25, (DW, ELF), 3423),
    ("Tower Shield", 20, 130, 0, (DK,), 3428),
    ("Serpent Shield", 22, 130, 0, (DK,), 3436),
    ("Elemental Shield", 28, 30, 110, (ELF,), 8077),
    ("Dragon Slayer Shield", 29, 100, 40, (DK,), 3416),
    ("Cross Shield", 31, 160, 0, (DK,), 3417),
    ("Grand Soul Shield", 33, 70, 20, (DW,), 3414),
]

KIND_NAMES = {"sword": "Espada", "axe": "Hacha", "club": "Maza", "spear": "Lanza", "bow": "Arco", "crossbow": "Ballesta"}


def build_items():
    items = []
    next_id = 61001
    for cls in (DK, DW, ELF):
        for name, defense, str_, agi, level, sprites in SETS[cls]:
            for (piece, piece_name, percent, slot), sprite in zip(PIECES, sprites):
                items.append(
                    dict(id=next_id, name=f"{name} {piece_name}", kind="armor", piece=piece, slot=slot, classes=(cls,),
                         defense=max(1, round(defense * percent / 100)), str=str_, agi=agi, level=level, sprite=sprite,
                         set=name)
                )
                next_id += 1
    next_id = 62001
    for (wtype, cls), weapons in WEAPONS.items():
        for name, dmin, dmax, str_, agi, two_handed, sprite in weapons:
            items.append(dict(id=next_id, name=name, kind="weapon", wtype=wtype, classes=(cls,), min=dmin, max=dmax,
                              str=str_, agi=agi, level=0, twoHanded=two_handed, sprite=sprite))
            next_id += 1
    for name, dmin, dmax, rise, str_, agi, sprite in STAFFS:
        items.append(dict(id=next_id, name=name, kind="staff", wtype="staff", classes=(DW,), min=dmin, max=dmax,
                          magic=rise, str=str_, agi=agi, level=0, twoHanded=False, sprite=sprite))
        next_id += 1
    next_id = 63001
    for name, defense, str_, agi, classes, sprite in SHIELDS:
        items.append(dict(id=next_id, name=name, kind="shield", classes=classes, defense=defense, str=str_, agi=agi,
                          level=0, sprite=sprite))
        next_id += 1
    for item in items:
        assert FIRST_ID <= item["id"] <= LAST_ID
    return items


# --- appearances.dat (protobuf a mano) ---------------------------------------------------------------
def varint(b, i):
    r = s = 0
    while True:
        x = b[i]
        i += 1
        r |= (x & 0x7F) << s
        s += 7
        if x < 0x80:
            return r, i


def fields(b):
    i = 0
    while i < len(b):
        st = i
        k, i = varint(b, i)
        f, w = k >> 3, k & 7
        if w == 0:
            v, i = varint(b, i)
        elif w == 2:
            n, i = varint(b, i)
            v = b[i:i + n]
            i += n
        elif w == 5:
            v = b[i:i + 4]
            i += 4
        elif w == 1:
            v = b[i:i + 8]
            i += 8
        else:
            raise ValueError("wire type")
        yield f, w, v, b[st:i]


def enc_varint(n):
    out = b""
    while True:
        b = n & 0x7F
        n >>= 7
        if n:
            out += bytes([b | 0x80])
        else:
            return out + bytes([b])


def ld(f, b):
    return enc_varint(f << 3 | 2) + enc_varint(len(b)) + b


# Flags del item de Tibia que se copian: take, light, shift, height, animate_always y clothes (el slot)
KEEP_FLAGS = {18, 23, 26, 27, 29, 34}


def build_dat(items):
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
    for item in items:
        base = objects[item["sprite"]]
        frames = b"".join(x[3] for x in base if x[0] == 2)
        flags = b""
        for x in base:
            if x[0] == 3:
                for ff, fw, fv, fraw in fields(x[2]):
                    if ff in KEEP_FLAGS and not (ff == 34 and item.get("slot") == "gloves"):
                        flags += fraw
        if 18 not in [ff for ff, *_ in fields(flags)]:
            flags += enc_varint(18 << 3) + enc_varint(1)
        new += ld(1, enc_varint(1 << 3) + enc_varint(item["id"]) + frames + ld(3, flags) + ld(4, item["name"].lower().encode()))

    out = b""
    inserted = False
    last_object = max(i for i, (f, _) in enumerate(pieces) if f == 1)
    for i, (f, raw) in enumerate(pieces):
        out += raw
        if i == last_object:
            out += new
            inserted = True
    assert inserted
    open(DAT, "wb").write(out)
    print(f"appearances.dat: {len(items)} items de MU ({len(data)} -> {len(out)} bytes)")


# --- items.xml ---------------------------------------------------------------------------------------
# Sin "moveevent": al equiparse los revisa data/scripts/mubia/items.lua (clase, STR, AGI y nivel).
PRIMARY = {"head": "helmets", "armor": "armors", "legs": "legs", "feet": "boots", "gloves": "gloves"}
TIBIA_WEAPON = {"sword": "sword", "axe": "axe", "club": "club", "spear": "axe"}


def xml_item(item):
    lines = [f'\t<item id="{item["id"]}" name="{item["name"].lower()}">']
    attr = lambda k, v: lines.append(f'\t\t<attribute key="{k}" value="{v}"/>')
    kind = item["kind"]
    if kind == "armor":
        attr("primarytype", PRIMARY[item["slot"]])
        if item["slot"] == "gloves":
            attr("slottype", "gloves")
        attr("weight", 1000)
    elif kind == "shield":
        attr("primarytype", "shields")
        attr("weaponType", "shield")
        attr("weight", 2000)
    elif kind == "staff":
        attr("primarytype", "wands")
        attr("weaponType", "wand")
        attr("shootType", "energy")
        attr("range", 4)
        attr("weight", 1500)
        lines.append('\t\t<attribute key="script" value="weapon">')
        lines.append('\t\t\t<attribute key="mana" value="0"/>')
        lines.append(f'\t\t\t<attribute key="fromDamage" value="{item["min"]}"/>')
        lines.append(f'\t\t\t<attribute key="toDamage" value="{item["max"]}"/>')
        lines.append('\t\t\t<attribute key="weaponType" value="wand"/>')
        lines.append('\t\t\t<attribute key="wandType" value="energy"/>')
        lines.append("\t\t</attribute>")
    elif item["wtype"] in ("bow", "crossbow"):
        # sin flechas: el arco dispara solo y siempre acierta (el daño lo calcula Mubia)
        attr("primarytype", "distance weapons")
        attr("weaponType", "distance")
        attr("slotType", "two-handed")
        attr("shootType", "arrow" if item["wtype"] == "bow" else "bolt")
        attr("range", 6)
        attr("hitchance", 100)
        attr("attack", item["max"])
        attr("weight", 2000)
        lines.append('\t\t<attribute key="script" value="weapon">')
        lines.append('\t\t\t<attribute key="weaponType" value="distance"/>')
        lines.append("\t\t</attribute>")
    else:
        weapon_type = TIBIA_WEAPON[item["wtype"]]
        attr("primarytype", f"{weapon_type} weapons")
        attr("weaponType", weapon_type)
        if item["twoHanded"]:
            attr("slotType", "two-handed")
        attr("attack", item["max"])
        attr("weight", 3000)
        lines.append('\t\t<attribute key="script" value="weapon">')
        lines.append(f'\t\t\t<attribute key="weaponType" value="{weapon_type}"/>')
        lines.append("\t\t</attribute>")
    lines.append("\t</item>")
    return "\n".join(lines) + "\n"


BEGIN = "\t<!-- Mubia: items de MU (generado por tools/mubia/gear.py) -->\n"
END = "\t<!-- Mubia: fin de items de MU -->\n"


def build_xml(items):
    s = open(XML, encoding="utf-8").read()
    if BEGIN in s:
        s = s[: s.index(BEGIN)] + s[s.index(END) + len(END):]
    for item in items:
        assert f'id="{item["id"]}"' not in s, item["id"]
    # Items de Tibia con el mismo nombre que uno de MU: pasan a llamarse "... (tibia)", así el loot
    # de los monstruos (que busca por nombre) da el item de MU y no hay nombres repetidos.
    mu_names = {i["name"].lower() for i in items}
    renamed = 0

    def rename(m):
        nonlocal renamed
        if m.group(2) in mu_names:
            renamed += 1
            return f'{m.group(1)}name="{m.group(2)} (tibia)"'
        return m.group(0)

    s = re.sub(r'(<item (?:id|fromid)="\d+"[^>]*?)name="([^"]+)"', rename, s)
    block = BEGIN + "".join(xml_item(i) for i in items) + END
    i = s.rindex("</items>")
    s = s[:i] + block + s[i:]
    open(XML, "w", encoding="utf-8").write(s)
    print(f"items.xml: {len(items)} items de MU, {renamed} items de Tibia renombrados")


# --- mubia_gear.lua ----------------------------------------------------------------------------------
def lua_item(item):
    classes = ", ".join(CLASS_LUA[c] for c in item["classes"])
    parts = [f'name = "{item["name"]}"', f'kind = "{item["kind"]}"', f"classes = {{ {classes} }}"]
    if item["kind"] == "armor":
        parts += [f'piece = "{item["piece"]}"', f'set = "{item["set"]}"', f'defense = {item["defense"]}']
    elif item["kind"] == "shield":
        parts += [f'defense = {item["defense"]}']
    else:
        parts += [f'type = "{item["wtype"]}"', f'min = {item["min"]}', f'max = {item["max"]}']
        if item["kind"] == "staff":
            parts += [f'magic = {item["magic"]}']
        if item["twoHanded"]:
            parts += ["twoHanded = true"]
    parts += [f'str = {item["str"]}', f'agi = {item["agi"]}']
    if item["level"]:
        parts += [f'level = {item["level"]}']
    return f'\t[{item["id"]}] = {{ {", ".join(parts)} }},\n'


def build_lua(items):
    out = [
        "-- Mubia Online: sets, armas y escudos de MU (Season 6).\n",
        "-- Generado por tools/mubia/gear.py (ese script también crea los items en items.xml y appearances.dat).\n",
        "-- defense = defensa, min/max = daño, magic = % de daño mágico extra (bastones),\n",
        "-- str/agi = fuerza y agilidad necesarias, level = nivel mínimo del personaje.\n",
        "Mubia.Gear = {\n",
    ]
    out += [lua_item(i) for i in items]
    out.append("}\n\n")
    out.append("-- Set inicial de cada clase (se da una sola vez)\n")
    out.append("Mubia.StarterGear = {\n")
    for cls, weapon in ((DK, "Short Sword"), (DW, "Skull Staff"), (ELF, "Short Bow")):
        first_set = SETS[cls][0][0]
        ids = [i["id"] for i in items if i.get("set") == first_set and cls in i["classes"]]
        ids += [i["id"] for i in items if i["name"] == weapon]
        out.append(f"\t[{CLASS_LUA[cls]}] = {{ {', '.join(map(str, ids))} }},\n")
    out.append("}\n")
    open(LUA, "w", encoding="utf-8").write("".join(out))
    print(f"mubia_gear.lua: {len(items)} items de MU")


if __name__ == "__main__":
    items = build_items()
    build_dat(items)
    build_xml(items)
    build_lua(items)
