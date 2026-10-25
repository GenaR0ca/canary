-- Mubia Online: Zienna the Weapons Merchant, armera de Devias: sets, armas y bastones con Luck, gratis.

local npcType = Game.createNpcType("Zienna the Weapons Merchant")
local npcConfig = {}

npcConfig.outfit = {
	lookType = 136,
	lookHead = 78,
	lookBody = 94,
	lookLegs = 114,
	lookFeet = 95,
	lookAddons = 1,
	lookMount = 0,
}

Mubia.registerShopNpc(npcType, npcConfig, {
	shop = Mubia.Shop({ sets = { "Plate", "Sphinx", "Spirit" } }, { gear = { "Tiger Bow", "Serpent Crossbow", "Gorgon Staff", "Blade", "Salamander Sword", "Great Scythe" } }),
	greeting = "¡Bienvenido a Devias, |PLAYERNAME|! Tengo sets, armas y bastones con Luck. Di {trade}, todo es gratis.",
	voice = "¡Sets, armas y bastones con Luck! Di {trade}.",
})
