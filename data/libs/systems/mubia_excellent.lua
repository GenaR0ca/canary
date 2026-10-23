-- Mubia Online: Luck y opciones Excellent de los items de MU (Season 6).
-- Se guardan en el item como muLuck (1 = tiene Luck) y muExc (las opciones, como bits: 1, 2, 4, 8...).
-- Los items salen al azar con Luck, opción adicional y Excellent al caer de los monstruos
-- y al crearse en la Chaos Machine (Mubia.rollItemOptions).

Mubia.ExcellentConfig = {
	-- Al caer de un monstruo, cada item de MU (sets, armas y escudos):
	luckChance = 15, -- % de que tenga Luck
	optionChance = 20, -- % de que tenga opción adicional (+4, a veces +8 o +12)
	excellentChance = 3, -- % de que sea Excellent
	excellentLuckChance = 50, -- % de Luck si es Excellent
	-- Cuántas opciones Excellent: { cantidad, % }
	excellentOptionCount = { { 1, 70 }, { 2, 25 }, { 3, 5 } },
	-- Alas de 2da y 3ra generación (al crearlas en la Chaos Machine)
	wingLuckChance = 20,
	wingOptionChance = 60, -- % de que tengan una opción de alas
	-- Luck: suma este % de éxito a Jewel of Soul y a la Chaos Machine, y da golpe crítico
	luckSuccessRate = 25,
	luckCriticalRate = 5,
}

-- Opciones Excellent por tipo de item. key = sigla (como en MU), text = qué hace (para la descripción).
Mubia.ExcellentOptions = {
	armor = {
		{ key = "MH", text = "Vida máxima +4%" },
		{ key = "SD", text = "SD máximo +4%" },
		{ key = "DD", text = "Reduce el daño recibido 4%" },
		{ key = "REF", text = "Devuelve el 5% del daño recibido" },
		{ key = "DSR", text = "Defensa contra monstruos +10%" },
		{ key = "ZEN", text = "Zen de los monstruos +30%" },
	},
	weapon = {
		{ key = "EXE", text = "Golpe excelente +10%" },
		{ key = "DMGL", text = "Daño +nivel/20" },
		{ key = "DMG", text = "Daño +2%" },
		{ key = "ASPD", text = "Velocidad de ataque +7%" },
		{ key = "RHP", text = "Recupera vida/8 al matar un monstruo" },
		{ key = "RMP", text = "Recupera mana/8 al matar un monstruo" },
	},
	-- Alas: las de 2da generación usan HP, MANA, AG e IGNOR; las de 3ra RMP, RHP, ARR e IGNOR (como en MU)
	wings = {
		{ key = "HP", text = "Vida máxima +50 (+5 por nivel)", tiers = { 2 } },
		{ key = "MANA", text = "Mana máximo +50 (+5 por nivel)", tiers = { 2 } },
		{ key = "AG", text = "AG máximo +50 (+5 por nivel)", tiers = { 2 } },
		{ key = "RMP", text = "5% de recuperar todo el mana al recibir daño", tiers = { 3 } },
		{ key = "RHP", text = "5% de recuperar toda la vida al recibir daño", tiers = { 3 } },
		{ key = "ARR", text = "5% de devolver el golpe al atacante", tiers = { 3 } },
		{ key = "IGNOR", text = "5% de ignorar la defensa del enemigo", tiers = { 2, 3 } },
	},
}

local ATTR_LUCK = "muLuck"
local ATTR_EXC = "muExc"
local ATTR_ROLLED = "muRolled"

-- Qué lista de opciones usa un item: "armor" (sets y escudos), "weapon" (armas y bastones) o "wings"
function Mubia.getExcellentGroup(item)
	local kind = Mubia.getItemKind(item)
	if kind == "armor" or kind == "shield" then
		return "armor"
	elseif kind == "weapon" or kind == "staff" then
		return "weapon"
	elseif kind == "wings" then
		local wing = Mubia.Wings[item:getId()]
		return wing.tier >= 2 and "wings" or nil
	end
	return nil
end

function Mubia.hasLuck(item)
	return tonumber(item:getCustomAttribute(ATTR_LUCK)) == 1
end

function Mubia.getExcellentMask(item)
	return tonumber(item:getCustomAttribute(ATTR_EXC)) or 0
end

-- Siglas de las opciones Excellent del item, por ejemplo { "MH", "DD" }
function Mubia.getExcellentKeys(item)
	local group = Mubia.ExcellentOptions[Mubia.getExcellentGroup(item) or ""]
	local mask = Mubia.getExcellentMask(item)
	local keys = {}
	if group then
		for i, option in ipairs(group) do
			if bit.band(mask, 2 ^ (i - 1)) ~= 0 then
				keys[#keys + 1] = option.key
			end
		end
	end
	return keys
end

-- Items Excellent (los de alas con opción no se llaman Excellent, como en MU)
function Mubia.isExcellent(item)
	return Mubia.getExcellentMask(item) > 0 and Mubia.getExcellentGroup(item) ~= "wings"
end

function Mubia.setLuck(item, luck)
	item:setCustomAttribute(ATTR_LUCK, luck and 1 or 0)
	Mubia.refreshItemText(item)
end

-- keys: lista de siglas, por ejemplo { "MH", "DD" }
function Mubia.setExcellentKeys(item, keys)
	local group = Mubia.ExcellentOptions[Mubia.getExcellentGroup(item) or ""]
	if not group then
		return false
	end
	local wanted = {}
	for _, key in ipairs(keys) do
		wanted[key:upper()] = true
	end
	local mask = 0
	for i, option in ipairs(group) do
		if wanted[option.key] then
			mask = mask + 2 ^ (i - 1)
		end
	end
	item:setCustomAttribute(ATTR_EXC, mask)
	Mubia.refreshItemText(item)
	return true
end

-- Opciones que puede tener este item (las alas según su generación)
local function availableOptions(item)
	local groupName = Mubia.getExcellentGroup(item)
	local group = Mubia.ExcellentOptions[groupName or ""]
	if not group then
		return {}
	end
	local tier = groupName == "wings" and Mubia.Wings[item:getId()].tier
	local list = {}
	for _, option in ipairs(group) do
		if not option.tiers or table.contains(option.tiers, tier) then
			list[#list + 1] = option.key
		end
	end
	return list
end

-- Siglas de todas las opciones que puede tener este item
function Mubia.getAvailableExcellentKeys(item)
	return availableOptions(item)
end

-- Elige "count" opciones al azar (distintas) para el item
function Mubia.randomExcellentKeys(item, count)
	local list = availableOptions(item)
	local keys = {}
	for _ = 1, math.min(count, #list) do
		local index = math.random(#list)
		keys[#keys + 1] = table.remove(list, index)
	end
	return keys
end

local function rollCount(list)
	local roll = math.random(100)
	for _, entry in ipairs(list) do
		roll = roll - entry[2]
		if roll <= 0 then
			return entry[1]
		end
	end
	return list[1][1]
end

-- Tira los dados de un item nuevo: Luck, opción adicional y Excellent. Solo una vez por item.
-- Devuelve true si salió Excellent.
function Mubia.rollItemOptions(item)
	local group = Mubia.getExcellentGroup(item)
	if not Mubia.getItemKind(item) or item:getCustomAttribute(ATTR_ROLLED) then
		return false
	end
	item:setCustomAttribute(ATTR_ROLLED, 1)
	local config = Mubia.ExcellentConfig

	if Mubia.getItemKind(item) == "wings" then
		if math.random(100) <= config.wingLuckChance then
			item:setCustomAttribute(ATTR_LUCK, 1)
		end
		if group and math.random(100) <= config.wingOptionChance then
			item:setCustomAttribute(ATTR_EXC, 0)
			Mubia.setExcellentKeys(item, Mubia.randomExcellentKeys(item, 1))
		end
		Mubia.refreshItemText(item)
		return false
	end

	local excellent = group and math.random(100) <= config.excellentChance
	local luckChance = excellent and config.excellentLuckChance or config.luckChance
	if math.random(100) <= luckChance then
		item:setCustomAttribute(ATTR_LUCK, 1)
	end
	if math.random(100) <= config.optionChance then
		local roll = math.random(100)
		item:setCustomAttribute("muOption", roll <= 70 and 1 or roll <= 90 and 2 or 3)
	end
	if excellent then
		Mubia.setExcellentKeys(item, Mubia.randomExcellentKeys(item, rollCount(config.excellentOptionCount)))
	end
	Mubia.refreshItemText(item)
	return excellent
end

-- Tira los dados de todos los items de MU que haya en un contenedor (el cuerpo de un monstruo)
function Mubia.rollContainerOptions(container)
	local excellent = {}
	for i = container:getSize() - 1, 0, -1 do
		local item = container:getItem(i)
		if item then
			if item:isContainer() then
				for _, name in ipairs(Mubia.rollContainerOptions(item)) do
					excellent[#excellent + 1] = name
				end
			elseif Mubia.rollItemOptions(item) then
				excellent[#excellent + 1] = item:getName()
			end
		end
	end
	return excellent
end

-- Líneas extra de la descripción: Luck y opciones Excellent
function Mubia.getExcellentLines(item)
	local lines = {}
	if Mubia.hasLuck(item) then
		lines[#lines + 1] = string.format("Luck: éxito de Jewel of Soul +%d%%, golpe crítico +%d%%.", Mubia.ExcellentConfig.luckSuccessRate, Mubia.ExcellentConfig.luckCriticalRate)
	end
	local group = Mubia.ExcellentOptions[Mubia.getExcellentGroup(item) or ""]
	local mask = Mubia.getExcellentMask(item)
	if group then
		for i, option in ipairs(group) do
			if bit.band(mask, 2 ^ (i - 1)) ~= 0 then
				lines[#lines + 1] = string.format("%s: %s.", option.key, option.text)
			end
		end
	end
	return lines
end

-- Suma de las opciones de todo el equipo puesto (se llama desde Mubia.getEquipmentBonus)
function Mubia.addExcellentBonus(bonus, item, player)
	bonus.criticalRate = bonus.criticalRate or 0
	if Mubia.hasLuck(item) then
		bonus.criticalRate = bonus.criticalRate + Mubia.ExcellentConfig.luckCriticalRate
	end
	local keys = Mubia.getExcellentKeys(item)
	if #keys == 0 then
		return
	end
	local exc = bonus.exc
	local wingLevel = Mubia.getItemLevel(item)
	for _, key in ipairs(keys) do
		if Mubia.getExcellentGroup(item) == "wings" then
			if key == "HP" then
				exc.wingHp = exc.wingHp + 50 + 5 * wingLevel
			elseif key == "MANA" then
				exc.wingMana = exc.wingMana + 50 + 5 * wingLevel
			elseif key == "AG" then
				exc.wingAg = exc.wingAg + 50 + 5 * wingLevel
			elseif key == "RMP" then
				exc.recoverMana = exc.recoverMana + 5
			elseif key == "RHP" then
				exc.recoverLife = exc.recoverLife + 5
			elseif key == "ARR" then
				exc.returnAttack = exc.returnAttack + 5
			elseif key == "IGNOR" then
				exc.ignoreDefense = exc.ignoreDefense + (Mubia.Wings[item:getId()].tier >= 3 and 5 or 3)
			end
		elseif key == "MH" then
			exc.maxHealth = exc.maxHealth + 4
		elseif key == "SD" then
			exc.maxSd = exc.maxSd + 4
		elseif key == "DD" then
			exc.damageDecrease = exc.damageDecrease + 4
		elseif key == "REF" then
			exc.reflect = exc.reflect + 5
		elseif key == "DSR" then
			exc.defenseRate = exc.defenseRate + 10
		elseif key == "ZEN" then
			exc.zen = exc.zen + 30
		elseif key == "EXE" then
			exc.excellentRate = exc.excellentRate + 10
		elseif key == "DMGL" then
			exc.damageFlat = exc.damageFlat + math.floor(player:getLevel() / 20)
		elseif key == "DMG" then
			exc.damage = exc.damage + 2
		elseif key == "ASPD" then
			exc.attackSpeed = exc.attackSpeed + 7
		elseif key == "RHP" then
			exc.lifeOnKill = exc.lifeOnKill + 1
		elseif key == "RMP" then
			exc.manaOnKill = exc.manaOnKill + 1
		end
	end
end

function Mubia.newExcellentBonus()
	return {
		maxHealth = 0,
		maxMana = 0,
		wingHp = 0,
		wingMana = 0,
		wingAg = 0,
		maxSd = 0,
		damageDecrease = 0,
		reflect = 0,
		defenseRate = 0,
		zen = 0,
		excellentRate = 0,
		damageFlat = 0,
		damage = 0,
		attackSpeed = 0,
		lifeOnKill = 0,
		manaOnKill = 0,
		recoverMana = 0,
		recoverLife = 0,
		returnAttack = 0,
		ignoreDefense = 0,
	}
end

local function chance(percent)
	return percent > 0 and math.random(100) <= percent
end

-- Golpe excelente (EXE: daño máximo x1.2) y golpe crítico (Luck: daño máximo) del atacante.
-- maxDamage = daño máximo del golpe normal (nil en magias: se multiplica el daño). Devuelve el daño nuevo.
function Mubia.applyExcellentHit(bonus, damage, maxDamage, target)
	-- Harmony CRIT: suma daño a los golpes excelentes y críticos
	local criticalDamage = bonus.harmony and bonus.harmony.criticalDamage or 0
	if chance(bonus.exc.excellentRate) then
		target:getPosition():sendMagicEffect(CONST_ME_CRITICAL_DAMAGE)
		return math.floor((maxDamage or damage) * 1.2) + criticalDamage
	end
	if chance(bonus.criticalRate or 0) then
		target:getPosition():sendMagicEffect(CONST_ME_FATAL)
		return (maxDamage or math.floor(damage * 1.1)) + criticalDamage
	end
	return damage
end

-- Ignorar defensa (IGNOR de las alas)
function Mubia.rollIgnoreDefense(bonus)
	return chance(bonus.exc.ignoreDefense)
end

-- Saca vida al atacante sin matarlo (REF y ARR)
local function hurtAttacker(attacker, amount)
	amount = math.min(math.floor(amount), attacker:getHealth() - 1)
	if amount > 0 then
		attacker:addHealth(-amount)
		attacker:getPosition():sendMagicEffect(CONST_ME_HITAREA)
	end
end

-- Después de calcular el daño que recibe un jugador: DD, REF, ARR y recuperar vida/mana (alas)
function Mubia.applyExcellentDefense(targetPlayer, attacker, damage)
	local exc = Mubia.getEquipmentBonus(targetPlayer).exc
	if exc.damageDecrease > 0 then
		damage = math.max(1, math.floor(damage * (100 - exc.damageDecrease) / 100))
	end
	if attacker and attacker ~= targetPlayer then
		if chance(exc.returnAttack) then
			hurtAttacker(attacker, damage)
		elseif exc.reflect > 0 then
			hurtAttacker(attacker, damage * exc.reflect / 100)
		end
	end
	if chance(exc.recoverLife) then
		targetPlayer:addHealth(targetPlayer:getMaxHealth())
		targetPlayer:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
	end
	if chance(exc.recoverMana) then
		targetPlayer:addMana(targetPlayer:getMaxMana())
		targetPlayer:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
	end
	return damage
end

-- RHP / RMP del arma: al matar un monstruo
function Mubia.applyExcellentKill(player)
	local exc = Mubia.getEquipmentBonus(player).exc
	if exc.lifeOnKill > 0 then
		player:addHealth(math.floor(player:getMaxHealth() / 8) * exc.lifeOnKill)
	end
	if exc.manaOnKill > 0 then
		player:addMana(math.floor(player:getMaxMana() / 8) * exc.manaOnKill)
	end
end
