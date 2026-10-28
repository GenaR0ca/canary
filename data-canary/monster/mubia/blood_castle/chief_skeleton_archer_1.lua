-- Mubia Online: Chief Skeleton Archer 1 (Blood Castle 1, nivel 37). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Chief Skeleton Archer 1")
local monster = {}

monster.outfit = {
	lookType = 33,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 37,
	health = 1400,
	damage = { 110, 130 },
	defense = 65,
	attackRate = 210,
	defenseRate = 49,
	attackSpeed = 1600,
	speed = 220,
	corpse = 5962,
	ranged = true,
})
