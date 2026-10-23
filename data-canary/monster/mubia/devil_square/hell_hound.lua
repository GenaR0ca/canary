-- Mubia Online: Hell Hound (Devil Square, nivel 38). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Hell Hound")
local monster = {}

monster.outfit = {
	lookType = 240,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 38,
	health = 1400,
	damage = { 125, 130 },
	defense = 55,
	speed = 220,
	corpse = 5962,
})
