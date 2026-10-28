-- Mubia Online: Giant Ogre 3 (Blood Castle 3, nivel 70). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Giant Ogre 3")
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
	level = 70,
	health = 9500,
	damage = { 210, 240 },
	defense = 180,
	attackRate = 400,
	defenseRate = 115,
	attackSpeed = 1600,
	speed = 220,
	corpse = 5962,
	ranged = true,
})
