-- Mubia Online: Alpha Crust (Icarus, lejos del centro, nivel 92). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Alpha Crust")
local monster = {}

monster.outfit = {
	lookType = 55,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 92,
	health = 34500,
	damage = { 489, 540 },
	defense = 360,
	speed = 200,
	corpse = 5995,
})
