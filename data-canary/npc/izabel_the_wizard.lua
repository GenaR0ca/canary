-- Mubia Online: Izabel the Wizard (Devias), vende gratis pociones y los scrolls de magias de Dark Wizard.

local npcType = Game.createNpcType("Izabel the Wizard")
local npcConfig = {}

npcConfig.outfit = {
	lookType = 138,
	lookHead = 9,
	lookBody = 86,
	lookLegs = 86,
	lookFeet = 9,
	lookAddons = 2,
	lookMount = 0,
}

local shop = {}
for _, entry in ipairs(Mubia.NpcPotions) do
	shop[#shop + 1] = entry
end
for _, def in ipairs(Mubia.getClassSpells(Mubia.CLASS_DW)) do
	shop[#shop + 1] = { itemName = def.scrollName, clientId = def.scrollId, buy = 0 }
end

Mubia.registerShopNpc(npcType, npcConfig, {
	shop = shop,
	greeting = "Hola |PLAYERNAME|. Tengo pociones y scrolls de magias de Dark Wizard. Di {trade}, son gratis.",
	voice = "¡Pociones y scrolls de Dark Wizard gratis! Di {trade}.",
})
