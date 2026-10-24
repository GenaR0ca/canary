-- Mubia Online: Chief Skeleton Warrior 7 (Blood Castle 7, nivel 85). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Chief Skeleton Warrior 7")
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
	level = 85,
	health = 23000,
	damage = { 340, 390 },
	defense = 340,
	attackRate = 520,
	defenseRate = 190,
	attackSpeed = 2000,
	speed = 220,
	corpse = 5962,
})
