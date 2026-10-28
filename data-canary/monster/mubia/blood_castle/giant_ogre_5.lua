-- Mubia Online: Giant Ogre 5 (Blood Castle 5, nivel 85). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Giant Ogre 5")
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
	level = 85,
	health = 23000,
	damage = { 340, 390 },
	defense = 300,
	attackRate = 520,
	defenseRate = 190,
	attackSpeed = 1600,
	speed = 220,
	corpse = 5962,
	ranged = true,
})
