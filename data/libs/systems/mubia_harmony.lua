-- Mubia Online: Jewel of Harmony, Jewel of Luck y Jewel of Excellent.
-- Harmony (como en MU Season 6): una opción extra por item que tiene nivel 0 a 13. La Jewel of Harmony
-- le da una opción al azar y, si ya tiene, la sube un nivel (nunca por encima del nivel +X del item).
-- Se guarda en el item como muHarmony (número de opción) y muHarmonyLevel.

Mubia.JEWEL_OF_HARMONY = 60319
Mubia.JEWEL_OF_LUCK = 60320
Mubia.JEWEL_OF_EXCELLENT = 60321

Mubia.HarmonyConfig = {
	maxLevel = 13,
	addChance = 80, -- % de éxito al darle la primera opción
	upgradeChance = 60, -- % de éxito al subirla un nivel (si falla, no pasa nada: solo se gasta la joya)
}

-- value = valor por nivel de Harmony (0 a 13). stat = qué suma en Mubia.getEquipmentBonus.
Mubia.HarmonyOptions = {
	weapon = {
		{ key = "MIN", text = "Daño mínimo +%d", stat = "minAttack", value = { 2, 3, 4, 5, 6, 7, 9, 11, 12, 14, 15, 16, 17, 20 } },
		{ key = "MAX", text = "Daño máximo +%d", stat = "maxAttack", value = { 3, 4, 5, 6, 7, 8, 10, 12, 14, 17, 20, 23, 26, 29 } },
		{ key = "STR", text = "STR requerida -%d", stat = "strDecrease", value = { 6, 8, 10, 12, 14, 16, 20, 23, 26, 29, 32, 35, 37, 40 } },
		{ key = "AGI", text = "AGI requerida -%d", stat = "agiDecrease", value = { 6, 8, 10, 12, 14, 16, 20, 23, 26, 29, 32, 35, 37, 40 } },
		{ key = "DMG", text = "Daño mínimo y máximo +%d", stat = "attack", value = { 2, 3, 4, 5, 6, 7, 9, 11, 12, 14, 15, 16, 17, 20 } },
		{ key = "CRIT", text = "Daño de golpe crítico +%d", stat = "criticalDamage", value = { 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 34, 36, 40 } },
		{ key = "SKILL", text = "Daño de skills +%d", stat = "skillDamage", value = { 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 34, 36, 40 } },
	},
	staff = {
		{ key = "MAGIC", text = "Daño mágico +%d", stat = "wizardry", value = { 6, 8, 10, 12, 14, 16, 17, 18, 19, 21, 23, 25, 27, 31 } },
		{ key = "STR", text = "STR requerida -%d", stat = "strDecrease", value = { 6, 8, 10, 12, 14, 16, 20, 23, 26, 29, 32, 35, 37, 40 } },
		{ key = "AGI", text = "AGI requerida -%d", stat = "agiDecrease", value = { 6, 8, 10, 12, 14, 16, 20, 23, 26, 29, 32, 35, 37, 40 } },
		{ key = "SKILL", text = "Daño de skills +%d", stat = "skillDamage", value = { 7, 10, 13, 16, 19, 22, 25, 28, 31, 34, 37, 40, 43, 46 } },
		{ key = "CRIT", text = "Daño de golpe crítico +%d", stat = "criticalDamage", value = { 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 34, 36 } },
	},
	armor = {
		{ key = "DEF", text = "Defensa +%d", stat = "defense", value = { 3, 4, 5, 6, 7, 8, 10, 12, 14, 16, 18, 20, 22, 25 } },
		{ key = "HP", text = "Vida máxima +%d", stat = "maxHealth", value = { 7, 8, 9, 10, 11, 12, 14, 16, 18, 20, 22, 24, 26, 28 } },
		{ key = "AG", text = "AG máximo +%d", stat = "maxAg", value = { 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30 } },
		{ key = "DD", text = "Daño recibido -%d", stat = "damageDecrease", value = { 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 } },
	},
}

local ATTR_HARMONY = "muHarmony"
local ATTR_HARMONY_LEVEL = "muHarmonyLevel"

-- Qué lista usa el item: "weapon", "staff" o "armor" (sets y escudos). Las alas no llevan Harmony.
function Mubia.getHarmonyGroup(item)
	local kind = Mubia.getItemKind(item)
	if kind == "armor" or kind == "shield" then
		return "armor"
	elseif kind == "weapon" or kind == "staff" then
		return kind
	end
	return nil
end

-- La opción Harmony del item (o nil) y su nivel
function Mubia.getHarmony(item)
	local group = Mubia.HarmonyOptions[Mubia.getHarmonyGroup(item) or ""]
	local index = tonumber(item:getCustomAttribute(ATTR_HARMONY))
	if not group or not index or not group[index] then
		return nil, 0
	end
	return group[index], tonumber(item:getCustomAttribute(ATTR_HARMONY_LEVEL)) or 0
end

function Mubia.getHarmonyValue(item)
	local option, level = Mubia.getHarmony(item)
	if not option then
		return nil, 0
	end
	return option, option.value[math.min(level, Mubia.HarmonyConfig.maxLevel) + 1]
end

function Mubia.setHarmony(item, index, level)
	item:setCustomAttribute(ATTR_HARMONY, index)
	item:setCustomAttribute(ATTR_HARMONY_LEVEL, level)
	Mubia.refreshItemText(item)
end

function Mubia.getHarmonyLines(item)
	local option, value = Mubia.getHarmonyValue(item)
	if not option then
		return {}
	end
	local _, level = Mubia.getHarmony(item)
	return { string.format("Harmony (nivel %d): %s.", level, string.format(option.text, value)) }
end

-- Suma la opción Harmony del item a los bonus del equipo (se llama desde Mubia.getEquipmentBonus)
function Mubia.addHarmonyBonus(bonus, item)
	local option, value = Mubia.getHarmonyValue(item)
	if not option then
		return
	end
	if option.stat == "attack" then
		bonus.harmony.minAttack = bonus.harmony.minAttack + value
		bonus.harmony.maxAttack = bonus.harmony.maxAttack + value
	elseif option.stat == "wizardry" then
		bonus.wizardry = bonus.wizardry + value
	elseif option.stat == "defense" then
		bonus.defense = bonus.defense + value
	elseif option.stat == "maxAg" then
		-- si el servidor tiene la barra de AG (mubia_sdag.lua) suma ahí; si no, da mana
		if bonus.exc.wingAg then
			bonus.exc.wingAg = bonus.exc.wingAg + value
		else
			bonus.harmony.maxMana = bonus.harmony.maxMana + value
		end
	elseif bonus.harmony[option.stat] then
		bonus.harmony[option.stat] = bonus.harmony[option.stat] + value
	end
end

function Mubia.newHarmonyBonus()
	return { minAttack = 0, maxAttack = 0, criticalDamage = 0, skillDamage = 0, maxHealth = 0, maxMana = 0, damageDecrease = 0 }
end

-- Cuánto baja la STR y AGI requerida un item por su opción Harmony
function Mubia.getHarmonyRequirementDecrease(item)
	local option, value = Mubia.getHarmonyValue(item)
	if option and option.stat == "strDecrease" then
		return value, 0
	elseif option and option.stat == "agiDecrease" then
		return 0, value
	end
	return 0, 0
end

-- Jewel of Harmony: da una opción al azar o sube la que tiene. Devuelve si se gasta la joya y el mensaje.
function Mubia.useHarmony(target)
	local groupName = Mubia.getHarmonyGroup(target)
	if not groupName then
		return false, "La Jewel of Harmony solo sirve en sets, armas, bastones y escudos de MU."
	end
	local config = Mubia.HarmonyConfig
	local option, level = Mubia.getHarmony(target)
	if not option then
		if math.random(100) > config.addChance then
			return true, string.format("Falló (tenía %d%% de éxito). Prueba de nuevo.", config.addChance)
		end
		local group = Mubia.HarmonyOptions[groupName]
		Mubia.setHarmony(target, math.random(#group), 0)
		local newOption, value = Mubia.getHarmonyValue(target)
		return true, string.format("¡Éxito! Opción Harmony: %s.", string.format(newOption.text, value))
	end

	local itemLevel = Mubia.getItemLevel(target)
	if level >= config.maxLevel then
		return false, string.format("La opción Harmony ya está en el nivel máximo (%d).", config.maxLevel)
	end
	if level >= itemLevel then
		return false, string.format("La opción Harmony no puede pasar el nivel del item (+%d). Sube el item primero.", itemLevel)
	end
	if math.random(100) > config.upgradeChance then
		return true, string.format("Falló (tenía %d%% de éxito). La opción Harmony sigue en nivel %d.", config.upgradeChance, level)
	end
	Mubia.setHarmony(target, tonumber(target:getCustomAttribute(ATTR_HARMONY)), level + 1)
	local _, value = Mubia.getHarmonyValue(target)
	return true, string.format("¡Éxito! Harmony nivel %d: %s.", level + 1, string.format(option.text, value))
end

-- Jewel of Luck: le da Luck a un item de MU (siempre sale bien)
function Mubia.useLuckJewel(target)
	if not Mubia.getItemKind(target) then
		return false, "La Jewel of Luck solo sirve en sets, armas, escudos y alas de MU."
	end
	if Mubia.hasLuck(target) then
		return false, "Este item ya tiene Luck."
	end
	Mubia.setLuck(target, true)
	return true, "¡Listo! Tu item ahora tiene Luck."
end

-- Jewel of Excellent: suma una opción Excellent nueva a un item que ya es Excellent
function Mubia.useExcellentJewel(target)
	if not Mubia.getExcellentGroup(target) or Mubia.getExcellentMask(target) == 0 then
		return false, "La Jewel of Excellent solo sirve en items Excellent (o alas que ya tengan una opción)."
	end
	local current = Mubia.getExcellentKeys(target)
	local missing = {}
	for _, key in ipairs(Mubia.getAvailableExcellentKeys(target)) do
		if not table.contains(current, key) then
			missing[#missing + 1] = key
		end
	end
	if #missing == 0 then
		return false, "Este item ya tiene todas las opciones Excellent."
	end
	local key = missing[math.random(#missing)]
	current[#current + 1] = key
	Mubia.setExcellentKeys(target, current)
	for _, line in ipairs(Mubia.getExcellentLines(target)) do
		if line:find("^" .. key .. ":") then
			return true, "¡Listo! Nueva opción " .. line
		end
	end
	return true, "¡Listo! Nueva opción Excellent: " .. key .. "."
end
