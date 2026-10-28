-- Mubia Online: Red Skeleton Knight 2 (Blood Castle 2, nivel 64). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Red Skeleton Knight 2")
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
	level = 64,
	health = 7000,
	damage = { 185, 220 },
	defense = 170,
	attackRate = 360,
	defenseRate = 110,
	attackSpeed = 2000,
	speed = 220,
	corpse = 5962,
})
