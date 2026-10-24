-- Mubia Online: Giant Ogre 8 (Blood Castle 8, nivel 104). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Giant Ogre 8")
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
	level = 104,
	health = 92100,
	damage = { 630, 650 },
	defense = 585,
	attackRate = 850,
	defenseRate = 340,
	attackSpeed = 1600,
	speed = 220,
	corpse = 5962,
	ranged = true,
})
