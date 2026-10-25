-- Mubia Online: Lahap. Como en MU, junta 10 Jewels of Bless o de Soul en un paquete y separa los paquetes.
-- Lo que hace está en Mubia.Lahap (data/scripts/mubia/npcs_mu.lua).

local npcType = Game.createNpcType("Lahap")
local npcConfig = {}

npcConfig.outfit = {
	lookType = 128,
	lookHead = 115,
	lookBody = 76,
	lookLegs = 57,
	lookFeet = 95,
	lookAddons = 1,
	lookMount = 0,
}

Mubia.registerShopNpc(npcType, npcConfig, {
	shop = {},
	greeting = "Hola |PLAYERNAME|. Junto tus joyas: di {juntar} y cada 10 Jewels of Bless o de Soul te doy un paquete. Di {separar} para desarmar tus paquetes.",
	voice = "¡Junto y separo paquetes de joyas! Di {juntar} o {separar}.",
	keywords = {
		juntar = function(npc, player)
			Mubia.Lahap.bundle(npc, player)
		end,
		separar = function(npc, player)
			Mubia.Lahap.unbundle(npc, player)
		end,
	},
})
