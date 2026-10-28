-- Mubia Online: Giant Ogre 6 (Blood Castle 6, nivel 90). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Giant Ogre 6")
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
	level = 90,
	health = 32000,
	damage = { 440, 500 },
	defense = 400,
	attackRate = 660,
	defenseRate = 230,
	attackSpeed = 1600,
	speed = 220,
	corpse = 5962,
	ranged = true,
})
