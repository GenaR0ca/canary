-- Mubia Online: Gigantis (Devil Square, nivel 105). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Gigantis")
local monster = {}

monster.outfit = {
	lookType = 101,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 105,
	health = 30000,
	damage = { 475, 510 },
	defense = 360,
	speed = 220,
	corpse = 5962,
})
