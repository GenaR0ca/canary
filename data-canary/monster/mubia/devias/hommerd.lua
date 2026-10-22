-- Mubia Online: Hommerd (Devias, nivel 24). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Hommerd")
local monster = {}

monster.outfit = {
	lookType = 70,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 24,
	health = 806,
	damage = { 83, 88 },
	defense = 27,
	speed = 200,
	corpse = 6040,
})
