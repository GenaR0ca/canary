-- Mubia Online: Cursed Wizard (Lost Tower 2 y 3, nivel 54). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Cursed Wizard")
local monster = {}

monster.outfit = {
	lookType = 9,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 54,
	health = 4000,
	damage = { 160, 170 },
	defense = 95,
	speed = 220,
	corpse = 6028,
	magic = true,
})
