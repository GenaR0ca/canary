-- Mubia Online: Balrog (Lost Tower 7, nivel 66). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Balrog")
local monster = {}

monster.outfit = {
	lookType = 243,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 66,
	health = 9000,
	damage = { 220, 240 },
	defense = 160,
	speed = 220,
	corpse = 6335,
})
