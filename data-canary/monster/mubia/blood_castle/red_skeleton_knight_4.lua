-- Mubia Online: Red Skeleton Knight 4 (Blood Castle 4, nivel 82). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Red Skeleton Knight 4")
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
	level = 82,
	health = 18000,
	damage = { 270, 320 },
	defense = 290,
	attackRate = 560,
	defenseRate = 170,
	attackSpeed = 2000,
	speed = 220,
	corpse = 5962,
})
