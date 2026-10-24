-- Mubia Online: Chief Skeleton Archer 3 (Blood Castle 3, nivel 61). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Chief Skeleton Archer 3")
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
	level = 61,
	health = 6500,
	damage = { 180, 200 },
	defense = 120,
	attackRate = 330,
	defenseRate = 93,
	attackSpeed = 1600,
	speed = 220,
	corpse = 5962,
	ranged = true,
})
