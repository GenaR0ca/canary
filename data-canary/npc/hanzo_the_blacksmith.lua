-- Mubia Online: Hanzo the Blacksmith, vende gratis los scrolls de magias de Dark Knight.

local npcType = Game.createNpcType("Hanzo the Blacksmith")
local npcConfig = {}

npcConfig.outfit = {
	lookType = 131,
	lookHead = 95,
	lookBody = 95,
	lookLegs = 95,
	lookFeet = 95,
	lookAddons = 3,
	lookMount = 0,
}

Mubia.registerShopNpc(npcType, npcConfig, {
	classId = Mubia.CLASS_DK,
})
