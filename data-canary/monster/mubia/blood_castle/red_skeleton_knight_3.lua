-- Mubia Online: Red Skeleton Knight 3 (Blood Castle 3, nivel 74). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Red Skeleton Knight 3")
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
	level = 74,
	health = 12000,
	damage = { 220, 260 },
	defense = 190,
	attackRate = 440,
	defenseRate = 130,
	attackSpeed = 2000,
	speed = 220,
	corpse = 5962,
})
