-- Mubia Online: Beetle Monster (Noria, nivel 10). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Beetle Monster")
local monster = {}

monster.outfit = {
	lookType = 45,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 10,
	health = 165,
	damage = { 26, 31 },
	defense = 11,
	speed = 190,
	corpse = 5990,
})
