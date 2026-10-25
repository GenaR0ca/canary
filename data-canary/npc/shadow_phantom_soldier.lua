-- Mubia Online: Shadow Phantom Soldier, en cada salida de la ciudad. Al hablarle te da el buff de defensa y daño (30 minutos).

local npcType = Game.createNpcType("Shadow Phantom Soldier")
local npcConfig = {}

npcConfig.outfit = {
	lookType = 1725, -- Celestial Avenger (female): red/gold armour with wings
	lookHead = 94,
	lookBody = 79,
	lookLegs = 94,
	lookFeet = 79,
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
