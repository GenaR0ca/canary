-- Mubia Online: Potion Girl Amy, vende gratis pociones de vida y de mana.

local npcType = Game.createNpcType("Potion Girl Amy")
local npcConfig = {}

npcConfig.outfit = {
	lookType = 136,
	lookHead = 78,
	lookBody = 94,
	lookLegs = 94,
	lookFeet = 78,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerShopNpc(npcType, npcConfig, {
	shop = Mubia.NpcPotions,
})
