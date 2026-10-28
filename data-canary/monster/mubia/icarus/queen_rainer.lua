-- Mubia Online: Queen Rainer (Icarus, nivel 82). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Queen Rainer")
local monster = {}

monster.outfit = {
	lookType = 78,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 82,
	health = 19000,
	damage = { 305, 350 },
	defense = 230,
	speed = 200,
	corpse = 5995,
	magic = true,
})
