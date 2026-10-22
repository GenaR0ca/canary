-- Mubia Online: Eo the Craftsman (Noria), vende gratis pociones de vida y de mana.

local npcType = Game.createNpcType("Eo the Craftsman")
local npcConfig = {}

npcConfig.outfit = {
	lookType = 128,
	lookHead = 58,
	lookBody = 101,
	lookLegs = 82,
	lookFeet = 115,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerShopNpc(npcType, npcConfig, {
	shop = Mubia.NpcPotions,
	greeting = "¡Bienvenido a Noria, |PLAYERNAME|! Preparo pociones de vida y de mana. Di {trade}, son gratis.",
})
