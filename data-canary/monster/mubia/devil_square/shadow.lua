-- Mubia Online: Shadow (Devil Square, nivel 47). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Shadow")
local monster = {}

monster.outfit = {
	lookType = 233,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 47,
	health = 2800,
	damage = { 148, 153 },
	defense = 78,
	speed = 220,
	corpse = 6040,
})
