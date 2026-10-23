-- Mubia Online: Poison Bull (Devil Square, nivel 46). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Poison Bull")
local monster = {}

monster.outfit = {
	lookType = 29,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 46,
	health = 2500,
	damage = { 145, 150 },
	defense = 75,
	speed = 220,
	corpse = 5962,
})
