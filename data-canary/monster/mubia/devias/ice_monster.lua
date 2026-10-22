-- Mubia Online: Ice Monster (Devias, nivel 22). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Ice Monster")
local monster = {}

monster.outfit = {
	lookType = 261,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 22,
	health = 678,
	damage = { 76, 81 },
	defense = 25,
	speed = 200,
	corpse = 6040,
})
