-- Mubia Online: Chief Skeleton Warrior 8 (Blood Castle 8, nivel 93). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Chief Skeleton Warrior 8")
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
	level = 93,
	health = 61100,
	damage = { 400, 470 },
	defense = 355,
	attackRate = 590,
	defenseRate = 245,
	attackSpeed = 2000,
	speed = 220,
	corpse = 5962,
})
