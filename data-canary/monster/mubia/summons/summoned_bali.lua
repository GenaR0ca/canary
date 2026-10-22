-- Mubia Online: Summoned Bali, invocación de la Fairy Elf.

local mType = Game.createMonsterType("Summoned Bali")
local monster = {}

monster.outfit = {
	lookType = 55,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerSummon(mType, monster, {
	health = 3000,
	damage = { 170, 190 },
	defense = 45,
	speed = 200,
})
