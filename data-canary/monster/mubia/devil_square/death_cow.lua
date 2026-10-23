-- Mubia Online: Death Cow (Devil Square, nivel 57). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Death Cow")
local monster = {}

monster.outfit = {
	lookType = 55,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 57,
	health = 4500,
	damage = { 170, 180 },
	defense = 110,
	speed = 220,
	corpse = 5962,
})
