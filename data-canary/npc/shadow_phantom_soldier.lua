-- Mubia Online: Shadow Phantom Soldier, en cada salida de la ciudad. Al hablarle te da el buff de defensa y daño (30 minutos).

local npcType = Game.createNpcType("Shadow Phantom Soldier")
local npcConfig = {}

npcConfig.outfit = {
	lookType = 131,
	lookHead = 114,
	lookBody = 114,
	lookLegs = 114,
	lookFeet = 114,
	lookAddons = 3,
	lookMount = 0,
}

Mubia.registerShopNpc(npcType, npcConfig, {
	shop = {},
	greeting = "Hola |PLAYERNAME|. Ten cuidado ahí afuera.",
	voice = "¡Aventurero! Háblame y te doy la protección del Shadow Phantom.",
	onGreet = function(npc, player)
		Mubia.ElfSoldier.give(npc, player)
	end,
	keywords = {
		buff = function(npc, player)
			Mubia.ElfSoldier.give(npc, player)
		end,
	},
})
