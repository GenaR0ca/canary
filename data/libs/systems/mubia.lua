-- Mubia Online: sistema de personaje estilo MU Online (Season 6 Episodio 3)
-- Stats STR/AGI/VIT/ENE, puntos por nivel, vida/mana/daño/defensa por stats y reset.

Mubia = Mubia or {}

Mubia.Config = {
	pointsPerLevel = 5,
	maxStat = 32767,
	resetLevel = 400,
	resetPointsPerReset = 500, -- puntos extra por cada reset acumulado
	resetCostZen = 0,
	minDamageAfterDefense = 0.1, -- el golpe nunca baja de este % aunque la defensa sea alta
	opcode = 80, -- opcode extendido para la ventana de stats del cliente
}

Mubia.STATS = { "str", "agi", "vit", "ene" }

Mubia.STAT_NAMES = {
	str = "Strength",
	agi = "Agility",
	vit = "Vitality",
	ene = "Energy",
}

-- Clases MU, indexadas por el baseid de vocations.xml
Mubia.CLASS_DK = 4
Mubia.CLASS_DW = 1
Mubia.CLASS_ELF = 3

Mubia.Classes = {
	[Mubia.CLASS_DK] = {
		name = "Dark Knight",
		base = { str = 28, agi = 20, vit = 25, ene = 10 },
		hp = { base = 110, perLevel = 2, perVit = 3 },
		mana = { base = 20, perLevel = 0.5, perEne = 1 },
		damage = function(s)
			return math.floor(s.str / 6), math.floor(s.str / 4)
		end,
		defense = function(s)
			return math.floor(s.agi / 3)
		end,
	},
	[Mubia.CLASS_DW] = {
		name = "Dark Wizard",
		base = { str = 18, agi = 18, vit = 15, ene = 30 },
		hp = { base = 60, perLevel = 1, perVit = 2 },
		mana = { base = 60, perLevel = 2, perEne = 2 },
		damage = function(s)
			-- daño de magia (wizardry)
			return math.floor(s.ene / 9), math.floor(s.ene / 4)
		end,
		defense = function(s)
			return math.floor(s.agi / 4)
		end,
	},
	[Mubia.CLASS_ELF] = {
		name = "Fairy Elf",
		base = { str = 22, agi = 25, vit = 20, ene = 15 },
		hp = { base = 80, perLevel = 1, perVit = 2 },
		mana = { base = 30, perLevel = 1.5, perEne = 1.5 },
		damage = function(s)
			return math.floor(s.agi / 7 + s.str / 14), math.floor(s.agi / 4 + s.str / 8)
		end,
		defense = function(s)
			return math.floor(s.agi / 10)
		end,
	},
}

-- El cliente muestra los textos en Latin-1: convierte las letras con tilde y la ñ desde UTF-8.
function Mubia.toLatin1(text)
	return (text:gsub("([\194\195])([\128-\191])", function(lead, byte)
		return string.char((lead:byte() - 194) * 64 + byte:byte())
	end))
end

function Mubia.sendMessage(player, messageType, text)
	player:sendTextMessage(messageType, Mubia.toLatin1(text))
end

function Mubia.getClass(player)
	local vocation = player:getVocation()
	if not vocation then
		return nil
	end
	return Mubia.Classes[vocation:getBaseId()]
end

local function kv(player)
	return player:kv():scoped("mubia")
end

function Mubia.getStats(player)
	local store = kv(player)
	local stats = {}
	for _, key in ipairs(Mubia.STATS) do
		stats[key] = store:get(key) or 0
	end
	stats.points = store:get("points") or 0
	stats.resets = store:get("resets") or 0
	return stats
end

function Mubia.saveStats(player, stats)
	local store = kv(player)
	for _, key in ipairs(Mubia.STATS) do
		store:set(key, stats[key])
	end
	store:set("points", stats.points)
	store:set("resets", stats.resets)
end

-- Primera vez que entra un personaje: stats base de su clase y puntos de los niveles que ya tenga.
function Mubia.initPlayer(player)
	local class = Mubia.getClass(player)
	if not class then
		return false
	end

	local store = kv(player)
	if store:get("initialized") then
		return true
	end

	local stats = {
		points = (player:getLevel() - 1) * Mubia.Config.pointsPerLevel,
		resets = 0,
	}
	for _, key in ipairs(Mubia.STATS) do
		stats[key] = class.base[key]
	end
	Mubia.saveStats(player, stats)
	store:set("initialized", true)
	return true
end

function Mubia.getMaxHealth(player, class, stats)
	local hp = class.hp
	return math.max(1, math.floor(hp.base + hp.perLevel * (player:getLevel() - 1) + hp.perVit * (stats.vit - class.base.vit)))
end

function Mubia.getMaxMana(player, class, stats)
	local mana = class.mana
	return math.max(0, math.floor(mana.base + mana.perLevel * (player:getLevel() - 1) + mana.perEne * (stats.ene - class.base.ene)))
end

-- Recalcula vida y mana máximas a partir de nivel y stats.
function Mubia.recalc(player)
	local class = Mubia.getClass(player)
	if not class then
		return
	end

	local stats = Mubia.getStats(player)
	local maxHealth = Mubia.getMaxHealth(player, class, stats)
	local maxMana = Mubia.getMaxMana(player, class, stats)

	player:setMaxHealth(maxHealth)
	player:setMaxMana(maxMana)
	if player:getHealth() > maxHealth then
		player:addHealth(maxHealth - player:getHealth())
	end
	if player:getMana() > maxMana then
		player:addMana(maxMana - player:getMana())
	end
end

function Mubia.addPoints(player, amount)
	local stats = Mubia.getStats(player)
	stats.points = stats.points + amount
	Mubia.saveStats(player, stats)
end

-- Reparte puntos en un stat. Devuelve true o false y un mensaje.
function Mubia.addStat(player, stat, amount)
	if not Mubia.STAT_NAMES[stat] then
		return false, "Stat desconocido. Usa str, agi, vit o ene."
	end
	if not Mubia.getClass(player) then
		return false, "Tu clase no usa stats."
	end

	amount = math.floor(tonumber(amount) or 0)
	if amount <= 0 then
		return false, "Escribe cuántos puntos quieres sumar, por ejemplo: /addstr 10"
	end

	local stats = Mubia.getStats(player)
	if amount > stats.points then
		return false, string.format("No tienes suficientes puntos. Te quedan %d.", stats.points)
	end
	if stats[stat] + amount > Mubia.Config.maxStat then
		return false, string.format("%s no puede pasar de %d.", Mubia.STAT_NAMES[stat], Mubia.Config.maxStat)
	end

	stats[stat] = stats[stat] + amount
	stats.points = stats.points - amount
	Mubia.saveStats(player, stats)
	Mubia.recalc(player)
	Mubia.sendStats(player)
	return true, string.format("%s +%d (ahora %d). Puntos libres: %d.", Mubia.STAT_NAMES[stat], amount, stats[stat], stats.points)
end

function Mubia.getDamageRange(player)
	local class = Mubia.getClass(player)
	if not class then
		return 0, 0
	end
	return class.damage(Mubia.getStats(player))
end

function Mubia.getDefense(player)
	local class = Mubia.getClass(player)
	if not class then
		return 0
	end
	return class.defense(Mubia.getStats(player))
end

local function getWeaponAttack(player)
	local attack = 0
	for _, slot in ipairs({ CONST_SLOT_LEFT, CONST_SLOT_RIGHT }) do
		local item = player:getSlotItem(slot)
		if item then
			local itemType = item:getType()
			if itemType:getWeaponType() ~= WEAPON_NONE and itemType:getWeaponType() ~= WEAPON_SHIELD then
				attack = attack + itemType:getAttack()
			end
		end
	end
	return attack
end

local function isHealthDamage(combatType)
	return combatType ~= COMBAT_HEALING and combatType ~= COMBAT_LIFEDRAIN and combatType ~= COMBAT_MANADRAIN and combatType ~= COMBAT_NONE
end

-- Sustituye el daño de Tibia por el de MU. Se llama desde Creature:onDrainHealth.
function Mubia.modifyDamage(target, attacker, typePrimary, damagePrimary, typeSecondary, damageSecondary)
	if not attacker or not target or not isHealthDamage(typePrimary) then
		return damagePrimary, damageSecondary
	end

	local attackerPlayer = attacker:getPlayer()
	if attackerPlayer and Mubia.getClass(attackerPlayer) and damagePrimary > 0 then
		local minDamage, maxDamage = Mubia.getDamageRange(attackerPlayer)
		local weaponAttack = getWeaponAttack(attackerPlayer)
		minDamage = minDamage + math.floor(weaponAttack * 0.8)
		maxDamage = maxDamage + weaponAttack
		damagePrimary = math.random(math.max(1, minDamage), math.max(1, maxDamage))
		damageSecondary = 0
	end

	local targetPlayer = target:getPlayer()
	if targetPlayer and Mubia.getClass(targetPlayer) then
		local total = damagePrimary + damageSecondary
		if total > 0 then
			local defense = Mubia.getDefense(targetPlayer)
			local minimum = math.ceil(total * Mubia.Config.minDamageAfterDefense)
			local reduced = math.max(minimum, total - defense)
			local ratio = reduced / total
			damagePrimary = math.floor(damagePrimary * ratio)
			damageSecondary = reduced - damagePrimary
		end
	end

	return damagePrimary, damageSecondary
end

function Mubia.reset(player)
	if not Mubia.getClass(player) then
		return false, "Tu clase no puede hacer reset."
	end
	if player:getLevel() < Mubia.Config.resetLevel then
		return false, string.format("Necesitas nivel %d para hacer reset.", Mubia.Config.resetLevel)
	end
	if Mubia.Config.resetCostZen > 0 and not player:removeMoneyBank(Mubia.Config.resetCostZen) then
		return false, string.format("El reset cuesta %d zen.", Mubia.Config.resetCostZen)
	end

	local class = Mubia.getClass(player)
	local stats = Mubia.getStats(player)
	stats.resets = stats.resets + 1
	for _, key in ipairs(Mubia.STATS) do
		stats[key] = class.base[key]
	end
	stats.points = stats.resets * Mubia.Config.resetPointsPerReset
	Mubia.saveStats(player, stats)

	player:setLevel(1)
	Mubia.recalc(player)
	player:addHealth(player:getMaxHealth())
	player:addMana(player:getMaxMana())
	player:teleportTo(player:getTown():getTemplePosition())
	player:getPosition():sendMagicEffect(CONST_ME_HOLYAREA)
	Mubia.sendStats(player)
	return true, string.format("Reset completado. Llevas %d reset(s) y tienes %d puntos para repartir.", stats.resets, stats.points)
end

-- Envía los stats al cliente (ventana de stats) en JSON simple.
function Mubia.sendStats(player)
	if not player:isUsingOtClient() then
		return
	end
	local class = Mubia.getClass(player)
	if not class then
		return
	end

	local stats = Mubia.getStats(player)
	local minDamage, maxDamage = class.damage(stats)
	local data = {
		action = "stats",
		class = class.name,
		level = player:getLevel(),
		resets = stats.resets,
		points = stats.points,
		str = stats.str,
		agi = stats.agi,
		vit = stats.vit,
		ene = stats.ene,
		minDamage = minDamage,
		maxDamage = maxDamage,
		defense = class.defense(stats),
		maxHealth = player:getMaxHealth(),
		maxMana = player:getMaxMana(),
	}

	local parts = {}
	for key, value in pairs(data) do
		if type(value) == "string" then
			parts[#parts + 1] = string.format('"%s":"%s"', key, value)
		else
			parts[#parts + 1] = string.format('"%s":%d', key, value)
		end
	end
	player:sendExtendedOpcode(Mubia.Config.opcode, "{" .. table.concat(parts, ",") .. "}")
end
