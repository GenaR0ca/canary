-- Mubia Online: Chief Skeleton Archer 6 (Blood Castle 6, nivel 81). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Chief Skeleton Archer 6")
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
	level = 81,
	health = 20000,
	damage = { 320, 350 },
	defense = 270,
	attackRate = 520,
	defenseRate = 160,
	attackSpeed = 1600,
	speed = 220,
	corpse = 5962,
	ranged = true,
})
