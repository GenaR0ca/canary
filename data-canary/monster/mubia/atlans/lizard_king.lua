-- Mubia Online: Lizard King (Atlans 3, nivel 70). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Lizard King")
local monster = {}

monster.outfit = {
	lookType = 344,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 70,
	health = 9000,
	damage = { 240, 270 },
	defense = 180,
	speed = 220,
	corpse = 10371,
	magic = true,
})
