-- Mubia Online: NPCs del templo. Uno por clase vende (gratis) los scrolls de sus magias
-- y Potion Girl Amy vende (gratis) las pociones. Todo a precio 0 mientras probamos.

local POTIONS = {
	{ itemName = "health potion", clientId = 266, buy = 0 },
	{ itemName = "strong health potion", clientId = 236, buy = 0 },
	{ itemName = "great health potion", clientId = 239, buy = 0 },
	{ itemName = "mana potion", clientId = 268, buy = 0 },
	{ itemName = "strong mana potion", clientId = 237, buy = 0 },
	{ itemName = "great mana potion", clientId = 238, buy = 0 },
}

local NPCS = {
	{
		name = "Hanzo the Blacksmith",
		classId = Mubia.CLASS_DK,
		outfit = { lookType = 131, lookHead = 95, lookBody = 95, lookLegs = 95, lookFeet = 95, lookAddons = 3 },
	},
	{
		name = "Pasi the Mage",
		classId = Mubia.CLASS_DW,
		outfit = { lookType = 130, lookHead = 0, lookBody = 88, lookLegs = 88, lookFeet = 0, lookAddons = 3 },
	},
	{
		name = "Elf Lala",
		classId = Mubia.CLASS_ELF,
		outfit = { lookType = 137, lookHead = 79, lookBody = 82, lookLegs = 82, lookFeet = 79, lookAddons = 3 },
	},
	{
		name = "Potion Girl Amy",
		outfit = { lookType = 136, lookHead = 78, lookBody = 94, lookLegs = 94, lookFeet = 78, lookAddons = 0 },
		shop = POTIONS,
	},
}

local function createNpc(config)
	local npcType = Game.createNpcType(config.name)
	local npcConfig = {}

	npcConfig.name = config.name
	npcConfig.description = config.name
	npcConfig.health = 100
	npcConfig.maxHealth = npcConfig.health
	npcConfig.walkInterval = 0
	npcConfig.walkRadius = 0
	npcConfig.outfit = config.outfit
	npcConfig.flags = { floorchange = false }

	local spells = config.classId and Mubia.getClassSpells(config.classId) or {}
	local className = config.classId and Mubia.Classes[config.classId].name

	npcConfig.shop = config.shop or {}
	for _, def in ipairs(spells) do
		table.insert(npcConfig.shop, { itemName = def.scrollName, clientId = def.scrollId, buy = 0 })
	end

	if className then
		npcConfig.voices = {
			interval = 15000,
			chance = 20,
			{ text = Mubia.toLatin1(string.format("¡Scrolls de magias de %s gratis! Di {trade}.", className)) },
		}
	else
		npcConfig.voices = {
			interval = 15000,
			chance = 20,
			{ text = Mubia.toLatin1("¡Pociones de vida y de mana gratis! Di {trade}.") },
		}
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

	-- Di "magias" para recibir todos los scrolls de la clase de una vez
	local function giveScrolls(npc, player)
		local names = {}
		for _, def in ipairs(spells) do
			if not player:addItem(def.scrollId, 1) then
				npcHandler:say(Mubia.toLatin1("No tienes espacio o capacidad para más items."), npc, player)
				break
			end
			names[#names + 1] = def.name
		end
		if #names > 0 then
			player:getPosition():sendMagicEffect(CONST_ME_GIFT_WRAPS)
			npcHandler:say(Mubia.toLatin1("Aquí tienes los scrolls de: " .. table.concat(names, ", ") .. "."), npc, player)
		end
	end

	local greeting
	if className then
		greeting = string.format("¡Hola |PLAYERNAME|! Enseño las magias de %s. Di {trade} para elegir scrolls gratis o {magias} para llevarte todos.", className)
	else
		greeting = "¡Hola |PLAYERNAME|! Di {trade} para llevarte pociones de vida y de mana gratis."
	end

	npcHandler:setCallback(CALLBACK_GREET, function(npc, player)
		npcHandler:setMessage(MESSAGE_GREET, Mubia.toLatin1(greeting))
		return true
	end)

	npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, function(npc, player, type, msg)
		if not npcHandler:checkInteraction(npc, player) then
			return false
		end
		if className and (MsgContains(msg, "magias") or MsgContains(msg, "scrolls")) then
			giveScrolls(npc, player)
		end
		return true
	end)

	npcHandler:setMessage(MESSAGE_FAREWELL, Mubia.toLatin1("¡Suerte en tu aventura!"))
	npcHandler:setMessage(MESSAGE_WALKAWAY, Mubia.toLatin1("¡Vuelve cuando quieras!"))
	npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

	npcType:register(npcConfig)
end

for _, config in ipairs(NPCS) do
	createNpc(config)
end
