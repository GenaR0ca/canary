-- Mubia Online: Chief Skeleton Warrior 6 (Blood Castle 6, nivel 76). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Chief Skeleton Warrior 6")
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
	level = 76,
	health = 17000,
	damage = { 260, 290 },
	defense = 210,
	attackRate = 460,
	defenseRate = 150,
	attackSpeed = 2000,
	speed = 220,
	corpse = 5962,
})
