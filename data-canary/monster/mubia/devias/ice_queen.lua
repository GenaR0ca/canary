-- Mubia Online: Ice Queen (jefa de Devias, nivel 52). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Ice Queen")
local monster = {}

monster.outfit = {
	lookType = 149,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 52,
	health = 10000,
	damage = { 170, 210 },
	defense = 60,
	speed = 220,
	corpse = 6040,
	magic = true,
})
