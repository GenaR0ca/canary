-- Mubia Online: drops de los monstruos como en MU.
-- Al morir un monstruo de MU (los de Mubia.WildMonsters) se tiran los dados de:
--  * un item de MU (arma, set o escudo) de un nivel parecido al del monstruo, con +nivel, Luck,
--    opción adicional y, muy pocas veces, Excellent. Probabilidad: 10 / itemRate del Monster.txt.
--  * Jewels (Bless, Soul, Life y Chaos), más fáciles en monstruos de nivel alto.
--  * Zen: probabilidad 10 / moneyRate del Monster.txt, cantidad según el nivel del monstruo.
-- Los items caen al piso. Durante unos segundos solo los puede agarrar quien mató al monstruo
-- (o su party, si es la party la dueña del cuerpo); después cualquiera. Al rato desaparecen.

Mubia.DropConfig = {
	itemRateMultiplier = 1, -- 2 = el doble de items
	excellentChance = 0.1, -- % de que un item que cae sea Excellent (0.1 = 1 de cada 1000)
	itemLevelWindow = 20, -- el monstruo suelta items con nivel de drop entre (su nivel - esto) y su nivel
	-- Jewels: % por monstruo = nivel del monstruo * perLevel (desde minLevel), con un tope de maxChance
	jewels = {
		{ id = Mubia.JEWEL_OF_CHAOS, minLevel = 10, perLevel = 0.012, maxChance = 1.5 },
		{ id = Mubia.JEWEL_OF_BLESS, minLevel = 15, perLevel = 0.01, maxChance = 1.2 },
		{ id = Mubia.JEWEL_OF_SOUL, minLevel = 15, perLevel = 0.007, maxChance = 0.9 },
		{ id = Mubia.JEWEL_OF_LIFE, minLevel = 20, perLevel = 0.005, maxChance = 0.6 },
	},
	zenMultiplier = 1, -- 2 = el doble de zen
	-- Jefes: siempre sueltan esta cantidad de items y de jewels (al azar entre Bless, Soul, Life y Chaos)
	bosses = {
		["Ice Queen"] = { items = 3, jewels = 1 },
	},
	protectSeconds = 10, -- segundos en que solo el dueño puede agarrar lo que cayó
	vanishSeconds = 90, -- segundos hasta que desaparece lo que nadie agarró
}

local ATTR_OWNER = "muDropOwner"
local ATTR_UNTIL = "muDropUntil"
local ATTR_TOKEN = "muDropToken"

-- Nivel de drop de cada item, como el "Level" del Item.txt de MU:
-- armas y bastones = su daño mínimo, escudos = su defensa (libros = su % mágico),
-- piezas de set = 1.4 x la defensa de la armadura del set.
local function computeDropLevels()
	local armorDefense = {}
	for _, gear in pairs(Mubia.Gear) do
		if gear.kind == "armor" and gear.piece == "armor" then
			armorDefense[gear.set] = gear.defense
		end
	end
	local levels = {}
	for itemId, gear in pairs(Mubia.Gear) do
		local level
		if gear.kind == "weapon" or gear.kind == "staff" then
			level = gear.min or 1
		elseif gear.kind == "shield" then
			level = gear.defense or gear.magic or 1
		elseif gear.kind == "armor" then
			level = math.floor((armorDefense[gear.set] or gear.defense or 1) * 1.4)
		end
		if level then
			levels[#levels + 1] = { id = itemId, level = math.max(1, level, gear.level or 0) }
		end
	end
	table.sort(levels, function(a, b)
		return a.level < b.level or (a.level == b.level and a.id < b.id)
	end)
	return levels
end

function Mubia.getDropLevels()
	if not Mubia.dropLevels then
		Mubia.dropLevels = computeDropLevels()
	end
	return Mubia.dropLevels
end

-- Item que suelta un monstruo de ese nivel (o nil si no hay ninguno de su nivel)
function Mubia.pickDropItem(monsterLevel)
	local window = Mubia.DropConfig.itemLevelWindow
	local candidates = {}
	for _, entry in ipairs(Mubia.getDropLevels()) do
		if entry.level > monsterLevel then
			break
		end
		if entry.level >= monsterLevel - window then
			candidates[#candidates + 1] = entry
		end
	end
	if #candidates == 0 then
		return nil
	end
	return candidates[math.random(#candidates)]
end

-- +nivel al caer: hasta (nivel del monstruo - nivel del item) / 3, con el tope del Monster.txt
function Mubia.rollDropItemLevel(monsterLevel, itemLevel, maxItemLevel)
	local top = math.floor((monsterLevel - itemLevel) / 3)
	top = math.max(0, math.min(top, maxItemLevel or 6, 6))
	return math.random(0, top)
end

local function chance(percent)
	return math.random() * 100 < percent
end

-- Qué suelta este monstruo: lista de { id, count, level } y el zen
function Mubia.rollMonsterDrop(name)
	local mu = Mubia.WildMonsters[name]
	if not mu then
		return {}, 0
	end
	local config = Mubia.DropConfig
	local stats = Mubia.MonsterStats[name] or {}
	local drops = {}

	local itemRate = stats.itemRate or (100 + mu.level * 2)
	if itemRate > 0 and chance(1000 / itemRate * config.itemRateMultiplier) then
		local entry = Mubia.pickDropItem(mu.level)
		if entry then
			drops[#drops + 1] = { id = entry.id, count = 1, level = Mubia.rollDropItemLevel(mu.level, entry.level, stats.maxItemLevel) }
		end
	end

	for _, jewel in ipairs(config.jewels) do
		if mu.level >= jewel.minLevel and chance(math.min(jewel.maxChance, mu.level * jewel.perLevel)) then
			drops[#drops + 1] = { id = jewel.id, count = 1 }
		end
	end

	local boss = config.bosses[name]
	if boss then
		for _ = 1, boss.items or 0 do
			local entry = Mubia.pickDropItem(mu.level)
			if entry then
				drops[#drops + 1] = { id = entry.id, count = 1, level = Mubia.rollDropItemLevel(mu.level, entry.level, stats.maxItemLevel) }
			end
		end
		for _ = 1, boss.jewels or 0 do
			drops[#drops + 1] = { id = config.jewels[math.random(#config.jewels)].id, count = 1 }
		end
	end

	local zen = 0
	local moneyRate = stats.moneyRate or 10
	if moneyRate > 0 and chance(1000 / moneyRate) then
		local base = (mu.level + 25) * mu.level / 3
		zen = math.max(1, math.floor(base * (0.8 + math.random() * 0.4) * config.zenMultiplier))
	end
	return drops, zen
end

-- Pone el zen en el cuerpo como monedas (zen.lua las convierte en zen para el dueño, con sus bonus)
function Mubia.addZenCoins(corpse, zen)
	local crystal = math.floor(zen / 10000)
	local platinum = math.floor((zen % 10000) / 100)
	local gold = zen % 100
	for _, coin in ipairs({ { 3043, crystal }, { 3035, platinum }, { 3031, gold } }) do
		local id, count = coin[1], coin[2]
		while count > 0 do
			local stack = math.min(count, 100)
			corpse:addItem(id, stack)
			count = count - stack
		end
	end
end

-- Quién puede agarrar un item que cayó (nil = cualquiera)
local function dropOwner(item)
	local untilTime = tonumber(item:getCustomAttribute(ATTR_UNTIL)) or 0
	if untilTime <= os.time() then
		return nil
	end
	return tonumber(item:getCustomAttribute(ATTR_OWNER))
end

function Mubia.canPickDrop(player, item)
	local owner = dropOwner(item)
	if not owner or owner == player:getGuid() then
		return true
	end
	-- la party del dueño también puede
	local ownerPlayer = Player(owner)
	local party = player:getParty()
	if party and ownerPlayer then
		local ownerParty = ownerPlayer:getParty()
		return ownerParty ~= nil and ownerParty:getLeader():getId() == party:getLeader():getId()
	end
	return false
end

local tokenCounter = 0

-- Saca del piso lo que nadie agarró
local function vanish(position, token)
	local tile = Tile(position)
	if not tile then
		return
	end
	for _, item in ipairs(tile:getItems() or {}) do
		if tonumber(item:getCustomAttribute(ATTR_TOKEN)) == token then
			item:remove()
		end
	end
end

-- Tira los items al piso donde murió el monstruo. Devuelve los nombres de los Excellent que cayeron.
function Mubia.dropItemsOnGround(position, drops, owner)
	local config = Mubia.DropConfig
	local excellent = {}
	local items = {}
	tokenCounter = tokenCounter + 1
	local token = os.time() * 1000 + tokenCounter % 1000
	for _, drop in ipairs(drops) do
		local item = Game.createItem(drop.id, drop.count, position)
		if item then
			if drop.level and drop.level > 0 then
				Mubia.setItemLevel(item, drop.level)
			end
			if Mubia.rollItemOptions and Mubia.rollItemOptions(item, config.excellentChance) then
				excellent[#excellent + 1] = item:getName()
			end
			if owner then
				item:setCustomAttribute(ATTR_OWNER, owner:getGuid())
				item:setCustomAttribute(ATTR_UNTIL, os.time() + config.protectSeconds)
			end
			item:setCustomAttribute(ATTR_TOKEN, token)
			items[#items + 1] = item
		end
	end
	if #items > 0 then
		position:sendMagicEffect(#excellent > 0 and CONST_ME_FIREWORK_YELLOW or CONST_ME_MAGIC_BLUE)
		addEvent(vanish, config.vanishSeconds * 1000, Position(position), token)
	end
	return excellent, items
end

-- Se llama al morir un monstruo (data/scripts/mubia/zen.lua), antes de cobrar el zen
function Mubia.dropMonsterLoot(monster, corpse, player)
	if not monster or monster:getMaster() then
		return {}
	end
	local drops, zen = Mubia.rollMonsterDrop(monster:getName())
	if zen > 0 and corpse and corpse:isContainer() then
		Mubia.addZenCoins(corpse, zen)
	end
	if #drops == 0 then
		return {}
	end
	local position = corpse and corpse:getPosition() or monster:getPosition()
	local excellent, items = Mubia.dropItemsOnGround(position, drops, player)
	-- Mubia Helper: recoge del piso lo que tenga marcado
	if player and Mubia.helperPickupItems then
		Mubia.helperPickupItems(player, items, position)
	end
	return excellent
end

-- Le saca las marcas de drop a un item que alguien levantó
function Mubia.clearDropMarks(item)
	for _, key in ipairs({ ATTR_OWNER, ATTR_UNTIL, ATTR_TOKEN }) do
		if item:getCustomAttribute(key) then
			item:removeCustomAttribute(key)
		end
	end
end

function Mubia.isDropOnGround(item)
	return item:getCustomAttribute(ATTR_TOKEN) ~= nil
end
