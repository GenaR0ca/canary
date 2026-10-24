-- Mubia Online: Giant Ogre 1 (Blood Castle 1, nivel 44). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Giant Ogre 1")
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
	level = 44,
	health = 2100,
	damage = { 130, 150 },
	defense = 85,
	attackRate = 250,
	defenseRate = 73,
	attackSpeed = 1600,
	speed = 220,
	corpse = 5962,
	ranged = true,
})
