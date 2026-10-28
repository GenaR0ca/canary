-- Mubia Online: Magic Skeleton 6 (Blood Castle 6, nivel 99). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Magic Skeleton 6")
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
	level = 99,
	health = 47000,
	damage = { 530, 580 },
	defense = 500,
	attackRate = 840,
	defenseRate = 280,
	attackSpeed = 1800,
	speed = 220,
	corpse = 6040,
	magic = true,
})
