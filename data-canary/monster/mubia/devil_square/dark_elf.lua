-- Mubia Online: Dark Elf (Devil Square, nivel 135). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Dark Elf")
local monster = {}

monster.outfit = {
	lookType = 9,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 135,
	health = 75000,
	damage = { 850, 900 },
	defense = 690,
	speed = 220,
	corpse = 6040,
	magic = true,
})
