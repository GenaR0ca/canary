-- Mubia Online: Arena Guard (Arena), vende gratis pociones de vida y de mana, como el guardia del estadio de MU.

local npcType = Game.createNpcType("Arena Guard")
local npcConfig = {}

npcConfig.outfit = {
	lookType = 134,
	lookHead = 95,
	lookBody = 114,
	lookLegs = 114,
	lookFeet = 95,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerShopNpc(npcType, npcConfig, {
	shop = Mubia.NpcPotions,
	greeting = "¡Bienvenido a la Arena, |PLAYERNAME|! Las jaulas van de la 1 (monstruos débiles) a la 14 (los más fuertes). Si necesitas pociones di {trade}, son gratis.",
})
