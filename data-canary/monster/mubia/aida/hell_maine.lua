-- Mubia Online: Hell Maine (jefe de Aida, nivel 98). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Hell Maine")
local monster = {}

monster.outfit = {
	lookType = 35,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 98,
	health = 50000,
	damage = { 550, 600 },
	defense = 520,
	speed = 220,
	corpse = 5995,
	magic = true,
})
