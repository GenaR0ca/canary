-- Mubia Online: Summoned Dark Knight, invocación de la Fairy Elf.

local mType = Game.createMonsterType("Summoned Dark Knight")
local monster = {}

monster.outfit = {
	lookType = 131,
	lookHead = 95,
	lookBody = 114,
	lookLegs = 114,
	lookFeet = 95,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerSummon(mType, monster, {
	health = 1200,
	damage = { 120, 140 },
	defense = 30,
	speed = 220,
})
