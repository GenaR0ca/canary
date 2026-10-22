-- Mubia Online: Summoned Assassin, invocación de la Fairy Elf.

local mType = Game.createMonsterType("Summoned Assassin")
local monster = {}

monster.outfit = {
	lookType = 152,
	lookHead = 95,
	lookBody = 95,
	lookLegs = 95,
	lookFeet = 95,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerSummon(mType, monster, {
	health = 450,
	damage = { 60, 75 },
	defense = 15,
	speed = 220,
})
