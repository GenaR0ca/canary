-- Mubia Online: segunda evolución con Sebina the Priest (Devias), como la misión de Sevina en MU.
--   Desde nivel 150. Paso 1 (todas las clases): traer el Scroll of Emperor.
--   Paso 2 (según la clase): Broken Sword (DK), Soul of Wizard (DW), Tear of Elf (Elf), Abyssal Eye (Summoner, futura).
--   Los items solo caen mientras el paso está activo y solo a quien hace la misión (data/scripts/mubia/sebina.lua).
--   Premio: la clase pasa a Blade Knight / Soul Master / Muse Elf (se mantiene al hacer reset) y puede usar
--   las alas de 2do y 3er nivel, las magias y los sets de la evolución.
-- La ventana del cliente es el módulo game_mubia_sebina (opcode 91).

Mubia.SEBINA_OPCODE = 91

Mubia.Sebina = {
	npcName = "Sebina the Priest",
	minLevel = 150,
	dropChance = 1, -- % por monstruo (más o menos 1 cada 100)

	SCROLL_OF_EMPEROR = 60801,
	BROKEN_SWORD = 60802,
	TEAR_OF_ELF = 60803,
	SOUL_OF_WIZARD = 60804,
	ABYSSAL_EYE = 60805, -- Summoner (todavía no está en el juego)

	-- Paso 1: monstruos que sueltan el Scroll of Emperor (en sus mapas normales, no en Devil Square / Blood Castle)
	scrollMonsters = {
		["ice queen"] = true, -- Devias
		["poison bull"] = true, -- Dungeon
		["dark knight"] = true, -- Dungeon
		["vepar"] = true, -- Atlans
		["valkyrie"] = true, -- Atlans
		["shadow"] = true, -- Lost Tower
		["poison shadow"] = true,
		["cursed wizard"] = true,
		["devil"] = true,
		["death knight"] = true,
		["gorgon"] = true,
		["death gorgon"] = true,
	},
	scrollWhere = "Ice Queen (Devias), Poison Bull y Dark Knight (Dungeon), Vepar y Valkyrie (Atlans), Shadow, Poison Shadow, Cursed Wizard, Devil, Death Knight y Death Gorgon (Lost Tower).",

	-- Paso 2: cualquier monstruo de estos mapas
	classItemAreas = {
		{ name = "Lost Tower", from = Position(830, 1609, 8), to = Position(1040, 1748, 14) },
		{ name = "Atlans", from = Position(1300, 1040, 7), to = Position(1555, 1295, 7) },
		{ name = "Tarkan", from = Position(1578, 1004, 7), to = Position(1825, 1258, 7) },
	},
	classItemWhere = "Cualquier monstruo de Lost Tower, Atlans y Tarkan.",
}

local S = Mubia.Sebina

-- Item del paso 2 de cada clase
S.classItems = {
	[Mubia.CLASS_DK] = S.BROKEN_SWORD,
	[Mubia.CLASS_DW] = S.SOUL_OF_WIZARD,
	[Mubia.CLASS_ELF] = S.TEAR_OF_ELF,
}

-- Items de la misión: no se venden, no se intercambian y no se tiran al piso
S.questItems = {
	[S.SCROLL_OF_EMPEROR] = true,
	[S.BROKEN_SWORD] = true,
	[S.TEAR_OF_ELF] = true,
	[S.SOUL_OF_WIZARD] = true,
	[S.ABYSSAL_EYE] = true,
}

function Mubia.isQuestItem(itemId)
	return S.questItems[itemId] == true
end

-- Lo que desbloquea la evolución (se puede cambiar acá) -----------------------------------------------------

-- Alas: desde este nivel de alas hace falta la evolución (2 = Wings of Dragon / Soul / Spirits)
S.wingTier = 2

-- Sets que solo puede usar la evolución
S.sets = {
	["Great Dragon"] = true,
	["Dragon Knight"] = true,
	["Grand Soul"] = true,
	["Dark Soul"] = true,
	["Venom Mist"] = true,
	["Divine"] = true,
	["Red Spirit"] = true,
	["Sylphid Ray"] = true,
}

-- Magias que solo puede usar la evolución (por la clave de Mubia.SpellList)
S.spells = {
	deathStab = true,
	ragefulBlow = true,
	iceStorm = true,
	decay = true,
	iceArrow = true,
	starfall = true,
}

-- ¿Ya hizo la segunda evolución? (Blade Knight, Soul Master, Muse Elf)
function Mubia.isEvolved(player)
	local vocation = player:getVocation()
	return vocation ~= nil and vocation:getId() ~= vocation:getBaseId()
end

-- Nombre de la evolución de la clase del jugador ("Blade Knight"...)
function Mubia.getEvolutionName(player)
	local vocation = player:getVocation()
	if not vocation then
		return ""
	end
	if vocation:getId() ~= vocation:getBaseId() then
		return vocation:getName()
	end
	local promotion = vocation:getPromotion()
	return promotion and promotion:getName() or vocation:getName()
end

-- Las magias de la evolución solo las puede usar la clase evolucionada (Canary revisa la vocación al lanzarla)
for _, def in ipairs(Mubia.SpellList) do
	if S.spells[def.key] then
		def.evolution = true
		def.vocations = { Mubia.ClassVocations[def.classId][2] }
	end
end

-- Alas de 2do nivel y sets de la evolución: se revisa al equipar
local checkEquipRequirements = Mubia.checkEquipRequirements
function Mubia.checkEquipRequirements(player, item)
	local itemId = item:getId()
	if not Mubia.isEvolved(player) then
		local wing = Mubia.Wings[itemId]
		if wing and wing.tier >= S.wingTier and Mubia.canUseWings(player, item) then
			return false, string.format("Solo la segunda evolución (%s) puede usar estas alas. Habla con %s en Devias.", Mubia.getEvolutionName(player), S.npcName)
		end
		local gear = Mubia.Gear[itemId]
		if gear and gear.set and S.sets[gear.set] then
			return false, string.format("El set %s es solo para la segunda evolución. Habla con %s en Devias.", gear.set, S.npcName)
		end
	end
	if checkEquipRequirements then
		return checkEquipRequirements(player, item)
	end
	return true
end

-- Estado de la misión ---------------------------------------------------------------------------------

S.STEP_NONE = 0
S.STEP_SCROLL = 1
S.STEP_CLASS_ITEM = 2
S.STEP_DONE = 3

local function store(player)
	return player:kv():scoped("mubia-sebina")
end

function S.getStep(player)
	if Mubia.isEvolved(player) then
		return S.STEP_DONE
	end
	return store(player):get("step") or S.STEP_NONE
end

function S.setStep(player, step)
	store(player):set("step", step)
end

-- Item que el jugador tiene que conseguir ahora (o nil)
function S.getWantedItem(player)
	local step = S.getStep(player)
	if step == S.STEP_SCROLL then
		return S.SCROLL_OF_EMPEROR
	elseif step == S.STEP_CLASS_ITEM then
		local class = player:getVocation() and player:getVocation():getBaseId()
		return S.classItems[class]
	end
	return nil
end

-- Busca el item en todo lo que lleva encima (inventario, equipo)
function S.findItem(player, itemId)
	return player:getItemById(itemId, true)
end

local function inArea(position, area)
	return position.z >= area.from.z and position.z <= area.to.z and position.x >= area.from.x and position.x <= area.to.x and position.y >= area.from.y and position.y <= area.to.y
end

local function inEvent(position)
	if Mubia.DevilSquare and Mubia.DevilSquare.getSquareAt and Mubia.DevilSquare.getSquareAt(position) then
		return true
	end
	if Mubia.BloodCastle and Mubia.BloodCastle.getCastleAt and Mubia.BloodCastle.getCastleAt(position) then
		return true
	end
	return false
end

-- ¿Este monstruo puede soltar el item que busca el jugador?
function S.canDropFor(player, monster, wanted)
	local position = monster:getPosition()
	if inEvent(position) then
		return false
	end
	if wanted == S.SCROLL_OF_EMPEROR then
		return S.scrollMonsters[monster:getName():lower()] == true
	end
	for _, area in ipairs(S.classItemAreas) do
		if inArea(position, area) then
			return true
		end
	end
	return false
end

-- Al morir un monstruo: 1% de que suelte el item de la misión (solo para quien tiene el botín)
function S.rollDrop(monster, corpse)
	local player = Player(corpse:getCorpseOwner())
	if not player then
		return
	end
	local wanted = S.getWantedItem(player)
	if not wanted or S.findItem(player, wanted) or not S.canDropFor(player, monster, wanted) then
		return
	end
	if math.random(10000) > S.dropChance * 100 then
		return
	end
	-- va directo al inventario (así nadie se lo puede robar del cuerpo); si está lleno, queda en el cuerpo
	local bag = player:getSlotItem(CONST_SLOT_BACKPACK)
	local item = bag and bag:isContainer() and bag:getEmptySlots() > 0 and bag:addItem(wanted, 1)
	if not item then
		item = corpse.addItem and corpse:addItem(wanted, 1)
	end
	if item then
		local name = ItemType(wanted):getName()
		Mubia.sendMessage(player, MESSAGE_EVENT_ADVANCE, string.format("¡Encontraste %s! Llévaselo a %s en Devias.", name, S.npcName))
		monster:getPosition():sendMagicEffect(CONST_ME_FIREWORK_YELLOW)
	end
end

-- Ventana de Sebina -----------------------------------------------------------------------------------

local function json(text)
	text = Mubia.toLatin1(tostring(text or ""))
	return '"' .. text:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n") .. '"'
end

local function itemJson(player, itemId, where)
	local have = S.findItem(player, itemId) ~= nil
	local status = have and "¡Ya lo tienes! Entrégaselo a Sebina." or "Todavía no lo tienes."
	return string.format('{"id":%d,"name":%s,"where":%s,"have":%s,"status":%s}', itemId, json(ItemType(itemId):getName()), json("Dónde conseguirlo: " .. where), have and "true" or "false", json(status))
end

-- Lo que desbloquea la evolución para la clase del jugador
local function rewardLines(player)
	local classId = player:getVocation() and player:getVocation():getBaseId()
	local lines = { string.format("La clase %s (se mantiene al hacer reset).", Mubia.getEvolutionName(player)) }
	local wings = {}
	for _, wing in pairs(Mubia.Wings) do
		if wing.classId == classId and wing.tier >= S.wingTier then
			wings[#wings + 1] = { tier = wing.tier, name = wing.name }
		end
	end
	table.sort(wings, function(a, b)
		return a.tier < b.tier
	end)
	local wingNames = {}
	for _, wing in ipairs(wings) do
		wingNames[#wingNames + 1] = wing.name
	end
	if #wingNames > 0 then
		lines[#lines + 1] = "Alas: " .. table.concat(wingNames, ", ") .. "."
	end
	local spells = {}
	for _, def in ipairs(Mubia.SpellList) do
		if def.evolution and def.classId == classId then
			spells[#spells + 1] = def.name
		end
	end
	if #spells > 0 then
		lines[#lines + 1] = "Magias: " .. table.concat(spells, ", ") .. "."
	end
	local sets, seen = {}, {}
	for itemId = 61001, 61999 do
		local gear = Mubia.Gear[itemId]
		if gear and gear.set and S.sets[gear.set] and not seen[gear.set] then
			for _, gearClass in ipairs(gear.classes or {}) do
				if gearClass == classId then
					seen[gear.set] = true
					sets[#sets + 1] = gear.set
					break
				end
			end
		end
	end
	if #sets > 0 then
		lines[#lines + 1] = "Sets: " .. table.concat(sets, ", ") .. "."
	end
	local out = {}
	for _, line in ipairs(lines) do
		out[#out + 1] = json(line)
	end
	return "[" .. table.concat(out, ",") .. "]"
end

function S.openWindow(player)
	local step = S.getStep(player)
	local evolution = Mubia.getEvolutionName(player)
	local name = player:getName()
	local text, stepLabel, item, button = "", "", "null", "null"
	local itemTitle = "Consigue este objeto"
	local classId = player:getVocation() and player:getVocation():getBaseId()

	if not Mubia.getClass(player) then
		text = "Lo siento, no puedo ayudar a tu clase."
	elseif step == S.STEP_DONE then
		stepLabel = "Misión completada"
		text = string.format("Ya despertaste tu verdadero poder, %s. Ahora eres %s. Que la luz te acompañe.", name, evolution)
	elseif step == S.STEP_NONE then
		stepLabel = "Segunda evolución"
		if player:getLevel() < S.minLevel then
			text = string.format("Siento un gran potencial en ti, %s, pero todavía no estás preparado. Vuelve cuando alcances el nivel %d y te enseñaré a convertirte en %s.", name, S.minLevel, evolution)
		else
			text = string.format("Siento un gran poder dormido en ti, %s. Puedo ayudarte a despertarlo y convertirte en %s.\nPrimero debes demostrar tu valor trayéndome el Scroll of Emperor. Solo aparecerá mientras tengas esta misión.", name, evolution)
			button = string.format('{"action":"accept","label":%s,"enabled":true}', json("Aceptar misión"))
		end
		itemTitle = "Primer objeto que te pediré"
		item = itemJson(player, S.SCROLL_OF_EMPEROR, S.scrollWhere)
	elseif step == S.STEP_SCROLL then
		stepLabel = "Paso 1 de 2"
		local have = S.findItem(player, S.SCROLL_OF_EMPEROR)
		text = have and string.format("¡Lo conseguiste, %s! Entrégame el Scroll of Emperor.", name) or "Tráeme el Scroll of Emperor. Lo llevan algunos monstruos poderosos del continente."
		item = itemJson(player, S.SCROLL_OF_EMPEROR, S.scrollWhere)
		button = string.format('{"action":"deliver","label":%s,"enabled":%s}', json("Entregar"), have and "true" or "false")
	elseif step == S.STEP_CLASS_ITEM then
		stepLabel = "Paso 2 de 2"
		local itemId = S.classItems[classId]
		if not itemId then
			text = "Todavía no puedo terminar tu misión."
		else
			local itemName = ItemType(itemId):getName()
			local have = S.findItem(player, itemId)
			text = have and string.format("Siento su poder desde aquí... Entrégame %s y despertaré tu verdadera fuerza.", itemName) or string.format("Para el último paso necesito %s. Búscalo en las tierras más peligrosas: Lost Tower, Atlans y Tarkan.", itemName)
			item = itemJson(player, itemId, S.classItemWhere)
			button = string.format('{"action":"deliver","label":%s,"enabled":%s}', json("Entregar"), have and "true" or "false")
		end
	end

	local rewardTitle = step == S.STEP_DONE and "Ya puedes usar" or "Al evolucionar podrás usar"
	local message = string.format('{"action":"open","npc":%s,"step":%d,"stepLabel":%s,"evolution":%s,"text":%s,"itemTitle":%s,"item":%s,"button":%s,"rewardTitle":%s,"rewards":%s}', json(S.npcName), step, json(stepLabel), json(evolution), json(text), json(itemTitle), item, button, json(rewardTitle), rewardLines(player))
	player:sendExtendedOpcode(Mubia.SEBINA_OPCODE, message)
end

local function promote(player)
	local promotion = player:getVocation():getPromotion()
	if not promotion then
		return false
	end
	player:setVocation(promotion)
	player:kv():set("promoted", true) -- así Canary la mantiene al entrar
	S.setStep(player, S.STEP_DONE)
	Mubia.recalc(player)
	Mubia.sendStats(player)
	local position = player:getPosition()
	position:sendMagicEffect(CONST_ME_HOLYAREA)
	position:sendMagicEffect(CONST_ME_FIREWORK_YELLOW)
	Mubia.sendMessage(player, MESSAGE_EVENT_ADVANCE, string.format("¡Felicitaciones! Ahora eres %s.", promotion:getName()))
	Game.broadcastMessage(Mubia.toLatin1(string.format("%s completó la misión de %s y ahora es %s.", player:getName(), S.npcName, promotion:getName())), MESSAGE_EVENT_ADVANCE)
	return true
end

function S.onAction(player, action)
	local step = S.getStep(player)
	if action == "accept" then
		if step ~= S.STEP_NONE or player:getLevel() < S.minLevel or not Mubia.getClass(player) then
			return S.openWindow(player)
		end
		S.setStep(player, S.STEP_SCROLL)
		player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
		Mubia.sendMessage(player, MESSAGE_EVENT_ADVANCE, "Misión aceptada: consigue el Scroll of Emperor.")
	elseif action == "deliver" then
		local wanted = S.getWantedItem(player)
		local item = wanted and S.findItem(player, wanted)
		if not item then
			Mubia.sendMessage(player, MESSAGE_FAILURE, "Todavía no tienes lo que te pidió Sebina.")
			return S.openWindow(player)
		end
		item:remove(1)
		if step == S.STEP_SCROLL then
			S.setStep(player, S.STEP_CLASS_ITEM)
			player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
			Mubia.sendMessage(player, MESSAGE_EVENT_ADVANCE, string.format("Paso 1 completado. Ahora consigue %s.", ItemType(S.getWantedItem(player) or 0):getName()))
		elseif step == S.STEP_CLASS_ITEM then
			promote(player)
		end
	end
	S.openWindow(player)
end
