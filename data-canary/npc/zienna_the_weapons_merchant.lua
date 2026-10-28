-- Mubia Online: Zienna the Weapons Merchant (Devias), vende gratis las armas y escudos de MU de todas las clases.

local npcType = Game.createNpcType("Zienna the Weapons Merchant")
local npcConfig = {}

npcConfig.outfit = {
	lookType = 136,
	lookHead = 78,
	lookBody = 94,
	lookLegs = 114,
	lookFeet = 95,
	lookAddons = 1,
	lookMount = 0,
}

local shop = {}
local ids = {}
for itemId, gear in pairs(Mubia.Gear) do
	if gear.kind ~= "armor" then
		ids[#ids + 1] = itemId
	end
end
table.sort(ids)
for _, itemId in ipairs(ids) do
	shop[#shop + 1] = { itemName = Mubia.Gear[itemId].name:lower(), clientId = itemId, buy = 0 }
end

Mubia.registerShopNpc(npcType, npcConfig, {
	shop = shop,
	greeting = "¡Bienvenido a Devias, |PLAYERNAME|! Vendo armas y escudos para todas las clases. Di {trade}, son gratis.",
	voice = "¡Armas y escudos para todas las clases! Di {trade}.",
})
