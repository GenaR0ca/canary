-- Mubia Online: Chief Skeleton Archer 2 (Blood Castle 2, nivel 53). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Chief Skeleton Archer 2")
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
	level = 53,
	health = 4100,
	damage = { 150, 180 },
	defense = 100,
	attackRate = 275,
	defenseRate = 80,
	attackSpeed = 1600,
	speed = 220,
	corpse = 5962,
	ranged = true,
})
