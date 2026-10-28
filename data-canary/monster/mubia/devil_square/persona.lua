-- Mubia Online: Persona (Devil Square, nivel 121). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Persona")
local monster = {}

monster.outfit = {
	lookType = 78,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 121,
	health = 50000,
	damage = { 640, 680 },
	defense = 560,
	speed = 220,
	corpse = 6040,
	magic = true,
})
