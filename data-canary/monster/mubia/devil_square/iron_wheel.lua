-- Mubia Online: Iron Wheel (Devil Square, nivel 80). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Iron Wheel")
local monster = {}

monster.outfit = {
	lookType = 245,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 80,
	health = 17000,
	damage = { 280, 330 },
	defense = 215,
	speed = 220,
	corpse = 6040,
})
