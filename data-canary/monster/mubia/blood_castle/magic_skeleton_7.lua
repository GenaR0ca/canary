-- Mubia Online: Magic Skeleton 7 (Blood Castle 7, nivel 102). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Magic Skeleton 7")
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
	level = 102,
	health = 55000,
	damage = { 560, 600 },
	defense = 550,
	attackRate = 870,
	defenseRate = 310,
	attackSpeed = 1800,
	speed = 220,
	corpse = 6040,
	magic = true,
})
