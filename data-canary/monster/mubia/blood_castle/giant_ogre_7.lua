-- Mubia Online: Giant Ogre 7 (Blood Castle 7, nivel 93). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Giant Ogre 7")
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
	level = 93,
	health = 37000,
	damage = { 470, 520 },
	defense = 440,
	attackRate = 730,
	defenseRate = 250,
	attackSpeed = 1600,
	speed = 220,
	corpse = 5962,
	ranged = true,
})
