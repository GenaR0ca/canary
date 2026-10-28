-- Mubia Online: Charon, el guardián de la Devil Square (Noria, Devias y Lorencia). Te lleva a la arena.
-- Todo lo que hace está en Mubia.DevilSquare.registerCharon (data/libs/systems/mubia_devil_square.lua).

local npcType = Game.createNpcType("Charon")
local npcConfig = {}

npcConfig.outfit = {
	lookType = 133,
	lookHead = 114,
	lookBody = 114,
	lookLegs = 114,
	lookFeet = 114,
	lookAddons = 3,
	lookMount = 0,
}

Mubia.DevilSquare.registerCharon(npcType, npcConfig)
