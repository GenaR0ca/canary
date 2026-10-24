-- Mubia Online: Giant Ogre 2 (Blood Castle 2, nivel 60). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Giant Ogre 2")
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
	level = 60,
	health = 6000,
	damage = { 175, 210 },
	defense = 130,
	attackRate = 320,
	defenseRate = 95,
	attackSpeed = 1600,
	speed = 220,
	corpse = 5962,
	ranged = true,
})
