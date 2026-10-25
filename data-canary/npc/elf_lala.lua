-- Mubia Online: Elf Lala, elfa de Noria: magias de Fairy Elf, sets de elfa con Luck y lo mismo que Lumen, gratis.

local npcType = Game.createNpcType("Elf Lala")
local npcConfig = {}

npcConfig.outfit = {
	lookType = 137,
	lookHead = 79,
	lookBody = 82,
	lookLegs = 82,
	lookFeet = 79,
	lookAddons = 3,
	lookMount = 0,
}

Mubia.registerShopNpc(npcType, npcConfig, {
	classId = Mubia.CLASS_ELF,
	shop = Mubia.Shop(
		{ spells = Mubia.CLASS_ELF },
		{ sets = { "Vine", "Silk", "Wind" } },
		Mubia.ShopBarmaid
	),
	greeting = "¡Hola |PLAYERNAME|! Enseño las magias de Fairy Elf y tengo sets con Luck, pociones y entradas a los eventos. Di {trade}, todo es gratis.",
	voice = "¡Magias de elfa, sets y pociones! Di {trade}.",
})
