-- Mubia Online: Mega Crust (Icarus, nivel 78). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Mega Crust")
local monster = {}

monster.outfit = {
	lookType = 263,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 78,
	health = 15000,
	damage = { 270, 320 },
	defense = 210,
	speed = 200,
	corpse = 5995,
})
