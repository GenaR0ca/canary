-- Mubia Online: Spider (Lorencia, nivel 2). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Spider")
local monster = {}

monster.outfit = {
	lookType = 30,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 2,
	health = 30,
	damage = { 4, 7 },
	defense = 1,
	speed = 180,
	corpse = 5961,
})
