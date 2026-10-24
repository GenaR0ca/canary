-- Mubia Online: Chief Skeleton Warrior 2 (Blood Castle 2, nivel 49). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Chief Skeleton Warrior 2")
local monster = {}

monster.outfit = {
	lookType = 298,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 49,
	health = 3500,
	damage = { 140, 170 },
	defense = 90,
	attackRate = 250,
	defenseRate = 76,
	attackSpeed = 2000,
	speed = 220,
	corpse = 5962,
})
