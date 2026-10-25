-- Mubia Online: Elf Soldier, en cada salida de las ciudades. Como en MU, al hablarle da gratis
-- más defensa y más daño por 30 minutos. Lo que hace está en Mubia.ElfSoldier (data/scripts/mubia/npcs_mu.lua).

local npcType = Game.createNpcType("Elf Soldier")
local npcConfig = {}

npcConfig.outfit = {
	lookType = 129,
	lookHead = 79,
	lookBody = 82,
	lookLegs = 82,
	lookFeet = 79,
	lookAddons = 3,
	lookMount = 0,
}

Mubia.registerShopNpc(npcType, npcConfig, {
	shop = {},
	greeting = "Hola |PLAYERNAME|. Ten cuidado ahí afuera.",
	voice = "¡Aventurero! Háblame y te doy la bendición de las elfas.",
	onGreet = function(npc, player)
		Mubia.ElfSoldier.give(npc, player)
	end,
	keywords = {
		buff = function(npc, player)
			Mubia.ElfSoldier.give(npc, player)
		end,
	},
})
