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

-- Nombre y descripción del item según su nivel y opción ("Plate Armor +7", "Opción adicional: Defensa +8")
function Mubia.refreshItemText(item)
	local itemType = item:getType()
	local level = Mubia.getItemLevel(item)
	local option = Mubia.getItemOption(item)
	local kind = Mubia.getItemKind(item)

	if level > 0 then
		item:setAttribute(ITEM_ATTRIBUTE_NAME, string.format("%s +%d", itemType:getName(), level))
	else
		item:removeAttribute(ITEM_ATTRIBUTE_NAME)
	end

	local lines = {}
	local wingStats = Mubia.getWingStats(item)
	if wingStats then
		local wing = Mubia.Wings[item:getId()]
		lines[#lines + 1] = string.format("Alas de %s. Aumenta el daño %d%%. Absorbe el %d%% del daño recibido. Defensa %d.", Mubia.Classes[wing.classId].name, wingStats.damage, wingStats.absorb, wingStats.defense)
	elseif level > 0 then
		local what = (kind == "weapon" or kind == "staff") and "Daño" or "Defensa"
		if kind == "staff" then
			what = "Daño mágico"
		end
		lines[#lines + 1] = string.format("Nivel +%d: %s +%d.", level, what, Mubia.getLevelBonus(level))
	end
	if option > 0 then
		local what = kind == "staff" and "Daño mágico" or (kind == "weapon" or kind == "wings") and "Daño" or "Defensa"
		lines[#lines + 1] = string.format("Opción adicional: %s +%d.", what, option * Mubia.ItemConfig.optionStep)
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
	local bonus = { attack = 0, wizardry = 0, magicRise = 0, defense = 0, wingDamage = 0, wingAbsorb = 0, petDamage = pet.damage or 0, petAbsorb = pet.absorb or 0 }
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
		end
	end
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
function Mubia.checkGearRequirements(player, itemId)
	local gear = Mubia.Gear[itemId]
	if not gear then
		return true
	end
	local class = Mubia.getClass(player)
	if not class or not hasClass(gear, class) then
		return false, string.format("%s solo lo puede usar: %s.", gear.name, classNames(gear))
	end
	local stats = Mubia.getStats(player)
	local missing = {}
	if stats.str < gear.str then
		missing[#missing + 1] = string.format("STR %d (tienes %d)", gear.str, stats.str)
	end
	if stats.agi < gear.agi then
		missing[#missing + 1] = string.format("AGI %d (tienes %d)", gear.agi, stats.agi)
	end
	if gear.level and player:getLevel() < gear.level then
		missing[#missing + 1] = string.format("nivel %d", gear.level)
	end
	if #missing > 0 then
		return false, string.format("Para usar %s necesitas %s.", gear.name, table.concat(missing, ", "))
	end
	return true
end

-- Texto extra al mirar un item de MU: clase, defensa o daño y requisitos
function Mubia.getGearLookText(player, item)
	if Mubia.Pets and Mubia.Pets[item:getId()] then
		return Mubia.getPetLookText(item)
	end
	local gear = Mubia.Gear[item:getId()]
	if not gear then
		return nil
	end
	local lines = { "Clase: " .. classNames(gear) .. "." }
	if gear.defense then
		lines[#lines + 1] = string.format("Defensa: %d.", gear.defense)
	end
	if gear.min then
		lines[#lines + 1] = string.format("Daño: %d - %d%s.", gear.min, gear.max, gear.twoHanded and " (dos manos)" or "")
	end
	if gear.magic then
		lines[#lines + 1] = string.format("Daño mágico: +%d%%.", gear.magic)
	end
	local requirement = string.format("Requiere STR %d, AGI %d", gear.str, gear.agi)
	if gear.level then
		requirement = requirement .. string.format(", nivel %d", gear.level)
	end
	lines[#lines + 1] = requirement .. "."
	local ok = Mubia.checkGearRequirements(player, item:getId())
	if not ok then
		lines[#lines + 1] = "No lo puedes usar."
	end
	return Mubia.toLatin1(table.concat(lines, "\n"))
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
