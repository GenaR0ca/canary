-- Mubia Online: Giant Ogre 4 (Blood Castle 4, nivel 79). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Giant Ogre 4")
local monster = {}

monster.outfit = {
	lookType = 59,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 79,
	health = 15000,
	damage = { 250, 290 },
	defense = 210,
	attackRate = 500,
	defenseRate = 150,
	attackSpeed = 1600,
	speed = 220,
	corpse = 5962,
	ranged = true,
})
