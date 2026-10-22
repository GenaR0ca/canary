-- Mubia Online: Summoned Elite Yeti, invocación de la Fairy Elf.

local mType = Game.createMonsterType("Summoned Elite Yeti")
local monster = {}

monster.outfit = {
	lookType = 110,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerSummon(mType, monster, {
	health = 700,
	damage = { 80, 95 },
	defense = 22,
	speed = 200,
})
