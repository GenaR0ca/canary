-- Mubia Online: City Guard, guardias que caminan dentro de Lorencia y Devias. Solo hablan y dan consejos.

local npcType = Game.createNpcType("City Guard")
local npcConfig = {}

npcConfig.outfit = {
	lookType = 131,
	lookHead = 57,
	lookBody = 88,
	lookLegs = 57,
	lookFeet = 95,
	lookAddons = 3,
	lookMount = 0,
}

Mubia.registerShopNpc(npcType, npcConfig, {
	shop = {},
	walkRadius = 4,
	greeting = "Hola |PLAYERNAME|. Estoy patrullando la ciudad. Dentro de la ciudad estás a salvo.",
	voice = "¡Todo tranquilo por aquí!",
})
