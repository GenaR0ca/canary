-- Mubia Online: Guard, los guardias de las puertas de Lorencia y Devias. Solo hablan y dan consejos.

local npcType = Game.createNpcType("Guard")
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
	greeting = "Hola |PLAYERNAME|. Dentro de la ciudad estás a salvo. Afuera, los monstruos son más fuertes cuanto más lejos vas. Usa la tecla M para viajar a otras ciudades.",
	voice = "¡Cuidado afuera de la ciudad, aventurero!",
})
