-- Mubia Online: Messenger of Archangel, la entrada a Blood Castle (Noria, Devias y Lorencia).
-- Todo lo que hace está en Mubia.BloodCastle.registerMessenger (data/libs/systems/mubia_blood_castle.lua).

local npcType = Game.createNpcType("Messenger of Archangel")
local npcConfig = {}

npcConfig.outfit = {
	lookType = 130,
	lookHead = 0,
	lookBody = 79,
	lookLegs = 0,
	lookFeet = 79,
	lookAddons = 1,
	lookMount = 0,
}

Mubia.BloodCastle.registerMessenger(npcType, npcConfig)
