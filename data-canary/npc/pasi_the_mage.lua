-- Mubia Online: Pasi the Mage, vende gratis los scrolls de magias de Dark Wizard.

local npcType = Game.createNpcType("Pasi the Mage")
local npcConfig = {}

npcConfig.outfit = {
	lookType = 130,
	lookHead = 0,
	lookBody = 88,
	lookLegs = 88,
	lookFeet = 0,
	lookAddons = 3,
	lookMount = 0,
}

Mubia.registerShopNpc(npcType, npcConfig, {
	classId = Mubia.CLASS_DW,
})
