-- Mubia Online: Hell Spider (Devil Square, nivel 40). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Hell Spider")
local monster = {}

monster.outfit = {
	lookType = 38,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 40,
	health = 1600,
	damage = { 130, 135 },
	defense = 60,
	speed = 220,
	corpse = 5962,
	magic = true,
})
