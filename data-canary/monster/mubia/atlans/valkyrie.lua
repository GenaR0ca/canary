-- Mubia Online: Valkyrie (Atlans, nivel 46). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Valkyrie")
local monster = {}

monster.outfit = {
	lookType = 139,
	lookHead = 113,
	lookBody = 38,
	lookLegs = 76,
	lookFeet = 96,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 46,
	health = 3200,
	damage = { 140, 150 },
	defense = 75,
	speed = 210,
	corpse = 18242,
	ranged = true,
})
