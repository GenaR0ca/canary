-- Mubia Online: Worm (Devias, nivel 20). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Worm")
local monster = {}

monster.outfit = {
	lookType = 26,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 20,
	health = 560,
	damage = { 69, 74 },
	defense = 23,
	speed = 200,
	corpse = 6040,
})
