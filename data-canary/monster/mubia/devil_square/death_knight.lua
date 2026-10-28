-- Mubia Online: Death Knight (Devil Square, nivel 62). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Death Knight")
local monster = {}

monster.outfit = {
	lookType = 300,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 62,
	health = 5500,
	damage = { 190, 200 },
	defense = 120,
	speed = 220,
	corpse = 6040,
})
