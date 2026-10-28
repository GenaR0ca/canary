-- Mubia Online: Bahamut (Atlans, nivel 43). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Bahamut")
local monster = {}

monster.outfit = {
	lookType = 317,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 43,
	health = 2400,
	damage = { 130, 140 },
	defense = 65,
	speed = 220,
	corpse = 8965,
})
