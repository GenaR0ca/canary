-- Mubia Online: Ghost (Devil Square, nivel 32). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Ghost")
local monster = {}

monster.outfit = {
	lookType = 48,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 32,
	health = 1000,
	damage = { 110, 115 },
	defense = 40,
	speed = 220,
	corpse = 5962,
})
