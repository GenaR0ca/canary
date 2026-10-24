-- Mubia Online: Magic Skeleton 1 (Blood Castle 1, nivel 51). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Magic Skeleton 1")
local monster = {}

monster.outfit = {
	lookType = 99,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 51,
	health = 3700,
	damage = { 150, 180 },
	defense = 115,
	attackRate = 300,
	defenseRate = 88,
	attackSpeed = 1600,
	speed = 220,
	corpse = 6040,
	magic = true,
})
