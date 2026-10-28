-- Mubia Online: Dark Knight (Devil Square, nivel 48). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Dark Knight")
local monster = {}

monster.outfit = {
	lookType = 131,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 48,
	health = 3000,
	damage = { 150, 155 },
	defense = 80,
	speed = 220,
	corpse = 5962,
})
