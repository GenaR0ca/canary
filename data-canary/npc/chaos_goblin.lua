-- Mubia Online: Chaos Goblin, regala (gratis mientras probamos) las joyas de MU, las alas de cada clase y las mascotas.

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
		{ itemName = "jewel of chaos", clientId = Mubia.JEWEL_OF_CHAOS, buy = 0 },
		{ itemName = "wings of satan", clientId = 60401, buy = 0 },
		{ itemName = "wings of heaven", clientId = 60402, buy = 0 },
		{ itemName = "wings of elf", clientId = 60403, buy = 0 },
		{ itemName = "wings of dragon", clientId = 60404, buy = 0 },
		{ itemName = "wings of soul", clientId = 60405, buy = 0 },
		{ itemName = "wings of spirits", clientId = 60406, buy = 0 },
		{ itemName = "wings of storm", clientId = 60407, buy = 0 },
		{ itemName = "wings of eternal", clientId = 60408, buy = 0 },
		{ itemName = "wings of illusion", clientId = 60409, buy = 0 },
		{ itemName = "guardian angel", clientId = 60501, buy = 0 },
		{ itemName = "imp", clientId = 60502, buy = 0 },
		{ itemName = "horn of uniria", clientId = 60503, buy = 0 },
		{ itemName = "horn of dinorant", clientId = 60504, buy = 0 },
		{ itemName = "horn of fenrir", clientId = 60505, buy = 0 },
		{ itemName = "demon", clientId = 60506, buy = 0 },
		{ itemName = "spirit of guardian", clientId = 60507, buy = 0 },
		{ itemName = "pet skeleton", clientId = 60508, buy = 0 },
		{ itemName = "pet panda", clientId = 60509, buy = 0 },
		{ itemName = "dark horse", clientId = 60510, buy = 0 },
		{ itemName = "dark raven", clientId = 60511, buy = 0 },
		{ itemName = "black fenrir", clientId = 60512, buy = 0 },
		{ itemName = "blue fenrir", clientId = 60513, buy = 0 },
		{ itemName = "gold fenrir", clientId = 60514, buy = 0 },
		{ itemName = "pet rudolf", clientId = 60515, buy = 0 },
		{ itemName = "pet unicorn", clientId = 60516, buy = 0 },
	},
	greeting = "¡Hola |PLAYERNAME|! Tengo Jewels of Bless, Soul, Life y Chaos, alas para cada clase y mascotas. Di {trade}, todo es gratis.",
	voice = "¡Joyas, alas y mascotas gratis! Di {trade}.",
})
