-- Mubia Online: Vepar (Atlans, nivel 45). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Vepar")
local monster = {}

monster.outfit = {
	lookType = 20,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 45,
	health = 2800,
	damage = { 135, 145 },
	defense = 70,
	speed = 220,
	corpse = 6067,
	magic = true,
})
