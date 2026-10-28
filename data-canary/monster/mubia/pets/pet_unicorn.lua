-- Mubia Online: Pet Unicorn, mascota que sigue a quien la tiene equipada (ver data/libs/systems/mubia_pets.lua).

local mType = Game.createMonsterType("Pet Unicorn")
local monster = {}

monster.outfit = {
	lookType = 400,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerPet(mType, monster, {})
