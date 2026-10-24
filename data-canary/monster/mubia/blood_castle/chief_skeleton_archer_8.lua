-- Mubia Online: Chief Skeleton Archer 8 (Blood Castle 8, nivel 97). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Chief Skeleton Archer 8")
local monster = {}

monster.outfit = {
	lookType = 33,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 97,
	health = 71400,
	damage = { 510, 570 },
	defense = 465,
	attackRate = 610,
	defenseRate = 289,
	attackSpeed = 1600,
	speed = 220,
	corpse = 5962,
	ranged = true,
})
