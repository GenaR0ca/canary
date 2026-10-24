-- Mubia Online: Magic Skeleton 5 (Blood Castle 5, nivel 90). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Magic Skeleton 5")
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
	level = 90,
	health = 32000,
	damage = { 400, 460 },
	defense = 450,
	attackRate = 720,
	defenseRate = 260,
	attackSpeed = 1800,
	speed = 220,
	corpse = 6040,
	magic = true,
})
