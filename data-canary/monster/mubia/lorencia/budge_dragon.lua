-- Mubia Online: Budge Dragon (Lorencia, nivel 4). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Budge Dragon")
local monster = {}

monster.outfit = {
	lookType = 271,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 4,
	health = 60,
	damage = { 10, 15 },
	defense = 3,
	speed = 190,
	corpse = 269,
})
