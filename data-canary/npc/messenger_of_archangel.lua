-- Mubia Online: Messenger of Archangel (Devias), la entrada a Blood Castle.
-- Al hablarle (o hacerle clic) abre la ventana para elegir el castillo, como en MU
-- (Mubia.openBloodCastleMenu en data/scripts/mubia/npcs_mu.lua; el evento está en data/libs/systems/mubia_blood_castle.lua).

local npcType = Game.createNpcType("Messenger of Archangel")
local npcConfig = {}

npcConfig.outfit = {
	lookType = 130,
	lookHead = 0,
	lookBody = 79,
	lookLegs = 0,
	lookFeet = 79,
	lookAddons = 1,
	lookMount = 0,
}

Mubia.registerShopNpc(npcType, npcConfig, {
	shop = {},
	greeting = "|PLAYERNAME|, el Archangel necesita tu ayuda. Elige tu castillo en la ventana. Si la cerraste, di {castillos}.",
	voice = "¡Los demonios robaron el arma del Archangel! Háblame para entrar al Blood Castle.",
	onGreet = function(npc, player)
		Mubia.openBloodCastleMenu(player)
	end,
	keywords = {
		castillos = function(npc, player)
			Mubia.openBloodCastleMenu(player)
		end,
		entrar = function(npc, player)
			Mubia.openBloodCastleMenu(player)
		end,
	},
})
