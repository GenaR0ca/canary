-- Mubia Online: Chaos Goblin, regala (gratis mientras probamos) las joyas de MU y las alas de cada clase.

local npcType = Game.createNpcType("Chaos Goblin")
local npcConfig = {}

npcConfig.outfit = {
	lookType = 61,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerShopNpc(npcType, npcConfig, {
	shop = {
		{ itemName = "jewel of bless", clientId = Mubia.JEWEL_OF_BLESS, buy = 0 },
		{ itemName = "jewel of soul", clientId = Mubia.JEWEL_OF_SOUL, buy = 0 },
		{ itemName = "jewel of life", clientId = Mubia.JEWEL_OF_LIFE, buy = 0 },
		{ itemName = "wings of satan", clientId = 60401, buy = 0 },
		{ itemName = "wings of heaven", clientId = 60402, buy = 0 },
		{ itemName = "wings of elf", clientId = 60403, buy = 0 },
		{ itemName = "wings of dragon", clientId = 60404, buy = 0 },
		{ itemName = "wings of soul", clientId = 60405, buy = 0 },
		{ itemName = "wings of spirits", clientId = 60406, buy = 0 },
		{ itemName = "wings of storm", clientId = 60407, buy = 0 },
		{ itemName = "wings of eternal", clientId = 60408, buy = 0 },
		{ itemName = "wings of illusion", clientId = 60409, buy = 0 },
	},
	greeting = "¡Hola |PLAYERNAME|! Tengo Jewels of Bless, Soul y Life y alas para cada clase. Di {trade}, todo es gratis.",
	voice = "¡Joyas y alas gratis! Di {trade}.",
})
