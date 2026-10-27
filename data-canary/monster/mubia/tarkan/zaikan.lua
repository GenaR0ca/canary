-- Mubia Online: Zaikan (jefe de Tarkan, nivel 90). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Zaikan")
local monster = {}

monster.outfit = {
	lookType = 300,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 90,
	health = 34000,
	damage = { 510, 590 },
	defense = 400,
	speed = 240,
	corpse = 8127,
	magic = true,
})
