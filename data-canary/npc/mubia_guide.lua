-- Mubia Online: NPC del templo que regala los items custom (Mubia.GiftItems) para probar.
local npcName = "Mubia Guide"

local npcType = Game.createNpcType(npcName)
local npcConfig = {}

npcConfig.name = npcName
npcConfig.description = npcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 0
npcConfig.walkRadius = 0

npcConfig.outfit = {
	lookType = 130,
	lookHead = 0,
	lookBody = 94,
	lookLegs = 94,
	lookFeet = 0,
	lookAddons = 3,
}

npcConfig.voices = {
	interval = 15000,
	chance = 20,
	{ text = Mubia.toLatin1("¡Pide tus {regalos} aquí!") },
}

npcConfig.flags = {
	floorchange = false,
}

-- Tienda gratis (escribir "trade"): items custom de Mubia + pociones, todo a precio 0
npcConfig.shop = {
	{ itemName = "health potion", clientId = 266, buy = 0 },
	{ itemName = "mana potion", clientId = 268, buy = 0 },
}
for _, gift in ipairs(Mubia.GiftItems) do
	table.insert(npcConfig.shop, { itemName = ItemType(gift.id):getName(), clientId = gift.id, buy = 0 })
end

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)

npcType.onThink = function(npc, interval)
	npcHandler:onThink(npc, interval)
end

npcType.onAppear = function(npc, creature)
	npcHandler:onAppear(npc, creature)
end

npcType.onDisappear = function(npc, creature)
	npcHandler:onDisappear(npc, creature)
end

npcType.onMove = function(npc, creature, fromPosition, toPosition)
	npcHandler:onMove(npc, creature, fromPosition, toPosition)
end

npcType.onSay = function(npc, creature, type, message)
	npcHandler:onSay(npc, creature, type, message)
end

npcType.onCloseChannel = function(npc, player)
	npcHandler:onCloseChannel(npc, player)
end

npcType.onBuyItem = function(npc, player, itemId, subType, amount, ignore, inBackpacks, totalCost)
	npc:sellItem(player, itemId, amount, subType, 0, ignore, inBackpacks)
end

npcType.onSellItem = function(npc, player, itemId, subtype, amount, ignore, name, totalCost) end

npcType.onCheckItem = function(npc, player, clientId, subType) end

local function giveGifts(npc, player)
	local names = {}
	for _, gift in ipairs(Mubia.GiftItems) do
		local item = player:addItem(gift.id, gift.count)
		if not item then
			npcHandler:say(Mubia.toLatin1("No tienes espacio o capacidad para más items."), npc, player)
			break
		end
		table.insert(names, ItemType(gift.id):getName())
	end
	if #names > 0 then
		player:getPosition():sendMagicEffect(CONST_ME_GIFT_WRAPS)
		npcHandler:say(Mubia.toLatin1("Aquí tienes: " .. table.concat(names, ", ") .. "."), npc, player)
	end
end

local function greetCallback(npc, player)
	npcHandler:setMessage(MESSAGE_GREET, Mubia.toLatin1("¡Hola |PLAYERNAME|! Te regalo los items nuevos de Mubia. Di {regalos} para recibirlos o {trade} para elegir items y pociones gratis."))
	return true
end

local function creatureSayCallback(npc, player, type, msg)
	if not npcHandler:checkInteraction(npc, player) then
		return false
	end

	if MsgContains(msg, "regalos") or MsgContains(msg, "regalo") or MsgContains(msg, "items") then
		giveGifts(npc, player)
	end
	return true
end

npcHandler:setCallback(CALLBACK_GREET, greetCallback)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setMessage(MESSAGE_FAREWELL, Mubia.toLatin1("¡Suerte en tu aventura!"))
npcHandler:setMessage(MESSAGE_WALKAWAY, Mubia.toLatin1("¡Vuelve cuando quieras!"))

npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

npcType:register(npcConfig)
