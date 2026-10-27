-- Mubia Online: Death Tree (Aida 1, nivel 62). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Death Tree")
local monster = {}

monster.outfit = {
	lookType = 310,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 62,
	health = 6000,
	damage = { 220, 240 },
	defense = 145,
	speed = 180,
	corpse = 8953,
})
