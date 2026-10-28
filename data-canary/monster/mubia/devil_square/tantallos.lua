-- Mubia Online: Tantallos (Devil Square, nivel 83). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Tantallos")
local monster = {}

monster.outfit = {
	lookType = 247,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 83,
	health = 22000,
	damage = { 335, 385 },
	defense = 250,
	speed = 220,
	corpse = 6040,
})
