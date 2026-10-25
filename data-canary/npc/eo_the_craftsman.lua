-- Mubia Online: Eo the Craftsman, artesano de Noria: arcos y ballestas con Luck, flechas y bolts +3, gratis.

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
	shop = Mubia.Shop(
		{ gear = { "Elven Bow", "Battle Bow", "Arquebus", "Light Crossbow" } },
		{ ammo = { Mubia.BOLT, Mubia.ARROW } }
	),
	greeting = "¡Bienvenido a Noria, |PLAYERNAME|! Fabrico arcos y ballestas con Luck, y flechas y bolts +3. Di {trade}, todo es gratis.",
	voice = "¡Arcos, ballestas, flechas y bolts! Di {trade}.",
})
