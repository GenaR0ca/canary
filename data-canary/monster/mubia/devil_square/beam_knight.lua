-- Mubia Online: Beam Knight (Devil Square, nivel 84). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Beam Knight")
local monster = {}

monster.outfit = {
	lookType = 234,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 84,
	health = 25000,
	damage = { 375, 425 },
	defense = 275,
	speed = 220,
	corpse = 6040,
})
