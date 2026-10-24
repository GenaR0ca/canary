-- Mubia Online: Magic Skeleton 2 (Blood Castle 2, nivel 69). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Magic Skeleton 2")
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
	level = 69,
	health = 8000,
	damage = { 200, 240 },
	defense = 190,
	attackRate = 400,
	defenseRate = 130,
	attackSpeed = 1800,
	speed = 220,
	corpse = 6040,
	magic = true,
})
