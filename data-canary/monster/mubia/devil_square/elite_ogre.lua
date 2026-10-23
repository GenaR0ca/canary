-- Mubia Online: Elite Ogre (Devil Square, nivel 74). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Elite Ogre")
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
	level = 74,
	health = 14000,
	damage = { 260, 290 },
	defense = 190,
	speed = 220,
	corpse = 5962,
})
