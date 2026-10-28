-- Mubia Online: Magic Skeleton 3 (Blood Castle 3, nivel 79). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Magic Skeleton 3")
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
	level = 79,
	health = 15000,
	damage = { 230, 280 },
	defense = 240,
	attackRate = 500,
	defenseRate = 180,
	attackSpeed = 1800,
	speed = 220,
	corpse = 6040,
	magic = true,
})
