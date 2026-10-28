-- Mubia Online: Phantom Knight (Icarus, lejos del centro, nivel 96). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Phantom Knight")
local monster = {}

monster.outfit = {
	lookType = 131,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 96,
	health = 41000,
	damage = { 560, 610 },
	defense = 425,
	speed = 200,
	corpse = 5995,
})
