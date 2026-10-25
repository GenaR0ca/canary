-- Mubia Online: qué vende cada NPC (como en MU Season 6). Todo a 0 zen mientras probamos.
-- Los NPC (data-canary/npc/) arman su tienda con Mubia.Shop(...) y la registran con Mubia.registerShopNpc.
-- Los items de equipo se venden con Luck (luck = true).

Mubia.SHOP_PRICE = 0 -- precio de compra de todo, por ahora

Mubia.ARROW = 3447 -- Arrow +3
Mubia.BOLT = 3446 -- Bolt +3
Mubia.AMMO_STACK = 255 -- cuántas flechas o bolts da cada compra

-- id de cada item de MU por nombre ("Leather Helm" -> 61001)
local gearByName = {}
for itemId, gear in pairs(Mubia.Gear) do
	gearByName[gear.name:lower()] = itemId
end

local PIECES = { helm = 1, armor = 2, pants = 3, gloves = 4, boots = 5 }

-- Las 5 piezas de un set ("Leather" -> casco, armadura, pantalón, guantes y botas)
local function setPieces(setName)
	local ids = {}
	for itemId, gear in pairs(Mubia.Gear) do
		if gear.set == setName then
			ids[#ids + 1] = itemId
		end
	end
	table.sort(ids, function(a, b)
		return (PIECES[Mubia.Gear[a].piece] or 9) < (PIECES[Mubia.Gear[b].piece] or 9)
	end)
	return ids
end

-- Arma la lista de la tienda. Cada parte es:
--   { sets = { "Leather", ... } }   sets completos de MU (con Luck)
--   { gear = { "Double Axe", ... } }   armas, bastones y escudos de MU (con Luck)
--   { items = { 266, ... } }   items comunes por id
--   { ammo = { Mubia.ARROW } }   flechas o bolts (cada compra da Mubia.AMMO_STACK)
--   { spells = Mubia.CLASS_DK }   todos los scrolls de magias de la clase
function Mubia.Shop(...)
	local shop = {}
	local function add(itemId, name, extra)
		local entry = { itemName = name, clientId = itemId, buy = Mubia.SHOP_PRICE }
		for key, value in pairs(extra or {}) do
			entry[key] = value
		end
		shop[#shop + 1] = entry
	end
	for _, part in ipairs({ ... }) do
		if part.spells then
			for _, def in ipairs(Mubia.getClassSpells(part.spells)) do
				add(def.scrollId, def.scrollName)
			end
		end
		for _, setName in ipairs(part.sets or {}) do
			for _, itemId in ipairs(setPieces(setName)) do
				add(itemId, Mubia.Gear[itemId].name:lower() .. " (luck)", { luck = true })
			end
		end
		for _, name in ipairs(part.gear or {}) do
			local itemId = gearByName[name:lower()]
			if itemId then
				add(itemId, name:lower() .. " (luck)", { luck = true })
			else
				logger.warn("[Mubia.Shop] no existe el item de MU '{}'", name)
			end
		end
		for _, itemId in ipairs(part.items or {}) do
			add(itemId, ItemType(itemId):getName())
		end
		for _, itemId in ipairs(part.ammo or {}) do
			add(itemId, string.format("%s (x%d)", ItemType(itemId):getName(), Mubia.AMMO_STACK), { stack = Mubia.AMMO_STACK })
		end
	end
	return shop
end

-- Lo que vende Lumen the Barmaid (y también Elf Lala y Wizard Izabel)
Mubia.ShopBarmaid = {
	items = {
		266,
		236,
		239, -- Small Healing Potion, Healing Potion, Large Healing Potion
		268,
		237,
		238, -- Small Mana Potion, Mana Potion, Large Mana Potion
		7644, -- Antidote
		60701, -- Ale
		60702, -- Olive of Love
		60631,
		60632,
		60633, -- Scroll of Archangel +1 a +3
		60641,
		60642,
		60643, -- Blood Bone +1 a +3
		60601,
		60602,
		60603, -- Devil's Eye +1 a +3
		60611,
		60612,
		60613, -- Devil's Key +1 a +3
	},
}

-- Antidote: quita todos los efectos negativos (veneno, fuego, rayo, sangrado, lentitud, borracho, maldición, frío, deslumbrado)
Mubia.NegativeConditions = {
	CONDITION_POISON,
	CONDITION_FIRE,
	CONDITION_ENERGY,
	CONDITION_BLEEDING,
	CONDITION_PARALYZE,
	CONDITION_DRUNK,
	CONDITION_CURSED,
	CONDITION_FREEZING,
	CONDITION_DAZZLED,
}

function Mubia.cleanse(player)
	for _, conditionType in ipairs(Mubia.NegativeConditions) do
		player:removeCondition(conditionType)
	end
end

-- Bebidas: velocidad de ataque y de magias un % más rápida por un rato (como +10 de velocidad en MU)
Mubia.Drinks = {
	[60701] = { name = "Ale", seconds = 80, percent = 10 },
	[60702] = { name = "Olive of Love", seconds = 180, percent = 10 },
}

-- Bebida activa de cada jugador, para el recuadro de buffs: Mubia.drinkBuffs[playerId] = { name, text, ends }
Mubia.drinkBuffs = Mubia.drinkBuffs or {}

function Mubia.drink(player, itemId)
	local drink = Mubia.Drinks[itemId]
	if not drink then
		return false
	end
	local playerId = player:getId()
	local ends = os.time() + drink.seconds
	Mubia.setBuff(player, "drinkSpeed", drink.percent, drink.seconds * 1000)
	Mubia.drinkBuffs[playerId] = {
		name = drink.name,
		text = string.format("+%d%% velocidad de ataque y magias", drink.percent),
		ends = ends,
	}
	Mubia.recalc(player)
	if Mubia.sendBuffs then
		Mubia.sendBuffs(player)
	end
	Mubia.sendMessage(player, MESSAGE_STATUS, string.format("%s: atacas y lanzas magias un %d%% más rápido por %d segundos.", drink.name, drink.percent, drink.seconds))

	-- al terminar vuelve la velocidad normal (si no tomó otra bebida mientras tanto)
	addEvent(function()
		local current = Mubia.drinkBuffs[playerId]
		if not current or current.ends ~= ends then
			return
		end
		Mubia.drinkBuffs[playerId] = nil
		local target = Player(playerId)
		if target then
			Mubia.recalc(target)
			if Mubia.sendBuffs then
				Mubia.sendBuffs(target)
			end
		end
	end, drink.seconds * 1000 + 100)
	return true
end

-- Vender a los NPC ---------------------------------------------------------------------------
-- Cualquier NPC con tienda compra cualquier item de tu bolsa (tecla I). El cliente pide la lista
-- y vende con el opcode 85 (data/scripts/mubia/npc_shop.lua). Si el item es valioso (+6 o más,
-- Excellent o una joya), el cliente pregunta antes de venderlo.

-- Zen que paga el NPC por cada joya (como en MU: un tercio de lo que vale)
Mubia.JewelSellPrices = {
	[60301] = 2000000, -- Jewel of Soul
	[60302] = 15000000, -- Jewel of Life
	[60303] = 3000000, -- Jewel of Bless
	[60304] = 270000, -- Jewel of Chaos
	[60305] = 12000000, -- Jewel of Creation
	[60309] = 30000000, -- Bless Bundle x10
	[60310] = 60000000, -- Bless Bundle x20
	[60311] = 90000000, -- Bless Bundle x30
	[60312] = 20000000, -- Soul Bundle x10
	[60313] = 40000000, -- Soul Bundle x20
	[60314] = 60000000, -- Soul Bundle x30
	[60319] = 6000000, -- Jewel of Harmony
	[60320] = 5000000, -- Jewel of Luck
	[60321] = 5000000, -- Jewel of Excellent
}

Mubia.VALUABLE_LEVEL = 6 -- desde +6 el NPC pregunta antes de comprarlo

function Mubia.isJewel(itemId)
	return Mubia.JewelSellPrices[itemId] ~= nil
end

function Mubia.isValuableItem(item)
	if Mubia.isJewel(item:getId()) then
		return true
	end
	if Mubia.getItemKind(item) then
		return Mubia.getItemLevel(item) >= Mubia.VALUABLE_LEVEL or (Mubia.isExcellent and Mubia.isExcellent(item)) or false
	end
	return false
end

-- Zen que paga el NPC por una unidad del item
function Mubia.getSellPrice(item)
	local itemId = item:getId()
	if Mubia.JewelSellPrices[itemId] then
		return Mubia.JewelSellPrices[itemId]
	end
	local wing = Mubia.Wings and Mubia.Wings[itemId]
	if wing then
		return 500000 * wing.tier * (1 + Mubia.getItemLevel(item))
	end
	local gear = Mubia.Gear[itemId]
	if gear then
		-- equipo de MU: según lo que pide (STR + AGI) y su nivel (+0 a +15)
		local level = Mubia.getItemLevel(item)
		local price = (gear.str + gear.agi) * 50 * (1 + level) ^ 2
		price = price * (1 + Mubia.getItemOption(item) / 40) -- opción adicional (Jewel of Life)
		if Mubia.hasLuck and Mubia.hasLuck(item) then
			price = price * 1.25
		end
		if Mubia.isExcellent and Mubia.isExcellent(item) then
			price = price * 3
		end
		return math.floor(price)
	end
	-- pociones, flechas, scrolls y demás
	return item:isStackable() and 10 or 100
end

local function jsonText(text)
	text = Mubia.toLatin1(tostring(text or ""))
	return '"' .. text:gsub('[%c"\\]', function(c)
		if c == '"' or c == "\\" then
			return "\\" .. c
		end
		return " "
	end) .. '"'
end

-- Los items de la bolsa (tecla I) que se pueden vender: { { slot, item }, ... }
function Mubia.getSellableItems(player)
	local list = {}
	local bag = player:getSlotItem(CONST_SLOT_BACKPACK)
	if not bag or not bag:isContainer() then
		return list
	end
	for slot = 0, bag:getSize() - 1 do
		local item = bag:getItem(slot)
		if item and not item:isContainer() then
			list[#list + 1] = { slot = slot, item = item }
		end
	end
	return list
end

-- Manda al cliente la lista de lo que puede vender (pestaña "Vender" de la tienda)
function Mubia.sendSellList(player)
	if not player:isUsingOtClient() then
		return
	end
	local entries = {}
	for _, entry in ipairs(Mubia.getSellableItems(player)) do
		local item = entry.item
		entries[#entries + 1] = string.format('{"slot":%d,"id":%d,"count":%d,"name":%s,"price":%d,"valuable":%s}', entry.slot, item:getId(), item:getCount(), jsonText(item:getName()), Mubia.getSellPrice(item), Mubia.isValuableItem(item) and "true" or "false")
	end
	player:sendExtendedOpcode(Mubia.NPC_SHOP_OPCODE or 85, '{"sell":[' .. table.concat(entries, ",") .. "]}")
end

-- Vende count unidades del item que está en la casilla slot de la bolsa.
-- confirmed: el jugador ya aceptó el aviso de item valioso.
function Mubia.sellFromBag(player, slot, itemId, count, confirmed)
	local bag = player:getSlotItem(CONST_SLOT_BACKPACK)
	local item = bag and bag:isContainer() and bag:getItem(slot)
	if not item or item:getId() ~= itemId or item:isContainer() then
		Mubia.sendMessage(player, MESSAGE_FAILURE, "Ese item ya no está en tu inventario.")
		Mubia.sendSellList(player)
		return false
	end
	if Mubia.isValuableItem(item) and not confirmed then
		Mubia.sendMessage(player, MESSAGE_FAILURE, "Ese item es valioso: confirma la venta.")
		return false
	end
	count = math.max(1, math.min(count, item:getCount()))
	local name = item:getName()
	local total = Mubia.getSellPrice(item) * count
	if not item:remove(count) then
		return false
	end
	if Mubia.addZen then
		Mubia.addZen(player, total)
	else
		player:setBankBalance(player:getBankBalance() + total)
	end
	local text = count > 1 and string.format("Vendiste %dx %s por %d zen.", count, name, total) or string.format("Vendiste %s por %d zen.", name, total)
	player:sendTextMessage(MESSAGE_TRADE, Mubia.toLatin1(text))
	Mubia.sendSellList(player)
	return true
end
