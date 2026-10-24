-- Mubia Online: Chief Skeleton Archer 4 (Blood Castle 4, nivel 69). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Chief Skeleton Archer 4")
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
	level = 69,
	health = 9500,
	damage = { 200, 240 },
	defense = 170,
	attackRate = 380,
	defenseRate = 110,
	attackSpeed = 1600,
	speed = 220,
	corpse = 5962,
	ranged = true,
})
