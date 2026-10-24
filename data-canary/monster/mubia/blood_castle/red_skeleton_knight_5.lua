-- Mubia Online: Red Skeleton Knight 5 (Blood Castle 5, nivel 87). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Red Skeleton Knight 5")
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
	level = 87,
	health = 26000,
	damage = { 370, 410 },
	defense = 400,
	attackRate = 650,
	defenseRate = 200,
	attackSpeed = 2000,
	speed = 220,
	corpse = 5962,
})
