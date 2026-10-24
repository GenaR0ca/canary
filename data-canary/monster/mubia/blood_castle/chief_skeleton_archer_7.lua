-- Mubia Online: Chief Skeleton Archer 7 (Blood Castle 7, nivel 87). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Chief Skeleton Archer 7")
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
	level = 87,
	health = 26000,
	damage = { 390, 430 },
	defense = 380,
	attackRate = 590,
	defenseRate = 200,
	attackSpeed = 1600,
	speed = 220,
	corpse = 5962,
	ranged = true,
})
