-- Mubia Online: Red Skeleton Knight 8 (Blood Castle 8, nivel 107). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Red Skeleton Knight 8")
local monster = {}

monster.outfit = {
	lookType = 306,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 107,
	health = 102800,
	damage = { 710, 760 },
	defense = 595,
	attackRate = 970,
	defenseRate = 377,
	attackSpeed = 2000,
	speed = 220,
	corpse = 5962,
})
