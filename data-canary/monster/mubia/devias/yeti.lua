-- Mubia Online: Yeti (Devias, nivel 30). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Yeti")
local monster = {}

monster.outfit = {
	lookType = 110,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 30,
	health = 1260,
	damage = { 104, 109 },
	defense = 33,
	speed = 200,
	corpse = 6040,
})
