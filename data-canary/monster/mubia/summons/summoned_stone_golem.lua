-- Mubia Online: Summoned Stone Golem, invocación de la Fairy Elf.

local mType = Game.createMonsterType("Summoned Stone Golem")
local monster = {}

monster.outfit = {
	lookType = 67,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerSummon(mType, monster, {
	health = 300,
	damage = { 40, 50 },
	defense = 10,
	speed = 160,
})
