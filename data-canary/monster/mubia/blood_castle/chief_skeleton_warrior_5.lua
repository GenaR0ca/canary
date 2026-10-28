-- Mubia Online: Chief Skeleton Warrior 5 (Blood Castle 5, nivel 70). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Chief Skeleton Warrior 5")
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
	level = 70,
	health = 12000,
	damage = { 210, 270 },
	defense = 185,
	attackRate = 380,
	defenseRate = 125,
	attackSpeed = 2000,
	speed = 220,
	corpse = 5962,
})
