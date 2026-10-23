-- Mubia Online: Pet Panda, mascota que sigue a quien la tiene equipada (ver data/libs/systems/mubia_pets.lua).

local mType = Game.createMonsterType("Pet Panda")
local monster = {}

monster.outfit = {
	lookType = 123,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerPet(mType, monster, {})
