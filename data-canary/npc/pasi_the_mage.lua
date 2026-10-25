-- Mubia Online: Pasi the Mage, mago de Lorencia: magias de Dark Wizard y equipo de DW con Luck, gratis.

local npcType = Game.createNpcType("Pasi the Mage")
local npcConfig = {}

npcConfig.outfit = {
	lookType = 130,
	lookHead = 0,
	lookBody = 88,
	lookLegs = 88,
	lookFeet = 0,
	lookAddons = 3,
	lookMount = 0,
}

Mubia.registerShopNpc(npcType, npcConfig, {
	classId = Mubia.CLASS_DW,
	shop = Mubia.Shop(
		{ spells = Mubia.CLASS_DW },
		{ sets = { "Pad", "Bone" } },
		{ gear = { "Round Shield", "Buckler", "Skull Staff", "Angelic Staff", "Serpent Staff", "Thunder Staff" } }
	),
	greeting = "Hola |PLAYERNAME|. Enseño las magias de Dark Wizard y tengo bastones y sets con Luck. Di {trade}, todo es gratis.",
	voice = "¡Magias, bastones y sets de Dark Wizard! Di {trade}.",
})
