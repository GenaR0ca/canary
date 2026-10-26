-- Mubia Online: Poison Shadow (Lost Tower 1 y 2, nivel 50). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Poison Shadow")
local monster = {}

monster.outfit = {
	lookType = 235,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 50,
	health = 3500,
	damage = { 155, 160 },
	defense = 85,
	speed = 220,
	corpse = 6028,
})
