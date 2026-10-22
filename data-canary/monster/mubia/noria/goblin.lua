-- Mubia Online: Goblin (Noria, nivel 3). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Goblin")
local monster = {}

monster.outfit = {
	lookType = 61,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 3,
	health = 45,
	damage = { 7, 10 },
	defense = 3,
	speed = 180,
	corpse = 6002,
})
