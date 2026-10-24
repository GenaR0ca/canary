# Mubia Online: genera un archivo por monstruo de Blood Castle en data-canary/monster/mubia/blood_castle/
# (el editor de mapas solo reconoce una criatura por archivo). Los stats son los del Monster.txt de MU
# (secciones "Blood Castle 1" a "Blood Castle 8"); cada castillo tiene sus 6 monstruos con el número del castillo
# en el nombre (como en MU: "Chief Skeleton Warrior 1" ... "Magic Skeleton 8").
# La Castle Gate y la Statue of Saint se escriben a mano (data-canary/monster/mubia/blood_castle/castle_gate.lua y
# statue_of_saint.lua) porque no caminan ni atacan.
#
# Uso: python3 tools/mubia/blood_castle_monsters.py
import os
import re

ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
OUT = os.path.join(ROOT, "data-canary/monster/mubia/blood_castle")

# nombre: (lookType de Tibia, corpse, ataque) ataque = "melee" | "magic" | "ranged"
KINDS = [
    ("Chief Skeleton Warrior", 298, 5962, "melee"),
    ("Chief Skeleton Archer", 33, 5962, "ranged"),
    ("Dark Skull Soldier", 37, 5962, "melee"),
    ("Giant Ogre", 59, 5962, "ranged"),
    ("Red Skeleton Knight", 306, 5962, "melee"),
    ("Magic Skeleton", 99, 6040, "magic"),
]

# Monster.txt: (castillo, índice MU, nivel, vida, daño mín, daño máx, defensa, precisión, bloqueo, alcance, vel. ataque)
ROWS = [
    (1, 84, 33, 1100, 100, 120, 55, 190, 45, 1, 2000),
    (1, 85, 37, 1400, 110, 130, 65, 210, 49, 5, 1600),
    (1, 86, 41, 1700, 120, 140, 75, 230, 61, 1, 2000),
    (1, 87, 44, 2100, 130, 150, 85, 250, 73, 5, 1600),
    (1, 88, 47, 2800, 140, 160, 95, 270, 77, 1, 2000),
    (1, 89, 51, 3700, 150, 180, 115, 300, 88, 4, 1600),
    (2, 90, 49, 3500, 140, 170, 90, 250, 76, 1, 2000),
    (2, 91, 53, 4100, 150, 180, 100, 275, 80, 5, 1600),
    (2, 92, 56, 5000, 160, 190, 115, 300, 88, 1, 2000),
    (2, 93, 60, 6000, 175, 210, 130, 320, 95, 5, 1600),
    (2, 94, 64, 7000, 185, 220, 170, 360, 110, 1, 2000),
    (2, 95, 69, 8000, 200, 240, 190, 400, 130, 4, 1800),
    (3, 96, 56, 5000, 160, 180, 110, 300, 85, 1, 2000),
    (3, 97, 61, 6500, 180, 200, 120, 330, 93, 5, 1600),
    (3, 98, 66, 8000, 190, 220, 150, 360, 98, 1, 2000),
    (3, 99, 70, 9500, 210, 240, 180, 400, 115, 5, 1600),
    (3, 111, 74, 12000, 220, 260, 190, 440, 130, 1, 2000),
    (3, 112, 79, 15000, 230, 280, 240, 500, 180, 4, 1800),
    (4, 113, 64, 7500, 180, 220, 150, 340, 98, 1, 2000),
    (4, 114, 69, 9500, 200, 240, 170, 380, 110, 5, 1600),
    (4, 115, 75, 12000, 220, 260, 190, 440, 130, 1, 2000),
    (4, 116, 79, 15000, 250, 290, 210, 500, 150, 5, 1600),
    (4, 117, 82, 18000, 270, 320, 290, 560, 170, 1, 2000),
    (4, 118, 84, 24000, 300, 350, 360, 640, 200, 4, 1800),
    (5, 119, 70, 12000, 210, 270, 185, 380, 125, 1, 2000),
    (5, 120, 75, 15000, 240, 300, 190, 420, 130, 5, 1600),
    (5, 121, 80, 19000, 280, 340, 220, 470, 175, 1, 2000),
    (5, 122, 85, 23000, 340, 390, 300, 520, 190, 5, 1600),
    (5, 123, 87, 26000, 370, 410, 400, 650, 200, 1, 2000),
    (5, 124, 90, 32000, 400, 460, 450, 720, 260, 4, 1800),
    (6, 125, 76, 17000, 260, 290, 210, 460, 150, 1, 2000),
    (6, 126, 81, 20000, 320, 350, 270, 520, 160, 5, 1600),
    (6, 127, 86, 25000, 390, 420, 360, 580, 195, 1, 2000),
    (6, 128, 90, 32000, 440, 500, 400, 660, 230, 5, 1600),
    (6, 129, 94, 38000, 480, 540, 450, 720, 260, 1, 2000),
    (6, 130, 99, 47000, 530, 580, 500, 840, 280, 4, 1800),
    (7, 138, 85, 23000, 340, 390, 340, 520, 190, 1, 2000),
    (7, 139, 87, 26000, 390, 430, 380, 590, 200, 5, 1600),
    (7, 140, 90, 32000, 430, 480, 400, 660, 230, 1, 2000),
    (7, 141, 93, 37000, 470, 520, 440, 730, 250, 5, 1600),
    (7, 142, 98, 45000, 510, 560, 490, 800, 270, 1, 2000),
    (7, 143, 102, 55000, 560, 600, 550, 870, 310, 4, 1800),
    (8, 428, 93, 61100, 400, 470, 355, 590, 245, 1, 2000),
    (8, 429, 97, 71400, 510, 570, 465, 610, 289, 5, 1600),
    (8, 430, 101, 81700, 580, 640, 475, 730, 321, 1, 2000),
    (8, 431, 104, 92100, 630, 650, 585, 850, 340, 5, 1600),
    (8, 432, 107, 102800, 710, 760, 595, 970, 377, 1, 2000),
    (8, 433, 115, 113700, 750, 780, 615, 1000, 488, 4, 1600),
]

TEMPLATE = """-- Mubia Online: {name} (Blood Castle {castle}, nivel {level}). Usa un dibujo de Tibia hasta tener sprite propio.

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
	attackRate = {attackRate},
	defenseRate = {defenseRate},
	attackSpeed = {attackSpeed},
	speed = 220,
	corpse = {corpse},{extra}
}})
"""


def main():
    os.makedirs(OUT, exist_ok=True)
    count = 0
    for k, row in enumerate(ROWS):
        castle, _, level, hp, mind, maxd, defense, attack_rate, defense_rate, _, attack_speed = row
        kind, look, corpse, attack = KINDS[k % 6]
        name = f"{kind} {castle}"
        extra = "\n\tmagic = true," if attack == "magic" else "\n\tranged = true," if attack == "ranged" else ""
        text = TEMPLATE.format(name=name, castle=castle, level=level, look=look, hp=hp, mind=mind, maxd=maxd,
                               defense=defense, attackRate=attack_rate, defenseRate=defense_rate,
                               attackSpeed=attack_speed, corpse=corpse, extra=extra)
        file = re.sub(r"[^a-z0-9]+", "_", name.lower()).strip("_") + ".lua"
        open(os.path.join(OUT, file), "w", encoding="utf-8").write(text)
        count += 1
    print(f"{count} monstruos en {OUT}")


if __name__ == "__main__":
    main()
