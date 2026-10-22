-- Mubia Online: Summoned Goblin, invocación de la Fairy Elf.

local mType = Game.createMonsterType("Summoned Goblin")
local monster = {}

monster.outfit = {
	lookType = 61,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerSummon(mType, monster, {
	health = 80,
	damage = { 15, 20 },
	defense = 3,
	speed = 180,
})
