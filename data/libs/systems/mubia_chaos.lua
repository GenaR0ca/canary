-- Mubia Online: Chaos Machine del Chaos Goblin (como en MU Online Season 6).
-- El jugador arrastra items de su inventario a la ventana de la máquina (cliente, opcode 83).
-- El servidor reconoce la receta por los items que hay, calcula el % de éxito y el costo en zen,
-- y al combinar cobra el zen, tira el dado y entrega el resultado. Si falla, los items se pierden.
-- Los items quedan en el inventario del jugador mientras están en la máquina: el cliente solo
-- manda dónde está cada uno (contenedor y lugar) y el servidor lo vuelve a comprobar al combinar.

Mubia.CHAOS_OPCODE = 83

Mubia.JEWEL_OF_CREATION = 60305
Mubia.LOCHS_FEATHER = 60306
Mubia.FEATHER_OF_CONDOR = 60307
Mubia.FLAME_OF_CONDOR = 60308

-- Paquetes de joyas: id = { joya, cantidad }
Mubia.JewelBundles = {
	[60309] = { jewel = Mubia.JEWEL_OF_BLESS, amount = 10 },
	[60310] = { jewel = Mubia.JEWEL_OF_BLESS, amount = 20 },
	[60311] = { jewel = Mubia.JEWEL_OF_BLESS, amount = 30 },
	[60312] = { jewel = Mubia.JEWEL_OF_SOUL, amount = 10 },
	[60313] = { jewel = Mubia.JEWEL_OF_SOUL, amount = 20 },
	[60314] = { jewel = Mubia.JEWEL_OF_SOUL, amount = 30 },
}

-- Fruits: id = stat que suben
Mubia.Fruits = {
	[60315] = "str",
	[60316] = "agi",
	[60317] = "vit",
	[60318] = "ene",
}

-- Armas Chaos (las tres salen de la receta Chaos Weapon, al azar)
Mubia.ChaosWeapons = { 62025, 62044, 62062 } -- Chaos Dragon Axe, Chaos Nature Bow, Chaos Lightning Staff

Mubia.ChaosConfig = {
	maxDistance = 4, -- hay que estar a esta distancia del Chaos Goblin para combinar
	-- Chaos Weapon: Jewel of Chaos + items de MU (+4 o más con opción). Bless y Soul suben el %.
	weapon = { minLevel = 4, minOption = 1, maxRate = 100, zenPerRate = 10000 },
	-- Alas de 1ra: arma Chaos + Jewel of Chaos (+ items de MU, Bless y Soul para subir el %)
	wings1 = { baseRate = 20, maxRate = 100, zenPerRate = 10000 },
	-- Alas de 2da: alas de 1ra + Loch's Feather + Jewel of Chaos (+ items de MU para subir el %)
	wings2 = { baseRate = 10, maxRate = 90, zen = 5000000 },
	-- Feather of Condor: alas de 2da +9 o más con opción + Jewel of Chaos + Jewel of Creation + 1 paquete de Bless + 1 de Soul
	condor = { minLevel = 9, minOption = 1, baseRate = 10, maxRate = 60, zenPerRate = 200000 },
	-- Alas de 3ra: Feather of Condor + Flame of Condor + Jewel of Chaos + Jewel of Creation + 1 paquete de Bless + 1 de Soul
	-- (items de MU +9 o más suben el %)
	wings3 = { baseRate = 20, maxRate = 60, zenPerRate = 200000 },
	-- Subir de +9 a +15: el item + 1 Jewel of Chaos + N Jewels of Bless + N Jewels of Soul (N = 1 para +10, 2 para +11...)
	upgrade = {
		[10] = { rate = 60, zen = 2000000 },
		[11] = { rate = 60, zen = 4000000 },
		[12] = { rate = 55, zen = 6000000 },
		[13] = { rate = 55, zen = 8000000 },
		[14] = { rate = 50, zen = 10000000 },
		[15] = { rate = 50, zen = 12000000 },
	},
	-- Fruits: Jewel of Chaos + Jewel of Creation
	fruit = { rate = 90, zen = 3000000 },
	-- Paquetes de joyas: 10, 20 o 30 joyas iguales. Desarmar un paquete cuesta unbundleZen.
	bundleZen = { [10] = 500000, [20] = 1000000, [30] = 1500000 },
	unbundleZen = 1000000,
	-- Puntos que da una Fruit (al azar) y máximo de puntos de Fruits por personaje
	fruitMin = 1,
	fruitMax = 3,
	fruitMaxTotal = 200,
	-- Cuánto suma al % cada item de MU extra: nivel x levelRate + opción x optionRate; cada joya suma su %
	levelRate = 3,
	optionRate = 2,
	blessRate = 5,
	soulRate = 4,
}

-- Lista de recetas para la ayuda de la ventana del cliente
Mubia.ChaosRecipes = {
	"Chaos Weapon: Jewel of Chaos + items de MU +4 o más con opción (Bless y Soul suben el %). Hasta 100%.",
	"Alas de 1ra: arma Chaos + Jewel of Chaos (items, Bless y Soul suben el %). Hasta 100%.",
	"Alas de 2da: alas de 1ra + Loch's Feather + Jewel of Chaos (items suben el %). Hasta 90%. 5.000.000 zen.",
	"Feather of Condor: alas de 2da +9 con opción + Jewel of Chaos + Jewel of Creation + paquete de Bless + paquete de Soul. Hasta 60%.",
	"Alas de 3ra: Feather of Condor + Flame of Condor + Jewel of Chaos + Jewel of Creation + paquete de Bless + paquete de Soul. Hasta 60%.",
	"Item +10 a +15: item +9 a +14 + Jewel of Chaos + 1 Bless y 1 Soul por cada nivel sobre +9 (+10 = 1 y 1, +15 = 6 y 6). 60% a 50%.",
	"Fruit: Jewel of Chaos + Jewel of Creation. 90%. 3.000.000 zen.",
	"Paquete: 10, 20 o 30 Jewels of Bless (o de Soul) solas. 100%. Un paquete solo se vuelve a desarmar.",
	"Si la combinación falla, los items se pierden (como en MU).",
}

-- Dónde abrió cada jugador la máquina (posición del Chaos Goblin)
Mubia.ChaosOpen = Mubia.ChaosOpen or {}

local function jsonString(text)
	text = Mubia.toLatin1(text)
	return '"' .. text:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n") .. '"'
end

local function send(player, action, fields)
	if not player:isUsingOtClient() then
		return
	end
	local parts = { '"action":"' .. action .. '"' }
	for key, value in pairs(fields or {}) do
		if type(value) == "string" then
			parts[#parts + 1] = string.format('"%s":%s', key, jsonString(value))
		elseif type(value) == "boolean" then
			parts[#parts + 1] = string.format('"%s":%s', key, value and "true" or "false")
		elseif type(value) == "table" then
			local list = {}
			for _, text in ipairs(value) do
				list[#list + 1] = jsonString(text)
			end
			parts[#parts + 1] = string.format('"%s":[%s]', key, table.concat(list, ","))
		else
			parts[#parts + 1] = string.format('"%s":%d', key, value)
		end
	end
	player:sendExtendedOpcode(Mubia.CHAOS_OPCODE, "{" .. table.concat(parts, ",") .. "}")
end

function Mubia.openChaosMachine(player, npc)
	Mubia.ChaosOpen[player:getId()] = npc:getPosition()
	send(player, "open", { zen = Mubia.getZen(player), recipes = Mubia.ChaosRecipes })
end

function Mubia.closeChaosMachine(player)
	Mubia.ChaosOpen[player:getId()] = nil
end

local function nearGoblin(player)
	local pos = Mubia.ChaosOpen[player:getId()]
	if not pos then
		return false
	end
	local playerPos = player:getPosition()
	local distance = Mubia.ChaosConfig.maxDistance
	return playerPos.z == pos.z and math.abs(playerPos.x - pos.x) <= distance and math.abs(playerPos.y - pos.y) <= distance
end

local function formatZen(amount)
	local text = tostring(amount)
	while true do
		local replaced
		text, replaced = text:gsub("^(%d+)(%d%d%d)", "%1.%2")
		if replaced == 0 then
			return text
		end
	end
end

-- Lee los items que manda el cliente: "c<contenedor>:<lugar>:<id>" o "e<slot>:<id>", separados por ";"
local function readItems(player, text)
	local entries, seen = {}, {}
	for ref in (text or ""):gmatch("[^;]+") do
		local item, itemId
		local cid, slot, id = ref:match("^c(%d+):(%d+):(%d+)$")
		if cid then
			local container = player:getContainerById(tonumber(cid))
			item = container and container:getItem(tonumber(slot))
			itemId = tonumber(id)
		else
			slot, id = ref:match("^e(%d+):(%d+)$")
			if slot then
				item = player:getSlotItem(tonumber(slot))
				itemId = tonumber(id)
			end
		end
		if not item or item:getId() ~= itemId then
			return nil, "Un item de la máquina ya no está en tu inventario. Sacalo y volvé a ponerlo."
		end
		local top = item:getTopParent()
		if not top or not top:isCreature() or top:getId() ~= player:getId() then
			return nil, "Solo puedes usar items de tu inventario."
		end
		if seen[ref] then
			return nil, "Pusiste el mismo item dos veces."
		end
		seen[ref] = true
		entries[#entries + 1] = {
			item = item,
			id = itemId,
			count = item:getCount(),
			kind = Mubia.getItemKind(item),
			level = Mubia.getItemLevel(item),
			option = Mubia.getItemOption(item),
		}
	end
	return entries
end

-- "jewel of bless" -> "Jewel Of Bless" -> "Jewel of Bless"
local function itemName(id)
	local name = ItemType(id):getName():gsub("(%a)([%w']*)", function(first, rest)
		return first:upper() .. rest
	end)
	return (name:gsub(" Of ", " of "))
end

local function isChaosWeapon(id)
	return table.contains(Mubia.ChaosWeapons, id)
end

local function wingTier(entry)
	local wing = Mubia.Wings[entry.id]
	return wing and wing.tier or nil
end

local function wingsOfTier(tier)
	local ids = {}
	for id, wing in pairs(Mubia.Wings) do
		if wing.tier == tier then
			ids[#ids + 1] = id
		end
	end
	table.sort(ids)
	return ids
end

-- Agrupa los items de la máquina por tipo
local function classify(entries)
	local groups = { jewels = {}, bundles = {}, chaosWeapons = {}, wings = { {}, {}, {} }, gear = {}, unknown = {} }
	for _, entry in ipairs(entries) do
		local id = entry.id
		if id == Mubia.JEWEL_OF_CHAOS or id == Mubia.JEWEL_OF_BLESS or id == Mubia.JEWEL_OF_SOUL or id == Mubia.JEWEL_OF_CREATION or id == Mubia.LOCHS_FEATHER or id == Mubia.FEATHER_OF_CONDOR or id == Mubia.FLAME_OF_CONDOR then
			groups.jewels[id] = (groups.jewels[id] or 0) + entry.count
		elseif Mubia.JewelBundles[id] then
			groups.bundles[#groups.bundles + 1] = entry
		elseif isChaosWeapon(id) then
			groups.chaosWeapons[#groups.chaosWeapons + 1] = entry
		elseif wingTier(entry) then
			table.insert(groups.wings[wingTier(entry)], entry)
		elseif entry.kind then
			groups.gear[#groups.gear + 1] = entry
		else
			groups.unknown[#groups.unknown + 1] = entry
		end
	end
	return groups
end

local function jewels(groups, id)
	return groups.jewels[id] or 0
end

local function onlyJewels(groups, allowed)
	for id, count in pairs(groups.jewels) do
		if count > 0 and not allowed[id] then
			return false
		end
	end
	return true
end

local function bundleCount(groups, jewel)
	local count = 0
	for _, entry in ipairs(groups.bundles) do
		if Mubia.JewelBundles[entry.id].jewel == jewel then
			count = count + 1
		end
	end
	return count
end

-- % que suman los items de MU extra (nivel y opción) y las joyas Bless/Soul
local function extraRate(list, minLevel)
	local config = Mubia.ChaosConfig
	local rate = 0
	for _, entry in ipairs(list) do
		if entry.level >= (minLevel or 0) then
			rate = rate + entry.level * config.levelRate + entry.option * config.optionRate
		end
	end
	return rate
end

local function jewelRate(groups)
	return jewels(groups, Mubia.JEWEL_OF_BLESS) * Mubia.ChaosConfig.blessRate + jewels(groups, Mubia.JEWEL_OF_SOUL) * Mubia.ChaosConfig.soulRate
end

local function clampRate(rate, maxRate)
	return math.max(1, math.min(maxRate, math.floor(rate)))
end

local function allEntries(entries)
	local consume = {}
	for _, entry in ipairs(entries) do
		consume[#consume + 1] = { entry = entry, count = entry.count }
	end
	return consume
end

-- Saca "amount" de una joya de las pilas de la máquina
local function takeJewel(entries, id, amount, consume)
	for _, entry in ipairs(entries) do
		if amount <= 0 then
			break
		end
		if entry.id == id then
			local take = math.min(amount, entry.count)
			consume[#consume + 1] = { entry = entry, count = take }
			amount = amount - take
		end
	end
	return consume
end

-- Reconoce la receta. Devuelve una tabla { name, rate, zen, consume, give(player) } o nil y el motivo.
function Mubia.findChaosRecipe(entries)
	local config = Mubia.ChaosConfig
	if #entries == 0 then
		return nil, "Arrastrá items de tu inventario a la máquina."
	end
	local groups = classify(entries)
	if #groups.unknown > 0 then
		return nil, string.format("%s no sirve en la Chaos Machine.", itemName(groups.unknown[1].id))
	end

	local chaos = jewels(groups, Mubia.JEWEL_OF_CHAOS)
	local bless = jewels(groups, Mubia.JEWEL_OF_BLESS)
	local soul = jewels(groups, Mubia.JEWEL_OF_SOUL)
	local creation = jewels(groups, Mubia.JEWEL_OF_CREATION)
	local loch = jewels(groups, Mubia.LOCHS_FEATHER)
	local feather = jewels(groups, Mubia.FEATHER_OF_CONDOR)
	local flame = jewels(groups, Mubia.FLAME_OF_CONDOR)
	local wings1, wings2, wings3 = groups.wings[1], groups.wings[2], groups.wings[3]
	local items = #groups.gear + #groups.chaosWeapons + #wings1 + #wings2 + #wings3

	-- Paquetes de joyas: 10, 20 o 30 Bless (o Soul) solas
	if items == 0 and #groups.bundles == 0 and (bless > 0 or soul > 0) and onlyJewels(groups, { [Mubia.JEWEL_OF_BLESS] = true, [Mubia.JEWEL_OF_SOUL] = true }) then
		if bless > 0 and soul > 0 then
			return nil, "Para hacer un paquete poné solo Jewels of Bless o solo Jewels of Soul."
		end
		local jewel = bless > 0 and Mubia.JEWEL_OF_BLESS or Mubia.JEWEL_OF_SOUL
		local total = math.max(bless, soul)
		local size = total >= 30 and 30 or total >= 20 and 20 or total >= 10 and 10 or nil
		if not size then
			return nil, "Para hacer un paquete necesitás 10, 20 o 30 joyas."
		end
		local bundleId
		for id, bundle in pairs(Mubia.JewelBundles) do
			if bundle.jewel == jewel and bundle.amount == size then
				bundleId = id
			end
		end
		return {
			name = string.format("Paquete de %d %s", size, itemName(jewel)),
			rate = 100,
			zen = config.bundleZen[size],
			consume = takeJewel(entries, jewel, size, {}),
			result = function()
				return bundleId, 1
			end,
		}
	end

	-- Desarmar un paquete
	if #entries == 1 and #groups.bundles == 1 then
		local bundle = Mubia.JewelBundles[groups.bundles[1].id]
		return {
			name = string.format("Desarmar paquete (%d %s)", bundle.amount, itemName(bundle.jewel)),
			rate = 100,
			zen = config.unbundleZen,
			consume = allEntries(entries),
			result = function()
				return bundle.jewel, bundle.amount
			end,
		}
	end

	-- Subir un item de +9..+14 a +10..+15
	local upgradeList = {}
	for _, list in ipairs({ groups.gear, groups.chaosWeapons, wings1, wings2, wings3 }) do
		for _, entry in ipairs(list) do
			upgradeList[#upgradeList + 1] = entry
		end
	end
	if items == 1 and #groups.bundles == 0 and chaos >= 1 and upgradeList[1].level >= 9 and onlyJewels(groups, { [Mubia.JEWEL_OF_CHAOS] = true, [Mubia.JEWEL_OF_BLESS] = true, [Mubia.JEWEL_OF_SOUL] = true }) then
		local target = upgradeList[1]
		local nextLevel = target.level + 1
		local upgrade = config.upgrade[nextLevel]
		if not upgrade then
			return nil, string.format("Este item ya está en +%d, el máximo.", target.level)
		end
		local need = nextLevel - 9
		if bless < need or soul < need then
			return nil, string.format("Para +%d necesitás 1 Jewel of Chaos, %d Jewel of Bless y %d Jewel of Soul.", nextLevel, need, need)
		end
		local consume = { { entry = target, count = 1 } }
		takeJewel(entries, Mubia.JEWEL_OF_CHAOS, 1, consume)
		takeJewel(entries, Mubia.JEWEL_OF_BLESS, need, consume)
		takeJewel(entries, Mubia.JEWEL_OF_SOUL, need, consume)
		return {
			name = string.format("Item +%d", nextLevel),
			-- Luck: +25% de éxito (como en MU, hasta 75%)
			rate = Mubia.hasLuck(target.item) and math.min(75, upgrade.rate + Mubia.ExcellentConfig.luckSuccessRate) or upgrade.rate,
			zen = upgrade.zen,
			consume = consume,
			keepItem = target, -- si sale bien el item se queda, con un nivel más
			upgradeTo = nextLevel,
		}
	end

	-- Fruit: Jewel of Chaos + Jewel of Creation
	if items == 0 and #groups.bundles == 0 and chaos >= 1 and creation >= 1 and onlyJewels(groups, { [Mubia.JEWEL_OF_CHAOS] = true, [Mubia.JEWEL_OF_CREATION] = true }) then
		local consume = takeJewel(entries, Mubia.JEWEL_OF_CHAOS, 1, {})
		takeJewel(entries, Mubia.JEWEL_OF_CREATION, 1, consume)
		return {
			name = "Fruit",
			rate = config.fruit.rate,
			zen = config.fruit.zen,
			consume = consume,
			result = function()
				local ids = {}
				for id in pairs(Mubia.Fruits) do
					ids[#ids + 1] = id
				end
				table.sort(ids)
				return ids[math.random(#ids)], 1
			end,
		}
	end

	-- Alas de 3ra
	if feather >= 1 or flame >= 1 then
		if feather < 1 or flame < 1 or chaos < 1 or creation < 1 or bundleCount(groups, Mubia.JEWEL_OF_BLESS) < 1 or bundleCount(groups, Mubia.JEWEL_OF_SOUL) < 1 then
			return nil, "Alas de 3ra: Feather of Condor + Flame of Condor + Jewel of Chaos + Jewel of Creation + paquete de Bless + paquete de Soul."
		end
		local extras = {}
		for _, list in ipairs({ groups.gear, wings1, wings2, wings3, groups.chaosWeapons }) do
			for _, entry in ipairs(list) do
				extras[#extras + 1] = entry
			end
		end
		local rate = config.wings3.baseRate + extraRate(extras, 9)
		rate = clampRate(rate, config.wings3.maxRate)
		return {
			name = "Alas de 3ra generación",
			rate = rate,
			zen = rate * config.wings3.zenPerRate,
			consume = allEntries(entries),
			result = function()
				local ids = wingsOfTier(3)
				return ids[math.random(#ids)], 1
			end,
		}
	end

	-- Feather of Condor
	if #wings2 >= 1 and creation >= 1 then
		local wing = wings2[1]
		if #wings2 > 1 or chaos < 1 or bundleCount(groups, Mubia.JEWEL_OF_BLESS) < 1 or bundleCount(groups, Mubia.JEWEL_OF_SOUL) < 1 then
			return nil, "Feather of Condor: unas alas de 2da +9 con opción + Jewel of Chaos + Jewel of Creation + paquete de Bless + paquete de Soul."
		end
		if wing.level < config.condor.minLevel or wing.option < config.condor.minOption then
			return nil, string.format("Para la Feather of Condor las alas de 2da tienen que ser +%d o más y tener opción adicional.", config.condor.minLevel)
		end
		local extras = {}
		for _, list in ipairs({ groups.gear, wings1, wings3, groups.chaosWeapons }) do
			for _, entry in ipairs(list) do
				extras[#extras + 1] = entry
			end
		end
		local rate = config.condor.baseRate + (wing.level - 9) * 5 + wing.option * config.optionRate + extraRate(extras, 9)
		rate = clampRate(rate, config.condor.maxRate)
		return {
			name = "Feather of Condor",
			rate = rate,
			zen = rate * config.condor.zenPerRate,
			consume = allEntries(entries),
			result = function()
				return Mubia.FEATHER_OF_CONDOR, 1
			end,
		}
	end

	-- Alas de 2da
	if loch >= 1 then
		if #wings1 ~= 1 or chaos < 1 then
			return nil, "Alas de 2da: unas alas de 1ra + Loch's Feather + Jewel of Chaos."
		end
		local wing = wings1[1]
		local extras = {}
		for _, list in ipairs({ groups.gear, groups.chaosWeapons, wings2, wings3 }) do
			for _, entry in ipairs(list) do
				extras[#extras + 1] = entry
			end
		end
		local rate = config.wings2.baseRate + wing.level * config.levelRate + wing.option * config.optionRate + extraRate(extras) + jewelRate(groups)
		return {
			name = "Alas de 2da generación",
			rate = clampRate(rate, config.wings2.maxRate),
			zen = config.wings2.zen,
			consume = allEntries(entries),
			result = function()
				local ids = wingsOfTier(2)
				return ids[math.random(#ids)], 1
			end,
		}
	end

	if chaos < 1 then
		return nil, "Falta la Jewel of Chaos (o esa combinación no existe)."
	end

	-- Alas de 1ra: arma Chaos + Jewel of Chaos
	if #groups.chaosWeapons >= 1 and creation == 0 and #groups.bundles == 0 then
		local extras = {}
		for _, list in ipairs({ groups.gear, groups.chaosWeapons, wings1, wings2, wings3 }) do
			for _, entry in ipairs(list) do
				extras[#extras + 1] = entry
			end
		end
		local rate = config.wings1.baseRate + extraRate(extras) + jewelRate(groups)
		rate = clampRate(rate, config.wings1.maxRate)
		return {
			name = "Alas de 1ra generación",
			rate = rate,
			zen = rate * config.wings1.zenPerRate,
			consume = allEntries(entries),
			result = function()
				local ids = wingsOfTier(1)
				return ids[math.random(#ids)], 1
			end,
		}
	end

	-- Chaos Weapon: items de MU +4 o más con opción
	if #groups.gear >= 1 and creation == 0 and #groups.bundles == 0 and items == #groups.gear then
		local valid = false
		for _, entry in ipairs(groups.gear) do
			if entry.level >= config.weapon.minLevel and entry.option >= config.weapon.minOption then
				valid = true
			end
		end
		if not valid then
			return nil, string.format("Para el arma Chaos necesitás al menos un item de MU +%d o más con opción adicional (Jewel of Life).", config.weapon.minLevel)
		end
		local rate = extraRate(groups.gear) + jewelRate(groups)
		rate = clampRate(rate, config.weapon.maxRate)
		return {
			name = "Chaos Weapon",
			rate = rate,
			zen = rate * config.weapon.zenPerRate,
			consume = allEntries(entries),
			result = function()
				return Mubia.ChaosWeapons[math.random(#Mubia.ChaosWeapons)], 1
			end,
		}
	end

	return nil, "Esa combinación no existe. Mirá las recetas en la ayuda (?)."
end

local function preview(player, entries)
	local recipe, reason = Mubia.findChaosRecipe(entries)
	if not recipe then
		send(player, "preview", { ok = false, text = reason, zen = Mubia.getZen(player) })
		return nil
	end
	send(player, "preview", { ok = true, recipe = recipe.name, rate = recipe.rate, cost = recipe.zen, zen = Mubia.getZen(player), text = string.format("%s: %d%% de éxito, %s zen.", recipe.name, recipe.rate, formatZen(recipe.zen)) })
	return recipe
end

function Mubia.chaosPreview(player, text)
	local entries, reason = readItems(player, text)
	if not entries then
		send(player, "preview", { ok = false, text = reason, zen = Mubia.getZen(player) })
		return
	end
	preview(player, entries)
end

function Mubia.chaosMix(player, text)
	if not nearGoblin(player) then
		send(player, "result", { success = false, text = "Estás lejos del Chaos Goblin. Hablale de nuevo para usar la máquina." })
		return
	end
	local entries, reason = readItems(player, text)
	if not entries then
		send(player, "preview", { ok = false, text = reason, zen = Mubia.getZen(player) })
		return
	end
	local recipe = preview(player, entries)
	if not recipe then
		return
	end
	if Mubia.getZen(player) < recipe.zen then
		send(player, "result", { success = false, keep = true, text = string.format("Te falta zen: la combinación cuesta %s y tenés %s.", formatZen(recipe.zen), formatZen(Mubia.getZen(player))) })
		return
	end

	player:setBankBalance(player:getBankBalance() - recipe.zen)
	Mubia.sendZen(player)

	local success = math.random(100) <= recipe.rate
	-- se sacan los items (si sale bien y es una mejora, el item se queda)
	for _, use in ipairs(recipe.consume) do
		if not (success and use.entry == recipe.keepItem) then
			use.entry.item:remove(use.count)
		end
	end

	local resultId, resultCount, resultLevel
	if success then
		if recipe.keepItem then
			Mubia.setItemLevel(recipe.keepItem.item, recipe.upgradeTo)
			resultId, resultCount, resultLevel = recipe.keepItem.id, 1, recipe.upgradeTo
		else
			resultId, resultCount = recipe.result()
			local created = player:addItem(resultId, resultCount)
			-- alas y armas nuevas: Luck y opciones al azar
			if created and resultCount == 1 then
				Mubia.rollItemOptions(created)
			end
		end
		player:getPosition():sendMagicEffect(CONST_ME_FIREWORK_YELLOW)
	else
		player:getPosition():sendMagicEffect(CONST_ME_POFF)
	end

	local text
	if success then
		local name = itemName(resultId)
		if resultLevel then
			name = string.format("%s +%d", name, resultLevel)
		elseif resultCount > 1 then
			name = string.format("%d x %s", resultCount, name)
		end
		text = string.format("¡Éxito! (%d%%) Recibiste: %s.", recipe.rate, name)
	else
		text = string.format("La combinación falló (%d%% de éxito). Los items se perdieron.", recipe.rate)
	end
	Mubia.sendMessage(player, success and MESSAGE_EVENT_ADVANCE or MESSAGE_FAILURE, text)
	send(player, "result", { success = success, text = text, item = resultId or 0, count = resultCount or 0, zen = Mubia.getZen(player) })
	Mubia.sendStats(player)
end

-- Fruits: suman puntos a un stat (con un máximo por personaje)
function Mubia.useFruit(player, item)
	local stat = Mubia.Fruits[item:getId()]
	if not stat or not Mubia.getClass(player) then
		return false
	end
	local config = Mubia.ChaosConfig
	local store = player:kv():scoped("mubia")
	local used = store:get("fruitPoints") or 0
	if used >= config.fruitMaxTotal then
		Mubia.sendMessage(player, MESSAGE_FAILURE, string.format("Ya llegaste al máximo de puntos de Fruits (%d).", config.fruitMaxTotal))
		return true
	end
	local stats = Mubia.getStats(player)
	local amount = math.min(math.random(config.fruitMin, config.fruitMax), config.fruitMaxTotal - used, Mubia.Config.maxStat - stats[stat])
	if amount <= 0 then
		Mubia.sendMessage(player, MESSAGE_FAILURE, string.format("%s ya está en el máximo.", Mubia.STAT_NAMES[stat]))
		return true
	end
	stats[stat] = stats[stat] + amount
	Mubia.saveStats(player, stats)
	store:set("fruitPoints", used + amount)
	item:remove(1)
	Mubia.recalc(player)
	Mubia.sendStats(player)
	player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
	Mubia.sendMessage(player, MESSAGE_EVENT_ADVANCE, string.format("%s +%d (ahora %d). Puntos de Fruits usados: %d de %d.", Mubia.STAT_NAMES[stat], amount, stats[stat], used + amount, config.fruitMaxTotal))
	return true
end
