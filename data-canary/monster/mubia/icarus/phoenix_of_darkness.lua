-- Mubia Online: Phoenix of Darkness (jefe de Icarus, nivel 108). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Phoenix of Darkness")
local monster = {}

monster.outfit = {
	lookType = 231,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 108,
	health = 95000,
	damage = { 950, 1000 },
	defense = 600,
	speed = 220,
	corpse = 5995,
	magic = true,
})
