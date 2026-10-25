-- Mubia Online: Lumen the Barmaid, tabernera de Lorencia: pociones, Antidote, Ale, Olive of Love y entradas a los eventos, gratis.

local npcType = Game.createNpcType("Lumen the Barmaid")
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
	shop = Mubia.Shop(Mubia.ShopBarmaid),
	greeting = "¡Hola |PLAYERNAME|, bienvenido a la taberna! Tengo pociones, Ale, Olive of Love y entradas para Blood Castle y Devil Square. Di {trade}, todo es gratis.",
	voice = "¡Pociones, Ale y entradas para los eventos! Di {trade}.",
})
