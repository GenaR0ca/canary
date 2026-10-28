-- Mubia Online: Death Rider (Aida 1 y 2, nivel 68). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Death Rider")
local monster = {}

monster.outfit = {
	lookType = 131,
	lookHead = 114,
	lookBody = 114,
	lookLegs = 114,
	lookFeet = 114,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 68,
	health = 8000,
	damage = { 232, 262 },
	defense = 170,
	speed = 220,
	corpse = 5995,
})
