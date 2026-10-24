-- Mubia Online: Magic Skeleton 4 (Blood Castle 4, nivel 84). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Magic Skeleton 4")
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
	level = 84,
	health = 24000,
	damage = { 300, 350 },
	defense = 360,
	attackRate = 640,
	defenseRate = 200,
	attackSpeed = 1800,
	speed = 220,
	corpse = 6040,
	magic = true,
})
