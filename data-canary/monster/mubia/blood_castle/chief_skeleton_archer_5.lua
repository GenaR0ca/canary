-- Mubia Online: Chief Skeleton Archer 5 (Blood Castle 5, nivel 75). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Chief Skeleton Archer 5")
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
	level = 75,
	health = 15000,
	damage = { 240, 300 },
	defense = 190,
	attackRate = 420,
	defenseRate = 130,
	attackSpeed = 1600,
	speed = 220,
	corpse = 5962,
	ranged = true,
})
