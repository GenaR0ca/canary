-- Mubia Online: Skeleton Archer (Devil Square, nivel 34). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Skeleton Archer")
local monster = {}

monster.outfit = {
	lookType = 33,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 34,
	health = 1100,
	damage = { 115, 120 },
	defense = 45,
	speed = 220,
	corpse = 5962,
	ranged = true,
})
