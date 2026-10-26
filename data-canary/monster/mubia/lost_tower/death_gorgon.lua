-- Mubia Online: Death Gorgon (Lost Tower 6 y 7, nivel 64). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Death Gorgon")
local monster = {}

monster.outfit = {
	lookType = 330,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 64,
	health = 6000,
	damage = { 200, 210 },
	defense = 130,
	speed = 220,
	corpse = 9607,
})
