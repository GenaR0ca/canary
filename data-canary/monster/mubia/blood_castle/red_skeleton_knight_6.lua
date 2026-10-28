-- Mubia Online: Red Skeleton Knight 6 (Blood Castle 6, nivel 94). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Red Skeleton Knight 6")
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
	level = 94,
	health = 38000,
	damage = { 480, 540 },
	defense = 450,
	attackRate = 720,
	defenseRate = 260,
	attackSpeed = 2000,
	speed = 220,
	corpse = 5962,
})
