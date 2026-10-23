# Mubia Online: genera un archivo por monstruo de Devil Square en data-canary/monster/mubia/devil_square/
# (el editor de mapas solo reconoce una criatura por archivo). Los stats salen del Monster.txt de MU
# (Mubia.MonsterStats); aquí solo va el dibujo de Tibia provisorio y si ataca a distancia.
#
# Uso: python3 tools/mubia/devil_square_monsters.py
import os
import re

ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
OUT = os.path.join(ROOT, "data-canary/monster/mubia/devil_square")
STATS = os.environ.get("MUBIA_STATS", os.path.join(ROOT, "data/libs/systems/mubia_monster_stats.lua"))

# nombre: (lookType de Tibia, corpse, ataque) ataque = "melee" | "magic" | "ranged"
MONSTERS = {
    # Devil Square +1
    "Larva": (82, 5962, "melee"),
    "Ghost": (48, 5962, "melee"),
    "Skeleton Archer": (33, 5962, "ranged"),
    "Hell Hound": (240, 5962, "melee"),
    # +2
    "Hell Spider": (38, 5962, "magic"),
    "Elite Skeleton": (37, 5962, "melee"),
    "Thunder Lich": (99, 6040, "magic"),
    "Poison Bull": (29, 5962, "melee"),
    "Gorgon": (330, 6040, "melee"),
    # +3
    "Shadow": (233, 6040, "melee"),
    "Dark Knight": (131, 5962, "melee"),
    "Poison Shadow": (232, 6040, "melee"),
    "Cursed Wizard": (130, 6040, "magic"),
    "Death Gorgon": (220, 6040, "melee"),
    # +4
    "Death Cow": (55, 5962, "melee"),
    "Devil": (35, 6040, "magic"),
    "Death Knight": (300, 6040, "melee"),
    "Balrog": (243, 6040, "melee"),
    # +5
    "Ogre Archer": (50, 5962, "ranged"),
    "Elite Ogre": (59, 5962, "melee"),
    "Metal Balrog": (244, 6040, "melee"),
    "Cursed King": (236, 6040, "magic"),
    # +6
    "Bloody Wolf": (3, 5962, "melee"),
    "Iron Wheel": (245, 6040, "melee"),
    "Tantallos": (247, 6040, "melee"),
    "Beam Knight": (234, 6040, "melee"),
    "Death Beam Knight": (322, 6040, "melee"),
    # +7
    "Gigantis": (101, 5962, "melee"),
    "Berserker": (8, 5962, "melee"),
    "Balram (Trainee)": (246, 6040, "melee"),
    "Soram (Trainee)": (237, 6040, "magic"),
    "Persona": (78, 6040, "magic"),
    "Dreadfear": (39, 6040, "melee"),
    "Dark Elf": (9, 6040, "magic"),
}

TEMPLATE = """-- Mubia Online: {name} (Devil Square, nivel {level}). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("{name}")
local monster = {{}}

monster.outfit = {{
	lookType = {look},
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}}

Mubia.registerWildMonster(mType, monster, {{
	level = {level},
	health = {hp},
	damage = {{ {mind}, {maxd} }},
	defense = {defense},
	speed = 220,
	corpse = {corpse},{extra}
}})
"""


def main():
    stats = open(STATS, encoding="utf-8").read()
    os.makedirs(OUT, exist_ok=True)
    for name, (look, corpse, attack) in MONSTERS.items():
        m = re.search(r'\["' + re.escape(name) + r'"\] = \{([^}]*)\}', stats)
        assert m, name
        row = dict(re.findall(r"(\w+) = (-?\d+)", m.group(1)))
        extra = "\n\tmagic = true," if attack == "magic" else "\n\tranged = true," if attack == "ranged" else ""
        text = TEMPLATE.format(name=name, level=row["level"], look=look, hp=row["hp"], mind=row["minDamage"],
                               maxd=row["maxDamage"], defense=row["defense"], corpse=corpse, extra=extra)
        file = re.sub(r"[^a-z0-9]+", "_", name.lower()).strip("_") + ".lua"
        open(os.path.join(OUT, file), "w", encoding="utf-8").write(text)
    print(f"{len(MONSTERS)} monstruos en {OUT}")


if __name__ == "__main__":
    main()
