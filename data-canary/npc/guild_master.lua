-- Mubia Online: Guild Master (Devias). Por ahora solo habla: los gremios todavía no existen.

local npcType = Game.createNpcType("Guild Master")
local npcConfig = {}

npcConfig.outfit = {
	lookType = 131,
	lookHead = 95,
	lookBody = 95,
	lookLegs = 95,
	lookFeet = 95,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerShopNpc(npcType, npcConfig, {
	shop = {},
	greeting = "Hola |PLAYERNAME|. Soy el maestro de los gremios de Devias. Pronto podrás crear tu propio gremio aquí.",
	voice = "Pronto se podrán crear gremios en Devias.",
})
