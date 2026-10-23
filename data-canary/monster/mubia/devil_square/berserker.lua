-- Mubia Online: Berserker (Devil Square, nivel 106). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Berserker")
local monster = {}

monster.outfit = {
	lookType = 8,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 106,
	health = 33000,
	damage = { 500, 540 },
	defense = 410,
	speed = 220,
	corpse = 5962,
})
