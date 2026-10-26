-- Mubia Online: Potion Girl Amy, vive en la zona segura de Lost Tower 1. Vende lo mismo que Lumen the Barmaid
-- (la tabernera de Lorencia): pociones, Antidote, Ale, Olive of Love y entradas a los eventos, gratis.

local npcType = Game.createNpcType("Potion Girl Amy")
local npcConfig = {}

npcConfig.outfit = {
	lookType = 136,
	lookHead = 114,
	lookBody = 94,
	lookLegs = 114,
	lookFeet = 94,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerShopNpc(npcType, npcConfig, {
	shop = Mubia.Shop(Mubia.ShopBarmaid),
	greeting = "Hola |PLAYERNAME|... aquí en la torre las pociones salvan vidas. Tengo pociones, Ale, Olive of Love y entradas para Blood Castle y Devil Square. Di {trade}, todo es gratis.",
	voice = "¡Pociones para sobrevivir a la torre! Di {trade}.",
})
