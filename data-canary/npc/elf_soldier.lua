-- Mubia Online: Elf Soldier (Noria). Como en MU, al hablarle da gratis más defensa y más daño
-- a los personajes de nivel bajo. Lo que hace está en Mubia.ElfSoldier (data/scripts/mubia/npcs_mu.lua).

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
	greeting = "Hola |PLAYERNAME|. Protejo a los aventureros que recién empiezan. Di {buff} si necesitas mi bendición otra vez.",
	voice = "¡Aventureros de nivel 200 o menos! Hablen conmigo para recibir la bendición de las elfas.",
	onGreet = function(npc, player)
		Mubia.ElfSoldier.give(npc, player)
	end,
	keywords = {
		buff = function(npc, player)
			Mubia.ElfSoldier.give(npc, player)
		end,
		bendicion = function(npc, player)
			Mubia.ElfSoldier.give(npc, player)
		end,
	},
})
