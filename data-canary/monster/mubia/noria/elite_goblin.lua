-- Mubia Online: Elite Goblin (Noria, nivel 8). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Elite Goblin")
local monster = {}

monster.outfit = {
	lookType = 296,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 8,
	health = 120,
	damage = { 19, 26 },
	defense = 9,
	speed = 200,
	corpse = 6002,
})
