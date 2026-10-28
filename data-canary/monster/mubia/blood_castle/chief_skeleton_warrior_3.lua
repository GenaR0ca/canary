-- Mubia Online: Chief Skeleton Warrior 3 (Blood Castle 3, nivel 56). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Chief Skeleton Warrior 3")
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
	level = 56,
	health = 5000,
	damage = { 160, 180 },
	defense = 110,
	attackRate = 300,
	defenseRate = 85,
	attackSpeed = 2000,
	speed = 220,
	corpse = 5962,
})
