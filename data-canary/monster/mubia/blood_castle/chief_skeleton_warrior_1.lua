-- Mubia Online: Chief Skeleton Warrior 1 (Blood Castle 1, nivel 33). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Chief Skeleton Warrior 1")
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
	level = 33,
	health = 1100,
	damage = { 100, 120 },
	defense = 55,
	attackRate = 190,
	defenseRate = 45,
	attackSpeed = 2000,
	speed = 220,
	corpse = 5962,
})
