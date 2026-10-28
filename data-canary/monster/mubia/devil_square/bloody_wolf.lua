-- Mubia Online: Bloody Wolf (Devil Square, nivel 76). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Bloody Wolf")
local monster = {}

monster.outfit = {
	lookType = 3,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 76,
	health = 13500,
	damage = { 260, 300 },
	defense = 200,
	speed = 220,
	corpse = 5962,
})
