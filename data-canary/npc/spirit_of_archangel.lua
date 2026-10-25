-- Mubia Online: Spirit of Archangel (Devias). Solo habla: manda a los jugadores al Messenger of Archangel para entrar a Blood Castle.

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
	greeting = "|PLAYERNAME|, el Arcángel necesita guerreros para defender Blood Castle. Habla con el {Messenger of Archangel}, al lado de Charon, para entrar.",
	voice = "¡Blood Castle espera a sus defensores! El Messenger of Archangel te lleva.",
})
