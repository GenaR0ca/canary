-- Mubia Online: Archangel, espera en la llegada de cada Blood Castle a que le devuelvan su arma.
-- Todo lo que hace está en Mubia.BloodCastle.registerArchangel (data/libs/systems/mubia_blood_castle.lua).

local npcType = Game.createNpcType("Archangel")
local npcConfig = {}

npcConfig.outfit = {
	lookType = 1069,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 79,
	lookFeet = 79,
	lookAddons = 3,
	lookMount = 0,
}

Mubia.BloodCastle.registerArchangel(npcType, npcConfig)
