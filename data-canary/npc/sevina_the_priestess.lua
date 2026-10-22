-- Mubia Online: Sevina the Priestess (Devias). Por ahora solo habla: su misión para cambiar de clase llega más adelante.

local npcType = Game.createNpcType("Sevina the Priestess")
local npcConfig = {}

npcConfig.outfit = {
	lookType = 138,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerShopNpc(npcType, npcConfig, {
	shop = {},
	greeting = "Bienvenido, |PLAYERNAME|. Cuando seas más fuerte te daré la misión para mejorar tu clase.",
	voice = "Los aventureros fuertes pueden mejorar su clase... pronto.",
})
