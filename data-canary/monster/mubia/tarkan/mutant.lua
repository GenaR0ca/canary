-- Mubia Online: Mutant (Tarkan, nivel 72). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Mutant")
local monster = {}

monster.outfit = {
	lookType = 323,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 72,
	health = 10000,
	damage = { 250, 280 },
	defense = 190,
	speed = 220,
	corpse = 5798,
})
