-- Mubia Online: Chief Skeleton Warrior 4 (Blood Castle 4, nivel 64). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Chief Skeleton Warrior 4")
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
	level = 64,
	health = 7500,
	damage = { 180, 220 },
	defense = 150,
	attackRate = 340,
	defenseRate = 98,
	attackSpeed = 2000,
	speed = 220,
	corpse = 5962,
})
