-- Mubia Online: Red Skeleton Knight 7 (Blood Castle 7, nivel 98). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Red Skeleton Knight 7")
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
	level = 98,
	health = 45000,
	damage = { 510, 560 },
	defense = 490,
	attackRate = 800,
	defenseRate = 270,
	attackSpeed = 2000,
	speed = 220,
	corpse = 5962,
})
