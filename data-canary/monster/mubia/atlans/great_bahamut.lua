-- Mubia Online: Great Bahamut (Atlans 2, nivel 66). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Great Bahamut")
local monster = {}

monster.outfit = {
	lookType = 275,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 66,
	health = 7000,
	damage = { 210, 230 },
	defense = 150,
	speed = 230,
	corpse = 949,
})
