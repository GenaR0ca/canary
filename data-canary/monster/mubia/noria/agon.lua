-- Mubia Online: Agon (Noria, nivel 16). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Agon")
local monster = {}

monster.outfit = {
	lookType = 114,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 16,
	health = 340,
	damage = { 51, 56 },
	defense = 18,
	speed = 200,
	corpse = 6040,
})
