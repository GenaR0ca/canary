-- Mubia Online: items estilo MU Online (Season 6).
-- Nivel del item +0 a +15 (Jewel of Bless y Jewel of Soul), opción adicional +4 a +28 (Jewel of Life)
-- y alas en su propio slot (CONST_SLOT_WINGS). El nivel y la opción se guardan en el item.

Mubia.ItemConfig = {
	maxLevel = 15,
	maxOption = 7, -- cada nivel de opción suma optionStep (7 x 4 = +28)
	optionStep = 4,
	-- Jewel of Bless: sube de +0 a +6, siempre sale bien
	blessMaxLevel = 6,
	-- Jewel of Soul: sube de +6 a +15. Probabilidad de éxito según el nivel al que se quiere llegar.
	-- Si falla, el item baja soulFailLevels niveles (nunca por debajo de +0).
	soulChance = { [7] = 50, [8] = 50, [9] = 50, [10] = 45, [11] = 40, [12] = 35, [13] = 30, [14] = 25, [15] = 20 },
	soulFailLevels = 1,
	-- Jewel of Life: probabilidad de éxito. Si falla, se pierde la opción (vuelve a +0).
	lifeChance = 50,
	lifeFailReset = true,
	-- Bonus por cada nivel del item (daño en armas, defensa en armaduras, escudos y alas)
	levelBonus = { 3, 3, 3, 3, 3, 3, 3, 3, 3, 4, 5, 6, 7, 8, 9 },
}

-- Slot de alas (lo define canary.exe desde la fase 2; 12 por si el .exe todavía es el viejo)
CONST_SLOT_WINGS = CONST_SLOT_WINGS or 12

Mubia.JEWEL_OF_BLESS = 60303
Mubia.JEWEL_OF_SOUL = 60301
Mubia.JEWEL_OF_LIFE = 60302

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

local SLOTP_HEAD = 1
local SLOTP_ARMOR = 8
local SLOTP_LEGS = 64
local SLOTP_FEET = 128
local ARMOR_SLOTS = SLOTP_HEAD + SLOTP_ARMOR + SLOTP_LEGS + SLOTP_FEET

local ATTR_LEVEL = "muLevel"
local ATTR_OPTION = "muOption"

-- Qué tipo de item MU es: "weapon", "staff", "armor", "shield", "wings" o nil si no se puede mejorar
function Mubia.getItemKind(item)
	if Mubia.Wings[item:getId()] then
		return "wings"
	end
	local itemType = item:getType()
	if itemType:isStackable() then
		return nil
	end
	local weaponType = itemType:getWeaponType()
	if weaponType == WEAPON_SHIELD then
		return "shield"
	elseif weaponType == WEAPON_WAND then
		return "staff"
	elseif weaponType ~= WEAPON_NONE and weaponType ~= WEAPON_AMMO then
		return "weapon"
	end
	if bit.band(itemType:getSlotPosition(), ARMOR_SLOTS) ~= 0 then
		return "armor"
	end
	return nil
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

-- Bonus de los items equipados: daño físico, daño mágico, defensa y alas
function Mubia.getEquipmentBonus(player)
	local bonus = { attack = 0, wizardry = 0, defense = 0, wingDamage = 0, wingAbsorb = 0 }
	local slots = { CONST_SLOT_HEAD, CONST_SLOT_ARMOR, CONST_SLOT_LEGS, CONST_SLOT_FEET, CONST_SLOT_LEFT, CONST_SLOT_RIGHT, CONST_SLOT_WINGS }
	for _, slot in ipairs(slots) do
		local item = player:getSlotItem(slot)
		local kind = item and Mubia.getItemKind(item)
		if kind then
			local itemType = item:getType()
			local levelBonus = Mubia.getLevelBonus(Mubia.getItemLevel(item))
			local optionBonus = Mubia.getItemOption(item) * Mubia.ItemConfig.optionStep
			if kind == "weapon" then
				bonus.attack = bonus.attack + levelBonus + optionBonus
			elseif kind == "staff" then
				bonus.wizardry = bonus.wizardry + levelBonus + optionBonus
			elseif kind == "shield" then
				bonus.defense = bonus.defense + itemType:getDefense() + levelBonus + optionBonus
			elseif kind == "armor" then
				bonus.defense = bonus.defense + itemType:getArmor() + levelBonus + optionBonus
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

-- ¿Puede la clase del jugador usar estas alas?
function Mubia.canUseWings(player, item)
	local wing = Mubia.Wings[item:getId()]
	if not wing then
		return true
	end
	local class = Mubia.getClass(player)
	return class ~= nil and Mubia.Classes[wing.classId] == class
end
