-- Mubia Online: Summoned Soldier, invocación de la Fairy Elf.

local mType = Game.createMonsterType("Summoned Soldier")
local monster = {}

monster.outfit = {
	lookType = 71,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerSummon(mType, monster, {
	health = 4500,
	damage = { 220, 250 },
	defense = 60,
	speed = 220,
})
