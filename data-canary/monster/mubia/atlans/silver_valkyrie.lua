-- Mubia Online: Silver Valkyrie (Atlans 2, nivel 68). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Silver Valkyrie")
local monster = {}

monster.outfit = {
	lookType = 139,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 68,
	health = 8000,
	damage = { 230, 260 },
	defense = 170,
	speed = 220,
	corpse = 18242,
	magic = true,
})
