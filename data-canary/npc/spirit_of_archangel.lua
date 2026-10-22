-- Mubia Online: Spirit of Archangel (Devias). Por ahora solo habla: Blood Castle llega más adelante.

local npcType = Game.createNpcType("Spirit of Archangel")
local npcConfig = {}

npcConfig.outfit = {
	lookType = 130,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerShopNpc(npcType, npcConfig, {
	shop = {},
	greeting = "|PLAYERNAME|, el Arcángel necesita guerreros para defender Blood Castle. Muy pronto te llamaré.",
	voice = "Blood Castle espera a sus defensores.",
})
