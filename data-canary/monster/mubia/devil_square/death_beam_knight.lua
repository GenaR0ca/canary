-- Mubia Online: Death Beam Knight (Devil Square, nivel 93). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Death Beam Knight")
local monster = {}

monster.outfit = {
	lookType = 322,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 93,
	health = 40000,
	damage = { 590, 650 },
	defense = 420,
	speed = 220,
	corpse = 6040,
})
