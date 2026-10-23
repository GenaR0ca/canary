-- Mubia Online: Cursed King (Devil Square, nivel 86). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Cursed King")
local monster = {}

monster.outfit = {
	lookType = 236,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 86,
	health = 38000,
	damage = { 500, 570 },
	defense = 350,
	speed = 220,
	corpse = 6040,
	magic = true,
})
