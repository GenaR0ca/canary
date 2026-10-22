-- Mubia Online: Stone Golem (Noria, nivel 18). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Stone Golem")
local monster = {}

monster.outfit = {
	lookType = 67,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 18,
	health = 465,
	damage = { 62, 67 },
	defense = 21,
	speed = 170,
	corpse = 6005,
})
