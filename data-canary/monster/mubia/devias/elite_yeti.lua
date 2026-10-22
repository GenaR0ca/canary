-- Mubia Online: Elite Yeti (Devias, nivel 36). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Elite Yeti")
local monster = {}

monster.outfit = {
	lookType = 257,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 36,
	health = 1814,
	damage = { 125, 130 },
	defense = 39,
	speed = 200,
	corpse = 6040,
})
