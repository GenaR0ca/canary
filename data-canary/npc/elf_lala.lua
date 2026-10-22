-- Mubia Online: Elf Lala, vende gratis los scrolls de magias de Fairy Elf.

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
})
