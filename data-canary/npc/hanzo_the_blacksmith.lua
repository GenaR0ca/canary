-- Mubia Online: Hanzo the Blacksmith, herrero de Lorencia: magias de Dark Knight y equipo de DK con Luck, gratis.

local npcType = Game.createNpcType("Hanzo the Blacksmith")
local npcConfig = {}

npcConfig.outfit = {
	lookType = 131,
	lookHead = 95,
	lookBody = 95,
	lookLegs = 95,
	lookFeet = 95,
	lookAddons = 3,
	lookMount = 0,
}

Mubia.registerShopNpc(npcType, npcConfig, {
	classId = Mubia.CLASS_DK,
	shop = Mubia.Shop(
		{ spells = Mubia.CLASS_DK },
		{ sets = { "Leather", "Bronze", "Scale", "Brass" } },
		{ gear = { "Double Axe", "Tomahawk", "Falchion", "Serpent Sword", "Nikea Axe", "Berdysh", "Horn Shield", "Kite Shield", "Spiked Shield" } }
	),
	greeting = "¡Hola |PLAYERNAME|! Soy el herrero de Lorencia. Tengo las magias de Dark Knight y equipo con Luck. Di {trade}, todo es gratis.",
	voice = "¡Armas, sets y magias de Dark Knight! Di {trade}.",
})
