-- Mubia Online: Ogre Archer (Devil Square, nivel 70). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Ogre Archer")
local monster = {}

monster.outfit = {
	lookType = 50,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 70,
	health = 10000,
	damage = { 220, 250 },
	defense = 170,
	speed = 220,
	corpse = 5962,
	ranged = true,
})
