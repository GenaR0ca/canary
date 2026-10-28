-- Mubia Online: Blue Golem (Aida 2, nivel 74). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Blue Golem")
local monster = {}

monster.outfit = {
	lookType = 261,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 74,
	health = 12500,
	damage = { 260, 290 },
	defense = 195,
	speed = 180,
	corpse = 7282,
})
