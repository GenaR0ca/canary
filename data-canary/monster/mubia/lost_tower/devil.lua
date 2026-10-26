-- Mubia Online: Devil (Lost Tower 4 y 5, nivel 60). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Devil")
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
	level = 60,
	health = 5000,
	damage = { 180, 195 },
	defense = 115,
	speed = 220,
	corpse = 5995,
	magic = true,
})
