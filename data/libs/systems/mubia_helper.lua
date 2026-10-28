-- Mubia Online: Mubia Helper, el "bot" de caza (como el MU Helper de MU Online).
-- El cliente (módulo game_mubia_helper) elige a qué monstruo pegarle y camina hacia él.
-- El servidor, mientras el Helper está prendido:
--   * lanza las habilidades elegidas (básica, habilidad 1 y 2 con su condición, buffs),
--   * toma pociones y usa Heal (en sí misma o en el party) cuando la vida baja del % elegido,
--   * recoge del cuerpo de los monstruos que matás los items elegidos (y el zen, si está marcado).
-- Además, siempre (prendido o no): acepta o rechaza solo las invitaciones de party ("Other Settings").
-- Cliente y servidor hablan por el opcode 86. Prender el Helper cuesta nivel x 20 zen (como en MU).

Mubia.HELPER_OPCODE = 86

Mubia.HelperConfig = {
	tick = 300, -- cada cuánto piensa el Helper (ms)
	zenPerLevel = 0, -- costo al prenderlo: nivel x esto (0 = gratis, por ahora para probarlo; en MU es 20)
	potionDelay = 1000, -- espera entre pociones del mismo tipo (ms); la de vida y la de mana no se esperan entre sí
	maxPickupRange = 8,
	maxExtraNames = 13, -- nombres de items extra para recoger (como en MU)
	-- items que cuentan como "joyas": joyas, paquetes de joyas, frutas, plumas
	jewelIds = { from = 60301, to = 60318 },
	-- sets, armas y escudos de MU
	gearIds = { from = 61001, to = 63999 },
}

-- Helper prendido por jugador: Mubia.helpers[playerId] = { config = {...}, nextPotion = ms, nextManaPotion = ms, timers = {...} }
Mubia.helpers = Mubia.helpers or {}

local BUFF_SUBID = 47100 -- Swell Life (ver data/scripts/mubia/spells.lua)

local function jsonString(text)
	return '"' .. tostring(text):gsub('[%c"\\]', "") .. '"'
end

local function send(player, json)
	if player:isUsingOtClient() then
		player:sendExtendedOpcode(Mubia.HELPER_OPCODE, json)
	end
end

function Mubia.isHelperOn(player)
	return Mubia.helpers[player:getId()] ~= nil
end

function Mubia.getHelperCost(player)
	return player:getLevel() * Mubia.HelperConfig.zenPerLevel
end

-- Habilidades que el jugador ya aprendió y que el Helper sabe usar
local HELPER_KINDS = { attack = true, buff = true, heal = true, recovery = true, summon = true }

function Mubia.sendHelperSpells(player)
	local parts = {}
	for _, def in ipairs(Mubia.SpellList) do
		if HELPER_KINDS[def.kind] and player:hasLearnedSpell(def.name) then
			parts[#parts + 1] = string.format('{"key":%s,"name":%s,"kind":%s}', jsonString(def.key), jsonString(def.name), jsonString(def.kind))
		end
	end
	send(player, string.format('{"spells":[%s],"cost":%d,"on":%s}', table.concat(parts, ","), Mubia.getHelperCost(player), tostring(Mubia.isHelperOn(player))))
end

local function sendState(player, on, reason)
	if reason then
		send(player, string.format('{"on":%s,"reason":%s}', tostring(on), jsonString(Mubia.toLatin1(reason))))
	else
		send(player, string.format('{"on":%s}', tostring(on)))
	end
end

-- La configuración llega como texto "clave=valor;clave=valor" (ver el módulo del cliente)
local function parseConfig(text)
	local raw = {}
	for key, value in text:gmatch("([%w]+)=([^;]*)") do
		raw[key] = value
	end

	local function number(key, default, min, max)
		local n = tonumber(raw[key]) or default
		return math.max(min, math.min(max, math.floor(n)))
	end
	local function spell(key)
		local def = raw[key] and Mubia.Spells[raw[key]]
		return def and def.key or nil
	end
	local function skill(prefix)
		local mode = raw[prefix .. "mode"]
		if mode ~= "timer" and mode ~= "count" then
			mode = "always"
		end
		return { key = spell(prefix), mode = mode, value = number(prefix .. "val", mode == "timer" and 3 or 2, 1, 60) }
	end

	local config = {
		basic = spell("basic"),
		skills = { skill("s1"), skill("s2") },
		buffs = {},
		healSelf = number("heal", 0, 0, 100),
		healParty = number("hparty", 0, 0, 100),
		hpPotion = number("hp", 0, 0, 100),
		mpPotion = number("mp", 0, 0, 100),
		pickAll = raw.all == "1",
		pickJewels = raw.jewel == "1",
		pickZen = raw.zen ~= "0", -- sin el dato, el zen se junta como siempre
		pickExcellent = raw.exc == "1",
		pickGear = raw.gear == "1",
		pickScrolls = raw.scroll == "1",
		pickRange = number("prange", 3, 1, Mubia.HelperConfig.maxPickupRange),
		extraNames = {},
	}
	for key in (raw.buffs or ""):gmatch("[^,]+") do
		local def = Mubia.Spells[key]
		if def and (def.kind == "buff" or def.kind == "summon" or def.kind == "recovery") then
			config.buffs[#config.buffs + 1] = def.key
		end
	end
	local extra = raw.other == "1" and raw.extra or ""
	for text in extra:gmatch("[^,]+") do
		local name = text:lower():gsub("^%s+", ""):gsub("%s+$", "")
		if name ~= "" and #config.extraNames < Mubia.HelperConfig.maxExtraNames then
			config.extraNames[#config.extraNames + 1] = name
		end
	end
	return config
end

local function inSafeZone(player)
	local tile = Tile(player:getPosition())
	return tile and tile:hasFlag(TILESTATE_PROTECTIONZONE)
end

function Mubia.startHelper(player, configText)
	if Mubia.isHelperOn(player) then
		Mubia.helpers[player:getId()].config = parseConfig(configText)
		Mubia.sendMessage(player, MESSAGE_STATUS, "Mubia Helper: configuración actualizada.")
		sendState(player, true)
		return true
	end
	if inSafeZone(player) then
		sendState(player, false, "No puedes usar el Mubia Helper en una zona segura.")
		return false
	end
	local cost = Mubia.getHelperCost(player)
	if cost > 0 and (Mubia.getZen(player) < cost or not player:removeMoneyBank(cost)) then
		sendState(player, false, string.format("Necesitas %d zen para usar el Mubia Helper.", cost))
		return false
	end

	local playerId = player:getId()
	Mubia.helpers[playerId] = { config = parseConfig(configText), nextPotion = 0, timers = {} }
	if cost > 0 then
		Mubia.sendMessage(player, MESSAGE_STATUS, string.format("Mubia Helper prendido (costó %d zen).", cost))
	else
		Mubia.sendMessage(player, MESSAGE_STATUS, "Mubia Helper prendido.")
	end
	sendState(player, true)
	addEvent(Mubia.helperTick, Mubia.HelperConfig.tick, playerId)
	return true
end

function Mubia.stopHelper(player, reason)
	if not Mubia.isHelperOn(player) then
		return
	end
	Mubia.helpers[player:getId()] = nil
	if reason then
		Mubia.sendMessage(player, MESSAGE_STATUS, "Mubia Helper apagado: " .. reason)
	else
		Mubia.sendMessage(player, MESSAGE_STATUS, "Mubia Helper apagado.")
	end
	sendState(player, false)
end

-- Monstruos vivos alrededor (sin contar invocaciones ni mascotas)
local function countMonstersAround(position, radius)
	local count = 0
	for _, creature in ipairs(Game.getSpectators(position, false, false, radius, radius, radius, radius)) do
		if creature:isMonster() and not creature:getMaster() and creature:getHealth() > 0 then
			count = count + 1
		end
	end
	return count
end

-- Dirección (norte, sur, este u oeste) para mirar hacia el objetivo
local function directionTo(from, to)
	local dx, dy = to.x - from.x, to.y - from.y
	if math.abs(dx) > math.abs(dy) then
		return dx > 0 and DIRECTION_EAST or DIRECTION_WEST
	end
	return dy > 0 and DIRECTION_SOUTH or DIRECTION_NORTH
end

-- ¿Hasta dónde llega una magia de ataque y cuánto se puede abrir hacia los costados?
local function spellReach(def)
	if def.target then
		return def.range or 5, nil
	end
	local area = def.area and _G[def.area]
	local size = area and #area or 3
	if def.direction or def.fan then
		local width = area and area[1] and #area[1] or 1
		return size - 1, math.floor(width / 2)
	end
	return math.floor(size / 2), nil
end

-- ¿La magia de ataque le llega al objetivo desde donde está el jugador?
local function canHit(player, def, target)
	if not target then
		return false
	end
	local from, to = player:getPosition(), target:getPosition()
	if from.z ~= to.z then
		return false
	end
	local dx, dy = math.abs(to.x - from.x), math.abs(to.y - from.y)
	local reach, side = spellReach(def)
	if math.max(dx, dy) > reach then
		return false
	end
	if side then
		-- magias hacia donde mirás: el objetivo tiene que estar más o menos en línea
		if math.min(dx, dy) > side then
			return false
		end
	end
	return from:isSightClear(to)
end

-- ¿Puede lanzarla ahora? (la aprendió, nivel, mana, AG y la espera entre magias por AGI)
local function canCast(player, def)
	if not def or not Mubia.SpellCasters or not Mubia.SpellCasters[def.key] then
		return false
	end
	if (Mubia.nextCast[player:getId()] or 0) > systemTime() then
		return false
	end
	if player:getLevel() < def.level or player:getMana() < def.mana then
		return false
	end
	if not player:hasLearnedSpell(def.name) then
		return false
	end
	local agCost = Mubia.SpellAG and Mubia.SpellAG[def.key] or 0
	if agCost > 0 and Mubia.getAG and Mubia.getAG(player) < agCost then
		return false
	end
	return true
end

-- Lanza la magia como si el jugador la hubiera dicho (sin que aparezca el texto en pantalla)
local function cast(player, def, target)
	local variant
	local position = player:getPosition()
	if def.target and target then
		variant = Variant(target:getId())
	elseif (def.direction or def.fan) and target then
		local direction = directionTo(position, target:getPosition())
		player:setDirection(direction)
		local front = Position(position)
		front:getNextPosition(direction)
		variant = Variant(front)
	else
		variant = Variant(position)
	end
	if Mubia.SpellCasters[def.key](player, variant) then
		player:addMana(-def.mana)
		return true
	end
	return false
end

-- Buffs: se vuelven a lanzar cuando se terminan, en el jugador o en algún compañero de party
local BUFF_PARTY_RANGE = 8 -- igual que PARTY_RANGE de data/scripts/mubia/spells.lua

local function hasBuff(creature, def)
	if def.buff == "swellLife" then
		return creature:getCondition(CONDITION_ATTRIBUTES, CONDITIONID_COMBAT, BUFF_SUBID) ~= nil
	end
	if def.buff == "soulBarrier" then
		return Mubia.getBuff(creature, "barrier") > 0
	end
	return Mubia.getBuff(creature, def.buff) > 0
end

-- El jugador y los compañeros de party a los que les llega el buff
local function buffTargets(player)
	local targets = { player }
	local party = player:getParty()
	if not party then
		return targets
	end
	local origin = player:getPosition()
	local members = party:getMembers()
	members[#members + 1] = party:getLeader()
	for _, member in ipairs(members) do
		if member and member ~= player then
			local position = member:getPosition()
			if position.z == origin.z and origin:getDistance(position) <= BUFF_PARTY_RANGE then
				targets[#targets + 1] = member
			end
		end
	end
	return targets
end

local function isBuffActive(player, def)
	if def.kind == "summon" then
		for _, summon in ipairs(player:getSummons()) do
			if not Mubia.PetFollowers[summon:getName()] then
				return true
			end
		end
		return false
	end
	if def.kind == "recovery" then
		return player:getMana() >= player:getMaxMana() * 0.5
	end
	-- los buffs llegan a toda la party cercana: se vuelve a lanzar si a alguno se le terminó
	for _, member in ipairs(buffTargets(player)) do
		if not hasBuff(member, def) then
			return false
		end
	end
	return true
end

-- Pociones: la mejor que tenga y pueda tomar (mismas reglas que tomarla a mano)
local function usePotion(player, kind)
	if not Mubia.FlaskPotions or not Mubia.useFlaskPotion then
		return false
	end
	local best, bestValue
	local baseId = player:getVocation():getBaseId()
	for itemId, potion in pairs(Mubia.FlaskPotions) do
		local amount = potion[kind]
		if amount and not potion.func and not potion.condition then
			local allowed = (not potion.level or player:getLevel() >= potion.level) and (not potion.vocations or table.contains(potion.vocations, baseId))
			local value = (amount[1] + amount[2]) / 2
			if allowed and (not bestValue or value > bestValue) and player:getItemCount(itemId) > 0 then
				best, bestValue = itemId, value
			end
		end
	end
	if not best then
		return false
	end
	local item = player:getItemById(best, true)
	if not item then
		return false
	end
	return Mubia.useFlaskPotion(player, item, Position(CONTAINER_POSITION, 0, 0), player, player:getPosition(), true)
end

local function percent(value, max)
	return max > 0 and value * 100 / max or 100
end

-- ¿Algún compañero de party cerca tiene la vida por debajo del %?
local PARTY_HEAL_RANGE = 8
local function partyNeedsHeal(player, limit)
	local party = player:getParty()
	if not party then
		return false
	end
	local origin = player:getPosition()
	local members = party:getMembers()
	members[#members + 1] = party:getLeader()
	for _, member in ipairs(members) do
		if member and member ~= player then
			local position = member:getPosition()
			if position.z == origin.z and origin:getDistance(position) <= PARTY_HEAL_RANGE and percent(member:getHealth(), member:getMaxHealth()) <= limit then
				return true
			end
		end
	end
	return false
end

local function heal(player, helper)
	local config = helper.config
	local now = systemTime()
	local hp = percent(player:getHealth(), player:getMaxHealth())
	local mp = percent(player:getMana(), player:getMaxMana())

	-- vida y mana van por separado: puede tomar las dos a la vez
	if now >= helper.nextPotion and config.hpPotion > 0 and hp <= config.hpPotion and usePotion(player, "health") then
		helper.nextPotion = now + Mubia.HelperConfig.potionDelay
	end
	if now >= (helper.nextManaPotion or 0) and config.mpPotion > 0 and mp <= config.mpPotion and usePotion(player, "mana") then
		helper.nextManaPotion = now + Mubia.HelperConfig.potionDelay
	end

	-- Heal de la elfa: en sí misma o en el compañero de party más herido (la magia elige al más herido)
	local needsHeal = config.healSelf > 0 and hp <= config.healSelf
	if not needsHeal and config.healParty > 0 then
		needsHeal = partyNeedsHeal(player, config.healParty)
	end
	if needsHeal then
		local def = Mubia.Spells.heal
		if canCast(player, def) and cast(player, def) then
			return true
		end
	end
	return false
end

local function castBuffs(player, helper)
	for _, key in ipairs(helper.config.buffs) do
		local def = Mubia.Spells[key]
		if def and not isBuffActive(player, def) and canCast(player, def) and cast(player, def) then
			return true
		end
	end
	return false
end

-- ¿Se cumple la condición de la habilidad 1 o 2?
local function skillReady(player, helper, index, skill, target)
	if skill.mode == "timer" then
		return systemTime() >= (helper.timers[index] or 0)
	end
	if skill.mode == "count" then
		return countMonstersAround(player:getPosition(), 3) >= skill.value
	end
	return true
end

local function attack(player, helper)
	local target = player:getTarget()
	if not target or not target:isMonster() or target:getHealth() <= 0 then
		return false
	end
	local config = helper.config
	for index, skill in ipairs(config.skills) do
		local def = skill.key and Mubia.Spells[skill.key]
		if def and skillReady(player, helper, index, skill, target) and canCast(player, def) and canHit(player, def, target) then
			if cast(player, def, target) then
				if skill.mode == "timer" then
					helper.timers[index] = systemTime() + skill.value * 1000
				end
				return true
			end
		end
	end
	local def = config.basic and Mubia.Spells[config.basic]
	if def and canCast(player, def) and canHit(player, def, target) then
		return cast(player, def, target)
	end
	return false
end

function Mubia.helperTick(playerId)
	local player = Player(playerId)
	local helper = Mubia.helpers[playerId]
	if not helper then
		return
	end
	if not player then
		Mubia.helpers[playerId] = nil
		return
	end
	if inSafeZone(player) then
		Mubia.stopHelper(player, "entraste en una zona segura.")
		return
	end

	-- una cosa por vez: curarse, buffs y después atacar
	local _ = heal(player, helper) or castBuffs(player, helper) or attack(player, helper)
	addEvent(Mubia.helperTick, Mubia.HelperConfig.tick, playerId)
end

-- ¿El Helper tiene que recoger este item?
local function wantsItem(config, item)
	local itemId = item:getId()
	if Mubia.ZenCoins and Mubia.ZenCoins[itemId] then
		return false -- el zen se junta solo
	end
	if config.pickAll then
		return true
	end
	local jewels, gear = Mubia.HelperConfig.jewelIds, Mubia.HelperConfig.gearIds
	if config.pickJewels and itemId >= jewels.from and itemId <= jewels.to then
		return true
	end
	if config.pickGear and itemId >= gear.from and itemId <= gear.to then
		return true
	end
	if config.pickScrolls and Mubia.SpellByScroll and Mubia.SpellByScroll[itemId] then
		return true
	end
	if config.pickExcellent and Mubia.isExcellent and Mubia.isExcellent(item) then
		return true
	end
	if #config.extraNames > 0 then
		local name = item:getName():lower()
		for _, wanted in ipairs(config.extraNames) do
			if name:find(wanted, 1, true) then
				return true
			end
		end
	end
	return false
end

local function pickFrom(player, config, container, bag, picked)
	for i = container:getSize() - 1, 0, -1 do
		local item = container:getItem(i)
		if item then
			if wantsItem(config, item) then
				if bag:getEmptySlots() <= 0 and not ItemType(item:getId()):isStackable() then
					return false
				end
				local name = item:getCount() > 1 and string.format("%d %s", item:getCount(), item:getName()) or item:getName()
				if item:moveTo(bag) then
					picked[#picked + 1] = name
				end
			elseif item:isContainer() then
				if not pickFrom(player, config, item, bag, picked) then
					return false
				end
			end
		end
	end
	return true
end

-- Se llama al morir un monstruo (data/scripts/mubia/zen.lua), después de tirar los dados de Excellent
function Mubia.helperPickup(player, corpse)
	local helper = Mubia.helpers[player:getId()]
	if not helper or not corpse or not corpse:isContainer() then
		return
	end
	local config = helper.config
	if not (config.pickAll or config.pickJewels or config.pickExcellent or config.pickGear or config.pickScrolls or #config.extraNames > 0) then
		return
	end
	local from, to = player:getPosition(), corpse:getPosition()
	if from.z ~= to.z or math.max(math.abs(from.x - to.x), math.abs(from.y - to.y)) > config.pickRange then
		return
	end
	local bag = player:getSlotItem(CONST_SLOT_BACKPACK)
	if not bag or not bag:isContainer() then
		return
	end

	local picked = {}
	local fits = pickFrom(player, config, corpse, bag, picked)
	if #picked > 0 then
		to:sendMagicEffect(CONST_ME_MAGIC_GREEN)
		Mubia.sendMessage(player, MESSAGE_LOOT, "Mubia Helper recogió: " .. table.concat(picked, ", ") .. ".")
	end
	if not fits and not helper.fullWarned then
		helper.fullWarned = true
		Mubia.sendMessage(player, MESSAGE_FAILURE, "Mubia Helper: tu inventario está lleno, ya no puede recoger más items.")
	elseif fits then
		helper.fullWarned = nil
	end
end

-- Con el Helper prendido y el zen sin marcar, las monedas quedan en el cuerpo (data/scripts/mubia/zen.lua)
function Mubia.helperWantsZen(player)
	local helper = player and Mubia.helpers[player:getId()]
	if not helper then
		return true
	end
	return helper.config.pickAll or helper.config.pickZen
end

-- Invitaciones de party: "accept" las acepta solo, "reject" las rechaza solo, "none" no hace nada.
-- Se guarda en el personaje, así funciona aunque el Helper esté apagado.
Mubia.PartyModes = { accept = true, reject = true, none = true }

function Mubia.getPartyMode(player)
	local mode = player:kv():scoped("mubia-helper"):get("party")
	return Mubia.PartyModes[mode] and mode or "none"
end

function Mubia.setPartyMode(player, mode)
	if not Mubia.PartyModes[mode] then
		return
	end
	player:kv():scoped("mubia-helper"):set("party", mode)
end

-- Elfa: flechas o bolts del inventario al quiver (mano del escudo), si hay lugar.
-- Se guarda en el personaje ("Other Settings"); funciona aunque el Helper esté apagado.
Mubia.autoQuiver = Mubia.autoQuiver or {}

function Mubia.setAutoQuiver(player, enabled)
	player:kv():scoped("mubia-helper"):set("quiver", enabled and "1" or "0")
	Mubia.autoQuiver[player:getId()] = enabled or nil
end

function Mubia.loadAutoQuiver(player)
	Mubia.autoQuiver[player:getId()] = player:kv():scoped("mubia-helper"):get("quiver") == "1" or nil
end

function Mubia.fillQuiver(player)
	local vocation = player:getVocation()
	if not vocation or vocation:getBaseId() ~= Mubia.CLASS_ELF then
		return
	end
	local quiver = player:getSlotItem(CONST_SLOT_RIGHT)
	if not quiver or not ItemType(quiver:getId()):isQuiver() or not quiver:isContainer() then
		return
	end
	local weapon = player:getSlotItem(CONST_SLOT_LEFT)
	local ammoType = weapon and ItemType(weapon:getId()):getAmmoType() or 0
	if ammoType == 0 then
		return -- sin arco ni ballesta no se sabe si van flechas o bolts
	end
	local bag = player:getSlotItem(CONST_SLOT_BACKPACK)
	if not bag or not bag:isContainer() then
		return
	end
	for i = bag:getSize() - 1, 0, -1 do
		local item = bag:getItem(i)
		if item then
			local itemType = ItemType(item:getId())
			if itemType:getWeaponType() == WEAPON_AMMO and itemType:getAmmoType() == ammoType then
				if not item:moveTo(quiver) then
					return -- el quiver está lleno
				end
			end
		end
	end
end

function Mubia.checkAutoQuivers()
	for playerId in pairs(Mubia.autoQuiver) do
		local player = Player(playerId)
		if player then
			Mubia.fillQuiver(player)
		else
			Mubia.autoQuiver[playerId] = nil
		end
	end
end

-- Revisa las invitaciones pendientes de cada party (lo llama un GlobalEvent cada segundo)
function Mubia.checkPartyInvites()
	for _, leader in ipairs(Game.getPlayers()) do
		local party = leader:getParty()
		if party and party:getLeader() == leader then
			for _, invitee in ipairs(party:getInvitees()) do
				local mode = Mubia.getPartyMode(invitee)
				if mode == "accept" and not invitee:getParty() then
					if party:addMember(invitee) then
						Mubia.sendMessage(invitee, MESSAGE_STATUS, string.format("Mubia Helper: aceptaste solo la party de %s.", leader:getName()))
					end
				elseif mode == "reject" then
					party:removeInvite(invitee)
					Mubia.sendMessage(leader, MESSAGE_FAILURE, string.format("%s rechaza las invitaciones de party.", invitee:getName()))
				end
			end
		end
	end
end

-- Mensajes del cliente: "spells" (pide la lista de habilidades), "start|config", "stop" y "party|modo"
function Mubia.onHelperOpcode(player, buffer)
	local action, rest = buffer:match("^(%a+)|?(.*)$")
	if action == "party" then
		Mubia.setPartyMode(player, rest)
	elseif action == "quiver" then
		Mubia.setAutoQuiver(player, rest == "1")
	elseif action == "spells" then
		Mubia.sendHelperSpells(player)
	elseif action == "start" then
		Mubia.startHelper(player, rest or "")
	elseif action == "stop" then
		Mubia.stopHelper(player)
	end
end
