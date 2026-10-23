-- Mubia Online: Dreadfear (Devil Square, nivel 123). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Dreadfear")
local monster = {}

monster.outfit = {
	lookType = 39,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 123,
	health = 55000,
	damage = { 700, 740 },
	defense = 610,
	speed = 220,
	corpse = 6040,
})
