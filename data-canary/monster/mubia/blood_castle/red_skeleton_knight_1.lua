-- Mubia Online: Red Skeleton Knight 1 (Blood Castle 1, nivel 47). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Red Skeleton Knight 1")
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
	level = 47,
	health = 2800,
	damage = { 140, 160 },
	defense = 95,
	attackRate = 270,
	defenseRate = 77,
	attackSpeed = 2000,
	speed = 220,
	corpse = 5962,
})
