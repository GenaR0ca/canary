-- Mubia Online: Elite Skeleton (Devil Square, nivel 42). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Elite Skeleton")
local monster = {}

monster.outfit = {
	lookType = 37,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 42,
	health = 1800,
	damage = { 135, 140 },
	defense = 65,
	speed = 220,
	corpse = 5962,
})
