-- Mubia Online: Assassin (Devias, nivel 26). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Assassin")
local monster = {}

monster.outfit = {
	lookType = 152,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 26,
	health = 946,
	damage = { 90, 95 },
	defense = 29,
	speed = 200,
	corpse = 6040,
})
