-- Mubia Online: Drakan (Icarus, nivel 86). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Drakan")
local monster = {}

monster.outfit = {
	lookType = 334,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 86,
	health = 29000,
	damage = { 425, 480 },
	defense = 305,
	speed = 200,
	corpse = 5995,
})
