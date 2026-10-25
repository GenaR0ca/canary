-- Mubia Online: Wizard Izabel, maga de Devias: lo mismo que Lumen más flechas y bolts +3, gratis.

local npcType = Game.createNpcType("Wizard Izabel")
local npcConfig = {}

npcConfig.outfit = {
	lookType = 138,
	lookHead = 9,
	lookBody = 86,
	lookLegs = 86,
	lookFeet = 9,
	lookAddons = 2,
	lookMount = 0,
}

Mubia.registerShopNpc(npcType, npcConfig, {
	shop = Mubia.Shop(Mubia.ShopBarmaid, { ammo = { Mubia.BOLT, Mubia.ARROW } }),
	greeting = "Hola |PLAYERNAME|. Tengo pociones, Ale, entradas para los eventos y flechas y bolts +3. Di {trade}, todo es gratis.",
	voice = "¡Pociones, entradas y flechas! Di {trade}.",
})
