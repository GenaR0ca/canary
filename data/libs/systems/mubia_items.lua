-- Mubia Online: items estilo MU Online (Season 6).
-- Nivel del item +0 a +15 (Jewel of Bless y Jewel of Soul), opción adicional +4 a +28 (Jewel of Life)
-- y alas en su propio slot (CONST_SLOT_WINGS). El nivel y la opción se guardan en el item.

Mubia.ItemConfig = {
	maxLevel = 15,
	maxOption = 7, -- cada nivel de opción suma optionStep (7 x 4 = +28)
	optionStep = 4,
	-- Jewel of Bless: sube de +0 a +6, siempre sale bien
	blessMaxLevel = 6,
	-- Jewel of Soul: sube de +6 a +9. Probabilidad de éxito según el nivel al que se quiere llegar.
	-- Si falla, el item baja soulFailLevels niveles (nunca por debajo de +0).
	-- De +9 a +15 se sube en la Chaos Machine (data/libs/systems/mubia_chaos.lua), como en MU.
	soulMaxLevel = 9,
	soulChance = { [7] = 50, [8] = 50, [9] = 50 },
	soulFailLevels = 1,
	-- Jewel of Life: probabilidad de éxito. Si falla, se pierde la opción (vuelve a +0).
	lifeChance = 50,
	lifeFailReset = true,
	-- Bonus por cada nivel del item (daño en armas, defensa en armaduras, escudos y alas)
	levelBonus = { 3, 3, 3, 3, 3, 3, 3, 3, 3, 4, 5, 6, 7, 8, 9 },
}

-- Slots de alas y guantes (los define canary.exe; los números por si el .exe todavía es el viejo)
CONST_SLOT_WINGS = CONST_SLOT_WINGS or 12
CONST_SLOT_GLOVES = CONST_SLOT_GLOVES or 13

-- Sets, armas y escudos de MU: la tabla Mubia.Gear está en mubia_gear.lua
Mubia.Gear = Mubia.Gear or {}

Mubia.JEWEL_OF_BLESS = 60303
Mubia.JEWEL_OF_SOUL = 60301
Mubia.JEWEL_OF_LIFE = 60302
Mubia.JEWEL_OF_CHAOS = 60304

-- Alas MU: aumentan el daño y absorben un % del daño recibido; ambos suben con el nivel del item.
Mubia.Wings = {
	[60401] = { name = "Wings of Satan", classId = Mubia.CLASS_DK, tier = 1 },
	[60402] = { name = "Wings of Heaven", classId = Mubia.CLASS_DW, tier = 1 },
	[60403] = { name = "Wings of Elf", classId = Mubia.CLASS_ELF, tier = 1 },
	[60404] = { name = "Wings of Dragon", classId = Mubia.CLASS_DK, tier = 2 },
	[60405] = { name = "Wings of Soul", classId = Mubia.CLASS_DW, tier = 2 },
	[60406] = { name = "Wings of Spirits", classId = Mubia.CLASS_ELF, tier = 2 },
	[60407] = { name = "Wings of Storm", classId = Mubia.CLASS_DK, tier = 3 },
	[60408] = { name = "Wings of Eternal", classId = Mubia.CLASS_DW, tier = 3 },
	[60409] = { name = "Wings of Illusion", classId = Mubia.CLASS_ELF, tier = 3 },
}

-- Por generación: % de daño extra y % de absorción (base + por nivel) y defensa base
Mubia.WingTiers = {
	[1] = { damage = 12, damagePerLevel = 2, absorb = 12, absorbPerLevel = 1, defense = 10 },
	[2] = { damage = 32, damagePerLevel = 1, absorb = 25, absorbPerLevel = 1, defense = 20 },
	[3] = { damage = 39, damagePerLevel = 1, absorb = 39, absorbPerLevel = 1, defense = 35 },
}

local ATTR_LEVEL = "muLevel"
local ATTR_OPTION = "muOption"

-- Qué tipo de item MU es: "weapon", "staff", "armor", "shield", "wings" o nil (los items de Tibia no se mejoran)
function Mubia.getItemKind(item)
	if Mubia.Wings[item:getId()] then
		return "wings"
	end
	local gear = Mubia.Gear[item:getId()]
	return gear and gear.kind or nil
end

function Mubia.getItemLevel(item)
	return tonumber(item:getCustomAttribute(ATTR_LEVEL)) or 0
end

function Mubia.getItemOption(item)
	return tonumber(item:getCustomAttribute(ATTR_OPTION)) or 0
end

-- Bonus total por el nivel (+0 a +15)
function Mubia.getLevelBonus(level)
	local total = 0
	for i = 1, math.min(level, #Mubia.ItemConfig.levelBonus) do
		total = total + Mubia.ItemConfig.levelBonus[i]
	end
	return total
end

function Mubia.getWingStats(item)
	local wing = Mubia.Wings[item:getId()]
	if not wing then
		return nil
	end
	local tier = Mubia.WingTiers[wing.tier]
	local level = Mubia.getItemLevel(item)
	return {
		damage = tier.damage + tier.damagePerLevel * level,
		absorb = tier.absorb + tier.absorbPerLevel * level,
		defense = tier.defense + Mubia.getLevelBonus(level),
	}
end

-- Líneas de stats del item por su nivel (+1 a +15) y, en las alas, daño / absorción / defensa
function Mubia.getItemStatLines(item)
	local lines = {}
	local level = Mubia.getItemLevel(item)
	local kind = Mubia.getItemKind(item)
	local wingStats = Mubia.getWingStats(item)
	if wingStats then
		lines[#lines + 1] = string.format("Daño +%d%%.", wingStats.damage)
		lines[#lines + 1] = string.format("Absorbe el %d%% del daño recibido.", wingStats.absorb)
		lines[#lines + 1] = string.format("Defensa: %d.", wingStats.defense)
	elseif level > 0 then
		local what = kind == "staff" and "Daño mágico" or kind == "weapon" and "Daño" or "Defensa"
		lines[#lines + 1] = string.format("Nivel +%d: %s +%d.", level, what, Mubia.getLevelBonus(level))
	end
	return lines
end

-- Líneas de opciones del item: opción adicional (Jewel of Life), Luck, Excellent y Harmony
function Mubia.getItemOptionLines(item)
	local lines = {}
	local option = Mubia.getItemOption(item)
	if option > 0 then
		local kind = Mubia.getItemKind(item)
		local what = kind == "staff" and "Daño mágico" or (kind == "weapon" or kind == "wings") and "Daño" or "Defensa"
		lines[#lines + 1] = string.format("Opción adicional: %s +%d.", what, option * Mubia.ItemConfig.optionStep)
	end
	for _, getLines in ipairs({ Mubia.getExcellentLines, Mubia.getHarmonyLines }) do
		for _, line in ipairs(getLines(item)) do
			lines[#lines + 1] = line
		end
	end
	return lines
end

-- Nombre y descripción del item según su nivel y opción ("Plate Armor +7", "Opción adicional: Defensa +8")
function Mubia.refreshItemText(item)
	local itemType = item:getType()
	local level = Mubia.getItemLevel(item)
	local option = Mubia.getItemOption(item)
	local kind = Mubia.getItemKind(item)

	-- "excellent dragon sword +7" (las alas con opción no se llaman Excellent, como en MU)
	local excellent = Mubia.isExcellent and Mubia.isExcellent(item)
	local name = itemType:getName()
	if excellent then
		name = "excellent " .. name
	end
	if level > 0 then
		name = string.format("%s +%d", name, level)
	end
	if name ~= itemType:getName() then
		item:setAttribute(ITEM_ATTRIBUTE_NAME, name)
	else
		item:removeAttribute(ITEM_ATTRIBUTE_NAME)
	end
	if excellent then
		item:setAttribute(ITEM_ATTRIBUTE_ARTICLE, "an")
	else
		item:removeAttribute(ITEM_ATTRIBUTE_ARTICLE)
	end

	local lines = {}
	for _, list in ipairs({ Mubia.getItemStatLines(item), Mubia.getItemOptionLines(item) }) do
		for _, line in ipairs(list) do
			lines[#lines + 1] = line
		end
	end

	if #lines > 0 then
		item:setAttribute(ITEM_ATTRIBUTE_DESCRIPTION, Mubia.toLatin1(table.concat(lines, "\n")))
	else
		item:removeAttribute(ITEM_ATTRIBUTE_DESCRIPTION)
	end
end

function Mubia.setItemLevel(item, level)
	item:setCustomAttribute(ATTR_LEVEL, math.max(0, math.min(level, Mubia.ItemConfig.maxLevel)))
	Mubia.refreshItemText(item)
end

function Mubia.setItemOption(item, option)
	item:setCustomAttribute(ATTR_OPTION, math.max(0, math.min(option, Mubia.ItemConfig.maxOption)))
	Mubia.refreshItemText(item)
end

-- Bonus de los items equipados: daño físico, daño mágico, % de daño mágico (bastones), defensa, alas y mascota
function Mubia.getEquipmentBonus(player)
	local pet = Mubia.getPet and Mubia.getPet(player) or {}
	local bonus = { attack = 0, wizardry = 0, magicRise = 0, defense = 0, wingDamage = 0, wingAbsorb = 0, petDamage = pet.damage or 0, petAbsorb = pet.absorb or 0, criticalRate = 0 }
	bonus.exc = Mubia.newExcellentBonus()
	bonus.harmony = Mubia.newHarmonyBonus()
	local slots = { CONST_SLOT_HEAD, CONST_SLOT_ARMOR, CONST_SLOT_LEGS, CONST_SLOT_FEET, CONST_SLOT_GLOVES, CONST_SLOT_LEFT, CONST_SLOT_RIGHT, CONST_SLOT_WINGS }
	for _, slot in ipairs(slots) do
		local item = player:getSlotItem(slot)
		local kind = item and Mubia.getItemKind(item)
		if kind then
			local gear = Mubia.Gear[item:getId()]
			local levelBonus = Mubia.getLevelBonus(Mubia.getItemLevel(item))
			local optionBonus = Mubia.getItemOption(item) * Mubia.ItemConfig.optionStep
			if kind == "weapon" then
				bonus.attack = bonus.attack + levelBonus + optionBonus
			elseif kind == "staff" then
				bonus.wizardry = bonus.wizardry + levelBonus + optionBonus
				bonus.magicRise = bonus.magicRise + (gear.magic or 0)
			elseif kind == "shield" or kind == "armor" then
				bonus.defense = bonus.defense + gear.defense + levelBonus + optionBonus
			elseif kind == "wings" then
				local stats = Mubia.getWingStats(item)
				bonus.defense = bonus.defense + stats.defense
				bonus.attack = bonus.attack + optionBonus
				bonus.wizardry = bonus.wizardry + optionBonus
				bonus.wingDamage = stats.damage
				bonus.wingAbsorb = stats.absorb
			end
			Mubia.addExcellentBonus(bonus, item, player)
			Mubia.addHarmonyBonus(bonus, item)
		end
	end
	-- DMGL: daño +nivel/20 (golpes y magias)
	bonus.attack = bonus.attack + bonus.exc.damageFlat
	bonus.wizardry = bonus.wizardry + bonus.exc.damageFlat
	return bonus
end

-- Daño mínimo y máximo de las armas MU equipadas (sin nivel ni opción)
function Mubia.getGearWeaponDamage(player)
	local minDamage, maxDamage = 0, 0
	for _, slot in ipairs({ CONST_SLOT_LEFT, CONST_SLOT_RIGHT }) do
		local item = player:getSlotItem(slot)
		local gear = item and Mubia.Gear[item:getId()]
		if gear and gear.min then
			minDamage = minDamage + gear.min
			maxDamage = maxDamage + gear.max
		end
	end
	return minDamage, maxDamage
end

local function hasClass(gear, class)
	for _, classId in ipairs(gear.classes) do
		if Mubia.Classes[classId] == class then
			return true
		end
	end
	return false
end

local function classNames(gear)
	local names = {}
	for _, classId in ipairs(gear.classes) do
		names[#names + 1] = Mubia.Classes[classId].name
	end
	return table.concat(names, ", ")
end

-- ¿Puede el jugador equipar este item de MU? Devuelve false y el motivo si no puede.
-- item (opcional): si tiene Harmony de STR o AGI requerida, se descuenta.
function Mubia.checkGearRequirements(player, itemId, item)
	local gear = Mubia.Gear[itemId]
	if not gear then
		return true
	end
	local strDecrease, agiDecrease = 0, 0
	if item then
		strDecrease, agiDecrease = Mubia.getHarmonyRequirementDecrease(item)
	end
	local needStr, needAgi = math.max(0, gear.str - strDecrease), math.max(0, gear.agi - agiDecrease)
	local class = Mubia.getClass(player)
	if not class or not hasClass(gear, class) then
		return false, string.format("%s solo lo puede usar: %s.", gear.name, classNames(gear))
	end
	local stats = Mubia.getStats(player)
	local missing = {}
	if stats.str < needStr then
		missing[#missing + 1] = string.format("STR %d (tienes %d)", needStr, stats.str)
	end
	if stats.agi < needAgi then
		missing[#missing + 1] = string.format("AGI %d (tienes %d)", needAgi, stats.agi)
	end
	if gear.level and player:getLevel() < gear.level then
		missing[#missing + 1] = string.format("nivel %d", gear.level)
	end
	if #missing > 0 then
		return false, string.format("Para usar %s necesitas %s.", gear.name, table.concat(missing, ", "))
	end
	return true
end

-- Colores del texto al mirar un item de MU (el cliente de Mubia los muestra; formato {texto, #color})
Mubia.LookColors = {
	name = "#00EB00", -- nombre y stats (verde, como el mensaje normal de "You see")
	option = "#6fa8ff", -- Luck, opción adicional, Excellent y Harmony (azul)
	info = "#ffffff", -- clase (blanco)
	ok = "#90ee90", -- requisito cumplido (verde claro)
	missing = "#f55e5e", -- requisito sin cumplir (rojo)
}

local function colored(parts, text, color)
	parts[#parts + 1] = string.format("{%s, %s}", text:gsub("[{}]", ""), color)
end

-- Requisitos coloreados: "Requiere STR 20, AGI 40." (verde claro si lo cumples, rojo si no)
local function addRequirements(parts, list)
	if #list == 0 then
		return
	end
	colored(parts, "\nRequiere ", Mubia.LookColors.info)
	for i, requirement in ipairs(list) do
		if i > 1 then
			colored(parts, ", ", Mubia.LookColors.info)
		end
		colored(parts, requirement.text, requirement.ok and Mubia.LookColors.ok or Mubia.LookColors.missing)
	end
	colored(parts, ".", Mubia.LookColors.info)
end

-- Texto completo al mirar un item de MU (sets, armas, escudos, alas y mascotas), con colores.
-- Devuelve nil si no es un item de MU (se usa la descripción normal de Tibia).
function Mubia.getItemLookMarkup(player, item)
	local itemId = item:getId()
	local gear = Mubia.Gear[itemId]
	local wing = Mubia.Wings[itemId]
	local pet = Mubia.Pets and Mubia.Pets[itemId]
	if not gear and not wing and not pet then
		return nil
	end

	local article = item:getArticle()
	local name = (article ~= "" and article .. " " or "") .. item:getName()
	local parts = {}
	colored(parts, "You see " .. name .. ".", Mubia.LookColors.name)

	local stats = {}
	if gear and gear.defense then
		stats[#stats + 1] = string.format("Defensa: %d.", gear.defense)
	end
	if gear and gear.min then
		stats[#stats + 1] = string.format("Daño: %d - %d%s.", gear.min, gear.max, gear.twoHanded and " (dos manos)" or "")
	end
	if gear and gear.magic then
		stats[#stats + 1] = string.format("Daño mágico: +%d%%.", gear.magic)
	end
	for _, line in ipairs(Mubia.getItemStatLines(item)) do
		stats[#stats + 1] = line
	end
	for _, line in ipairs(stats) do
		colored(parts, "\n" .. line, Mubia.LookColors.name)
	end

	local options = Mubia.getItemOptionLines(item)
	if pet then
		for _, line in ipairs(Mubia.getPetLines(item, false)) do
			options[#options + 1] = line
		end
	end
	for _, line in ipairs(options) do
		colored(parts, "\n" .. line, Mubia.LookColors.option)
	end

	local requirements = {}
	if gear then
		colored(parts, "\nClase: " .. classNames(gear) .. ".", Mubia.LookColors.info)
		local strDecrease, agiDecrease = Mubia.getHarmonyRequirementDecrease(item)
		local playerStats = Mubia.getStats(player)
		local needStr, needAgi = math.max(0, gear.str - strDecrease), math.max(0, gear.agi - agiDecrease)
		requirements[#requirements + 1] = { text = "STR " .. needStr, ok = playerStats.str >= needStr }
		requirements[#requirements + 1] = { text = "AGI " .. needAgi, ok = playerStats.agi >= needAgi }
		if gear.level then
			requirements[#requirements + 1] = { text = "Nivel " .. gear.level, ok = player:getLevel() >= gear.level }
		end
	elseif wing then
		colored(parts, "\nClase: " .. Mubia.Classes[wing.classId].name .. ".", Mubia.LookColors.info)
	elseif pet and pet.level then
		requirements[#requirements + 1] = { text = "Nivel " .. pet.level, ok = player:getLevel() >= pet.level }
	end
	addRequirements(parts, requirements)

	return Mubia.toLatin1(table.concat(parts))
end

-- Sets, armas y escudos de Tibia equipados: se borran (solo existen los de MU)
local GEAR_SLOTS = { CONST_SLOT_HEAD, CONST_SLOT_ARMOR, CONST_SLOT_LEGS, CONST_SLOT_FEET, CONST_SLOT_LEFT, CONST_SLOT_RIGHT }

-- ¿Es un casco, armadura, pantalón, botas, arma o escudo de Tibia?
function Mubia.isTibiaGear(itemId)
	if Mubia.Gear[itemId] or Mubia.Wings[itemId] then
		return false
	end
	local itemType = ItemType(itemId)
	if itemType:isContainer() then
		return false
	end
	local weaponType = itemType:getWeaponType()
	if weaponType ~= WEAPON_NONE and weaponType ~= WEAPON_AMMO then
		return true
	end
	-- casco, armadura, pantalón o botas
	return bit.band(itemType:getSlotPosition(), 1 + 8 + 64 + 128) ~= 0
end

function Mubia.removeTibiaGear(player)
	local removed = 0
	for _, slot in ipairs(GEAR_SLOTS) do
		local item = player:getSlotItem(slot)
		if item and Mubia.isTibiaGear(item:getId()) then
			item:remove()
			removed = removed + 1
		end
	end
	return removed
end

-- Una sola vez por personaje: set inicial de MU de su clase (va a la mochila si el slot está ocupado)
function Mubia.giveStarterGear(player)
	local class = Mubia.getClass(player)
	local store = player:kv():scoped("mubia")
	if not class or store:get("starterGear") then
		return false
	end
	store:set("starterGear", true)
	for classId, ids in pairs(Mubia.StarterGear or {}) do
		if Mubia.Classes[classId] == class then
			for _, itemId in ipairs(ids) do
				local gear = Mubia.Gear[itemId]
				local ok = Mubia.checkGearRequirements(player, itemId)
				local slot = ({ helm = CONST_SLOT_HEAD, armor = CONST_SLOT_ARMOR, pants = CONST_SLOT_LEGS, gloves = CONST_SLOT_GLOVES, boots = CONST_SLOT_FEET })[gear.piece] or CONST_SLOT_LEFT
				if not ok or player:getSlotItem(slot) or not player:addItem(itemId, 1, false, 1, slot) then
					player:addItem(itemId, 1)
				end
			end
		end
	end
	return true
end

-- ¿Puede la clase del jugador usar estas alas?
function Mubia.canUseWings(player, item)
	local wing = Mubia.Wings[item:getId()]
	if not wing then
		return true
	end
	local class = Mubia.getClass(player)
	return class ~= nil and Mubia.Classes[wing.classId] == class
end

-- ¿Puede el jugador ponerse este item de MU (set, arma, escudo, alas o mascota)? Devuelve false y el motivo si no.
function Mubia.checkEquipRequirements(player, item)
	local itemId = item:getId()
	if Mubia.Wings[itemId] then
		if not Mubia.canUseWings(player, item) then
			return false, string.format("Solo un %s puede usar estas alas.", Mubia.Classes[Mubia.Wings[itemId].classId].name)
		end
		return true
	elseif Mubia.Pets and Mubia.Pets[itemId] then
		return Mubia.checkPetRequirements(player, itemId)
	end
	return Mubia.checkGearRequirements(player, itemId, item)
end
