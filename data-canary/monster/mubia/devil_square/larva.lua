-- Mubia Online: Larva (Devil Square, nivel 25). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Larva")
local monster = {}

monster.outfit = {
	lookType = 82,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 25,
	health = 750,
	damage = { 90, 95 },
	defense = 31,
	speed = 220,
	corpse = 5962,
})
