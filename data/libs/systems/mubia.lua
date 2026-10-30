-- Mubia Online: sistema de personaje estilo MU Online (Season 6 Episodio 3)
-- Stats STR/AGI/VIT/ENE, puntos por nivel, vida/mana/daño/defensa por stats y reset.

Mubia = Mubia or {}

Mubia.Config = {
	pointsPerLevel = 5,
	maxStat = 32767,
	startLevel = 1, -- nivel con el que empieza todo personaje nuevo
	testLevel = 400, -- PRUEBAS: sube una vez a este nivel a todos los personajes (0 = desactivado)
	resetLevel = 400,
	maxLevel = 400, -- como en MU: la experiencia se corta aquí, para seguir hay que hacer reset (0 = sin tope)
	resetPointsPerReset = 1000, -- puntos extra por cada reset acumulado
	resetCostZen = 0,
	minDamageAfterDefense = 0.1, -- el golpe nunca baja de este % aunque la defensa sea alta
	opcode = 80, -- opcode extendido para la ventana de stats del cliente
	-- velocidad: tiempo entre golpes/magias = base / (1 + (AGI / divisor de la clase) / 25)
	attackSpeedBase = 2000,
	castSpeedBase = 1500,
	minAttackSpeed = 300,
	ravenCommandDivisor = 8, -- el Dark Raven pega CMD / este número de daño extra
	berserkerDefense = 25, -- % de defensa que se pierde con Berserker
}

Mubia.STATS = { "str", "agi", "vit", "ene", "cmd" }

Mubia.STAT_NAMES = {
	str = "Strength",
	agi = "Agility",
	vit = "Vitality",
	ene = "Energy",
	cmd = "Command",
}

-- Clases MU, indexadas por el baseid de vocations.xml
Mubia.CLASS_DK = 4
Mubia.CLASS_DW = 1
Mubia.CLASS_ELF = 3
Mubia.CLASS_MG = 11
Mubia.CLASS_DL = 12
Mubia.CLASS_SUMMONER = 13
Mubia.CLASS_RF = 15

Mubia.Classes = {
	[Mubia.CLASS_DK] = {
		name = "Dark Knight",
		base = { str = 28, agi = 20, vit = 25, ene = 10, cmd = 0 },
		hp = { base = 110, perLevel = 2, perVit = 3 },
		mana = { base = 20, perLevel = 0.5, perEne = 1 },
		-- daño físico (golpe normal y skills de arma)
		damage = function(s)
			return math.floor(s.str / 6), math.floor(s.str / 4)
		end,
		defense = function(s)
			return math.floor(s.agi / 3)
		end,
		-- en MU las skills del DK pegan 200% + ENE/10 %
		skillMultiplier = function(s)
			return (200 + s.ene / 10) / 100
		end,
		attackSpeedDiv = 15,
		magicSpeedDiv = 20,
	},
	[Mubia.CLASS_DW] = {
		name = "Dark Wizard",
		base = { str = 18, agi = 18, vit = 15, ene = 30, cmd = 0 },
		hp = { base = 60, perLevel = 1, perVit = 2 },
		mana = { base = 60, perLevel = 2, perEne = 2 },
		damage = function(s)
			return math.floor(s.str / 8), math.floor(s.str / 4)
		end,
		-- daño mágico (wizardry)
		magic = function(s)
			return math.floor(s.ene / 9), math.floor(s.ene / 4)
		end,
		defense = function(s)
			return math.floor(s.agi / 4)
		end,
		attackSpeedDiv = 20,
		magicSpeedDiv = 10,
	},
	[Mubia.CLASS_ELF] = {
		name = "Fairy Elf",
		base = { str = 22, agi = 25, vit = 20, ene = 15, cmd = 0 },
		hp = { base = 80, perLevel = 1, perVit = 2 },
		mana = { base = 30, perLevel = 1.5, perEne = 1.5 },
		damage = function(s)
			return math.floor(s.agi / 7 + s.str / 14), math.floor(s.agi / 4 + s.str / 8)
		end,
		defense = function(s)
			return math.floor(s.agi / 10)
		end,
		attackSpeedDiv = 30,
		magicSpeedDiv = 30,
	},
	[Mubia.CLASS_MG] = {
		name = "Magic Gladiator",
		base = { str = 26, agi = 26, vit = 26, ene = 26, cmd = 0 },
		hp = { base = 110, perLevel = 1, perVit = 2 },
		mana = { base = 60, perLevel = 1, perEne = 2 },
		pointsPerLevel = 7,
		noEvolution = true,
		damage = function(s)
			return math.floor(s.str / 6), math.floor(s.str / 4)
		end,
		magic = function(s)
			return math.floor(s.ene / 9), math.floor(s.ene / 4)
		end,
		defense = function(s)
			return math.floor(s.agi / 4)
		end,
		skillMultiplier = function(s)
			return 2
		end,
		attackSpeedDiv = 15,
		magicSpeedDiv = 20,
	},
	[Mubia.CLASS_DL] = {
		name = "Dark Lord",
		base = { str = 26, agi = 20, vit = 20, ene = 15, cmd = 25 },
		hp = { base = 90, perLevel = 1.5, perVit = 2 },
		mana = { base = 40, perLevel = 1, perEne = 1.5 },
		pointsPerLevel = 7,
		noEvolution = true,
		damage = function(s)
			return math.floor(s.str / 7 + s.ene / 14), math.floor(s.str / 5 + s.ene / 10)
		end,
		defense = function(s)
			return math.floor(s.agi / 4)
		end,
		skillMultiplier = function(s)
			return (200 + s.ene / 20) / 100
		end,
		attackSpeedDiv = 15,
		magicSpeedDiv = 20,
	},
	[Mubia.CLASS_SUMMONER] = {
		name = "Summoner",
		base = { str = 21, agi = 21, vit = 18, ene = 23, cmd = 0 },
		hp = { base = 70, perLevel = 1, perVit = 2 },
		mana = { base = 40, perLevel = 1.5, perEne = 2 },
		damage = function(s)
			return math.floor(s.str / 8), math.floor(s.str / 4)
		end,
		-- en MU tiene daño de Curse aparte; acá es el mismo daño mágico
		magic = function(s)
			return math.floor(s.ene / 9), math.floor(s.ene / 4)
		end,
		defense = function(s)
			return math.floor(s.agi / 4)
		end,
		attackSpeedDiv = 20,
		magicSpeedDiv = 15,
	},
	[Mubia.CLASS_RF] = {
		name = "Rage Fighter",
		base = { str = 32, agi = 27, vit = 25, ene = 20, cmd = 0 },
		hp = { base = 100, perLevel = 1.3, perVit = 2 },
		mana = { base = 40, perLevel = 1, perEne = 1.3 },
		pointsPerLevel = 7,
		noEvolution = true,
		damage = function(s)
			return math.floor(s.str / 7 + s.vit / 15), math.floor(s.str / 5 + s.vit / 12)
		end,
		defense = function(s)
			return math.floor(s.agi / 4)
		end,
		attackSpeedDiv = 15,
		magicSpeedDiv = 20,
	},
}

-- Puntos de stats por nivel de la clase (si no tiene los suyos, los de Mubia.Config)
function Mubia.getPointsPerLevel(class)
	return class.pointsPerLevel or Mubia.Config.pointsPerLevel
end

-- Command solo lo usa la clase que empieza con Command (Dark Lord)
function Mubia.classUsesStat(class, stat)
	return stat ~= "cmd" or class.base.cmd > 0
end

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
		points = (player:getLevel() - 1) * Mubia.getPointsPerLevel(class),
		resets = 0,
	}
	for _, key in ipairs(Mubia.STATS) do
		stats[key] = class.base[key]
	end
	Mubia.saveStats(player, stats)
	store:set("initialized", true)
	return true
end

-- Una sola vez por personaje: lo deja en el nivel inicial con los stats base de su clase.
-- Sirve para los personajes creados antes de que Mubia empezara en nivel 1.
function Mubia.applyStartLevel(player)
	local class = Mubia.getClass(player)
	local store = kv(player)
	if not class or store:get("startLevelApplied") then
		return false
	end
	store:set("startLevelApplied", true)

	local stats = Mubia.getStats(player)
	if stats.resets > 0 or player:getLevel() <= Mubia.Config.startLevel then
		return false
	end

	player:removeExperience(player:getExperience() - Game.getExperienceForLevel(Mubia.Config.startLevel), false)
	for _, key in ipairs(Mubia.STATS) do
		stats[key] = class.base[key]
	end
	stats.points = (player:getLevel() - 1) * Mubia.getPointsPerLevel(class)
	Mubia.saveStats(player, stats)
	return true
end

-- PRUEBAS: una sola vez por personaje, lo sube a Mubia.Config.testLevel (gana los puntos de esos niveles).
function Mubia.applyTestLevel(player)
	local target = Mubia.Config.testLevel
	local store = kv(player)
	if target <= 0 or not Mubia.getClass(player) or store:get("testLevelApplied") == target then
		return false
	end
	store:set("testLevelApplied", target)
	if player:getLevel() >= target then
		return false
	end
	player:addExperience(Game.getExperienceForLevel(target) - player:getExperience(), false)
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

local function speedFromAgi(base, agi, divisor)
	local value = math.floor(base / (1 + (agi / divisor) / 25))
	return math.max(Mubia.Config.minAttackSpeed, value)
end

-- Milisegundos entre golpes normales (AGI la baja).
function Mubia.getAttackSpeed(class, stats)
	return speedFromAgi(Mubia.Config.attackSpeedBase, stats.agi, class.attackSpeedDiv)
end

-- Milisegundos de espera entre magias MU (AGI la baja).
function Mubia.getCastSpeed(class, stats)
	return speedFromAgi(Mubia.Config.castSpeedBase, stats.agi, class.magicSpeedDiv)
end

-- Recalcula vida, mana y velocidad de ataque a partir de nivel y stats.
function Mubia.recalc(player)
	local class = Mubia.getClass(player)
	if not class then
		return
	end

	local stats = Mubia.getStats(player)
	local pet = Mubia.getPet and Mubia.getPet(player) or {}
	-- opciones Excellent: MH / SD (+4% cada una), HP / MANA / AG de las alas
	-- y Harmony HP / AG de las armaduras
	local equipment = Mubia.getEquipmentBonus(player)
	local exc, harmony = equipment.exc, equipment.harmony
	local maxHealth = math.floor(Mubia.getMaxHealth(player, class, stats) * (100 + exc.maxHealth) / 100) + exc.wingHp + harmony.maxHealth + (pet.hp or 0)
	local maxMana = math.floor(Mubia.getMaxMana(player, class, stats) * (100 + exc.maxMana) / 100) + exc.wingMana + harmony.maxMana

	player:setMaxHealth(maxHealth)
	player:setMaxMana(maxMana)
	-- setAttackSpeed existe desde el canary.exe de Mubia con velocidad por AGI (la mascota la sube un %)
	if player.setAttackSpeed then
		local attackSpeed = Mubia.getAttackSpeed(class, stats)
		attackSpeed = math.floor(attackSpeed * (100 - (pet.attackSpeed or 0)) / 100)
		attackSpeed = math.floor(attackSpeed * (100 - exc.attackSpeed) / 100) -- ASPD del arma
		attackSpeed = math.floor(attackSpeed * (100 - Mubia.getBuff(player, "drinkSpeed")) / 100) -- Ale / Olive of Love
		player:setAttackSpeed(math.max(Mubia.Config.minAttackSpeed, attackSpeed))
	end
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
		return false, "Stat desconocido. Usa str, agi, vit, ene o cmd."
	end
	if not Mubia.getClass(player) then
		return false, "Tu clase no usa stats."
	end
	if not Mubia.classUsesStat(Mubia.getClass(player), stat) then
		return false, string.format("Tu clase no usa %s.", Mubia.STAT_NAMES[stat])
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
	-- defensa por AGI + armaduras, escudo y alas equipados (con su nivel y opción)
	local defense = class.defense(Mubia.getStats(player)) + Mubia.getEquipmentBonus(player).defense
	if Mubia.getBuff(player, "berserker") > 0 then
		defense = math.floor(defense * (100 - Mubia.Config.berserkerDefense) / 100)
	end
	return defense
end

-- Innovation: el objetivo pierde un % de su defensa
function Mubia.reduceDefense(target, defense)
	local innovation = Mubia.getBuff(target, "innovation")
	if innovation > 0 then
		return math.floor(defense * (100 - innovation) / 100)
	end
	return defense
end

-- Daño mínimo y máximo del arma de MU equipada, con su nivel (+1 a +15) y opción adicional (Jewel of Life) y las alas
function Mubia.getWeaponDamage(player)
	local minDamage, maxDamage = Mubia.getGearWeaponDamage(player)
	local equipment = Mubia.getEquipmentBonus(player)
	local bonus = equipment.attack
	-- Harmony: daño mínimo / máximo del arma
	return minDamage + bonus + equipment.harmony.minAttack, maxDamage + bonus + equipment.harmony.maxAttack
end

local function isHealthDamage(combatType)
	return combatType ~= COMBAT_HEALING and combatType ~= COMBAT_LIFEDRAIN and combatType ~= COMBAT_MANADRAIN and combatType ~= COMBAT_NONE
end

-- Jugadores lanzando ahora mismo una magia MU: su daño ya viene calculado.
Mubia.castingSpell = Mubia.castingSpell or {}

-- Sustituye el daño de Tibia por el de MU. Se llama desde Creature:onDrainHealth.
function Mubia.modifyDamage(target, attacker, typePrimary, damagePrimary, typeSecondary, damageSecondary)
	if not attacker or not target or not isHealthDamage(typePrimary) then
		return damagePrimary, damageSecondary
	end

	-- Vida que se saca a sí mismo (REF, ARR y Damage Reflection del que lo golpeó): ya viene calculada
	if attacker:getId() == target:getId() then
		return damagePrimary, damageSecondary
	end

	-- Dark Raven: su golpe sube con el Command del dueño
	local master = attacker:getMaster()
	local ravenOwner = master and attacker:getName() == "Dark Raven" and master:getPlayer()
	if ravenOwner and damagePrimary > 0 then
		damagePrimary = damagePrimary + math.floor(Mubia.getStats(ravenOwner).cmd / Mubia.Config.ravenCommandDivisor)
	end

	local attackerPlayer = attacker:getPlayer()
	local isMuSpell = attackerPlayer and Mubia.castingSpell[attackerPlayer:getId()]
	if attackerPlayer and not isMuSpell and Mubia.getClass(attackerPlayer) and damagePrimary > 0 then
		local minDamage, maxDamage = Mubia.getDamageRange(attackerPlayer)
		local weaponMin, weaponMax = Mubia.getWeaponDamage(attackerPlayer)
		minDamage = minDamage + weaponMin
		maxDamage = maxDamage + weaponMax
		damagePrimary = math.random(math.max(1, minDamage), math.max(1, maxDamage))
		-- golpe excelente (EXE) y crítico (Luck): daño máximo
		damagePrimary = Mubia.applyExcellentHit(Mubia.getEquipmentBonus(attackerPlayer), damagePrimary, math.max(1, maxDamage), target)
		damagePrimary = damagePrimary + Mubia.getBuff(attackerPlayer, "damage") + Mubia.getBuff(attackerPlayer, "criticalDamage")
		damageSecondary = 0
	elseif isMuSpell and damagePrimary > 0 then
		local bonus = Mubia.getEquipmentBonus(attackerPlayer)
		-- Harmony SKILL: daño extra de skills
		damagePrimary = Mubia.applyExcellentHit(bonus, damagePrimary + bonus.harmony.skillDamage, nil, target)
	end

	-- IGNOR de las alas: este golpe no se reduce por la defensa del enemigo
	local ignoreDefense = false
	if attackerPlayer and damagePrimary > 0 and Mubia.rollIgnoreDefense(Mubia.getEquipmentBonus(attackerPlayer)) then
		ignoreDefense = true
		-- la defensa de los monstruos de MU se resta después (mubia_monsters.lua): se compensa acá
		local wild = Mubia.WildMonsters and target:getMonster() and not target:getMaster() and Mubia.WildMonsters[target:getName()]
		if wild and wild.defense then
			damagePrimary = damagePrimary + Mubia.reduceDefense(target, wild.defense)
		end
	end

	-- Alas, mascota y DMG del arma: aumentan el daño de golpes y magias
	if attackerPlayer and damagePrimary > 0 then
		local bonus = Mubia.getEquipmentBonus(attackerPlayer)
		for _, extra in ipairs({ bonus.wingDamage, bonus.petDamage, bonus.exc.damage }) do
			if extra > 0 then
				damagePrimary = math.floor(damagePrimary * (100 + extra) / 100)
				damageSecondary = math.floor(damageSecondary * (100 + extra) / 100)
			end
		end
	end

	-- Weakness: el atacante pega un % menos
	local weakness = Mubia.getBuff(attacker, "weakness")
	if weakness > 0 then
		damagePrimary = math.floor(damagePrimary * (100 - weakness) / 100)
		damageSecondary = math.floor(damageSecondary * (100 - weakness) / 100)
	end

	local targetPlayer = target:getPlayer()
	if targetPlayer and Mubia.getClass(targetPlayer) then
		local total = damagePrimary + damageSecondary
		if total > 0 then
			local defense = ignoreDefense and 0 or Mubia.reduceDefense(targetPlayer, Mubia.getDefense(targetPlayer) + Mubia.getBuff(targetPlayer, "defense"))
			local minimum = math.ceil(total * Mubia.Config.minDamageAfterDefense)
			local reduced = math.max(minimum, total - defense)
			-- Soul Barrier: quita un % del daño que queda
			local barrier = Mubia.getBuff(targetPlayer, "barrier")
			if barrier > 0 then
				reduced = math.max(1, math.floor(reduced * (100 - barrier) / 100))
			end
			-- Alas y mascota: absorben un % del daño que queda
			local bonus = Mubia.getEquipmentBonus(targetPlayer)
			for _, absorb in ipairs({ bonus.wingAbsorb, bonus.petAbsorb }) do
				if absorb > 0 then
					reduced = math.max(1, math.floor(reduced * (100 - absorb) / 100))
				end
			end
			-- Harmony DD: resta daño fijo
			reduced = math.max(1, reduced - bonus.harmony.damageDecrease)
			-- opciones Excellent: DD, REF, ARR y recuperar vida / mana (alas)
			reduced = Mubia.applyExcellentDefense(targetPlayer, attacker, reduced)
			-- Damage Reflection: devuelve un % al atacante (sin matarlo, como REF)
			local reflection = Mubia.getBuff(targetPlayer, "damageReflection")
			if reflection > 0 then
				Mubia.hurtAttacker(attacker, reduced * reflection / 100)
			end
			-- SD: si te pega otro jugador, el escudo se lleva la mayor parte del golpe
			if attackerPlayer and attackerPlayer ~= targetPlayer and Mubia.absorbWithSD then
				reduced = Mubia.absorbWithSD(targetPlayer, reduced)
			end
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
	-- daño y defensa con el equipo puesto (arma, armaduras, escudo y alas)
	local minDamage, maxDamage = class.damage(stats)
	local weaponMin, weaponMax = Mubia.getWeaponDamage(player)
	minDamage, maxDamage = minDamage + weaponMin, maxDamage + weaponMax
	local equipment = Mubia.getEquipmentBonus(player)
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
		defense = Mubia.getDefense(player),
		minMagic = 0,
		maxMagic = 0,
		attackSpeed = Mubia.getAttackSpeed(class, stats),
		castSpeed = Mubia.getCastSpeed(class, stats),
		maxHealth = player:getMaxHealth(),
		maxMana = player:getMaxMana(),
	}

	if Mubia.classUsesStat(class, "cmd") then
		data.cmd = stats.cmd
	end

	if class.magic then
		local minMagic, maxMagic = class.magic(stats)
		local rise = (100 + equipment.magicRise) / 100 * (100 + Mubia.getBuff(player, "berserker")) / 100
		data.minMagic = math.floor((minMagic + equipment.wizardry) * rise)
		data.maxMagic = math.floor((maxMagic + equipment.wizardry) * rise)
	end

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

-- Magias MU (se registran en data/scripts/mubia/spells.lua y se aprenden con scrolls.lua).
-- Cada magia tiene su scroll; los scrolls de una misma clase comparten dibujo (ver Mubia.ScrollSprites).
--
-- kind: "attack" (daño), "buff", "heal", "recovery", "summon", "teleport" o "debuff" (un enemigo, sin daño)
-- power (solo attack): "skill" = daño físico + arma (DK con su multiplicador), "magic" = daño mágico (ENE)
-- target = necesita objetivo (range casillas), direction = sale hacia donde mira el personaje
-- area = área alrededor del personaje (o del objetivo si target = true)
-- slow / poison / burn / drunk / push / hits / drain = efectos extra sobre los golpeados
-- requiresPet / requiresGear = mascota o libro que hay que tener puesto

-- Item del que copia el dibujo cada scroll de clase (el appearances.dat ya trae los scrolls nuevos)
Mubia.ScrollSprites = {
	[Mubia.CLASS_DK] = 347,
	[Mubia.CLASS_DW] = 22865,
	[Mubia.CLASS_ELF] = 28650,
	[Mubia.CLASS_MG] = 347,
	[Mubia.CLASS_DL] = 347,
	[Mubia.CLASS_SUMMONER] = 22865,
}

-- Primer id de scroll de cada clase; los siguientes van en el orden de Mubia.SpellList.
-- Las magias nuevas se agregan al final de su clase para no cambiar los ids de los scrolls ya creados.
-- Los textos de description van sin tildes ni ñ porque se muestran tal cual en el cliente.
Mubia.ScrollFirstId = {
	[Mubia.CLASS_DK] = 60001,
	[Mubia.CLASS_DW] = 60101,
	[Mubia.CLASS_ELF] = 60201,
	[Mubia.CLASS_MG] = 60901,
	[Mubia.CLASS_DL] = 60911,
	[Mubia.CLASS_SUMMONER] = 60921,
}

Mubia.ClassVocations = {
	[Mubia.CLASS_DK] = { "dark knight;true", "blade knight;true" },
	[Mubia.CLASS_DW] = { "dark wizard;true", "soul master;true" },
	[Mubia.CLASS_ELF] = { "fairy elf;true", "muse elf;true" },
	[Mubia.CLASS_MG] = { "magic gladiator;true" },
	[Mubia.CLASS_DL] = { "dark lord;true" },
	[Mubia.CLASS_SUMMONER] = { "summoner;true", "bloody summoner;true" },
}

-- Magias de DK y DW que también usa el Magic Gladiator (además de las suyas). Las de la evolución no van acá.
Mubia.MGSharedSpells = {
	"twistingSlash", "impale",
	"energyBall", "fireBall", "powerWave", "lightning", "meteorite", "ice", "poison", "flame", "twister", "evilSpirit", "hellfire", "aquaBeam", "cometfall", "inferno",
}

Mubia.SpellList = {
	-- Dark Knight / Blade Knight
	{ key = "twistingSlash", name = "Twisting Slash", classId = Mubia.CLASS_DK, mana = 10, kind = "attack", power = "skill", base = 0, type = COMBAT_PHYSICALDAMAGE, effect = CONST_ME_HITAREA, area = "AREA_CIRCLE2X2", description = "Giro con el arma que golpea a todos alrededor." },
	{ key = "impale", name = "Impale", classId = Mubia.CLASS_DK, mana = 8, kind = "attack", power = "skill", base = 15, type = COMBAT_PHYSICALDAMAGE, effect = CONST_ME_DRAWBLOOD, area = "MUBIA_AREA_LINE3", direction = true, shootEffect = CONST_ANI_SPEAR, description = "Estocada con lanza que atraviesa a los enemigos en linea." },
	{ key = "swellLife", name = "Swell Life", classId = Mubia.CLASS_DK, mana = 22, kind = "buff", buff = "swellLife", description = "Aumenta por un tiempo la vida maxima tuya y de tu party." },
	{ key = "deathStab", name = "Death Stab", classId = Mubia.CLASS_DK, mana = 15, kind = "attack", power = "skill", base = 70, type = COMBAT_PHYSICALDAMAGE, effect = CONST_ME_WHIRLWIND_BLOW_WHITE, target = true, range = 2, description = "Estocada devastadora reforzada con la energia del viento." },
	{ key = "ragefulBlow", name = "Rageful Blow", classId = Mubia.CLASS_DK, mana = 25, kind = "attack", power = "skill", base = 60, type = COMBAT_EARTHDAMAGE, effect = CONST_ME_GROUNDSHAKER, area = "AREA_CIRCLE3X3", description = "Golpe que hace temblar la tierra y golpea a todos los enemigos cercanos." },
	{
		key = "strikeOfDestruction",
		name = "Strike of Destruction",
		classId = Mubia.CLASS_DK,
		mana = 30,
		kind = "attack",
		power = "skill",
		base = 110,
		type = COMBAT_ICEDAMAGE,
		effect = CONST_ME_ICEAREA,
		shootEffect = CONST_ANI_ICE,
		target = true,
		range = 4,
		area = "AREA_CIRCLE2X2",
		slow = { ticks = 3000, percent = 50 },
		description = "Esfera de hielo muy poderosa que reduce la velocidad del enemigo.",
	},

	-- Dark Wizard / Soul Master
	{ key = "energyBall", name = "Energy Ball", classId = Mubia.CLASS_DW, mana = 1, kind = "attack", power = "magic", base = 3, type = COMBAT_ENERGYDAMAGE, effect = CONST_ME_ENERGYHIT, shootEffect = CONST_ANI_ENERGYBALL, target = true, description = "Bola de energia contra un objetivo." },
	{ key = "fireBall", name = "Fire Ball", classId = Mubia.CLASS_DW, mana = 3, kind = "attack", power = "magic", base = 8, type = COMBAT_FIREDAMAGE, effect = CONST_ME_FIREAREA, shootEffect = CONST_ANI_FIRE, target = true, description = "Enorme bola de fuego contra un objetivo." },
	{ key = "powerWave", name = "Power Wave", classId = Mubia.CLASS_DW, mana = 5, kind = "attack", power = "magic", base = 14, type = COMBAT_ENERGYDAMAGE, effect = CONST_ME_ENERGYAREA, shootEffect = CONST_ANI_ENERGY, target = true, description = "Ola de fuerza sacada de la tierra hacia el enemigo." },
	{ key = "lightning", name = "Lightning", classId = Mubia.CLASS_DW, mana = 15, kind = "attack", power = "magic", base = 17, type = COMBAT_ENERGYDAMAGE, effect = CONST_ME_PURPLEENERGY, shootEffect = CONST_ANI_ENERGY, target = true, push = true, description = "Relampago que golpea al enemigo y lo empuja." },
	{ key = "teleport", name = "Teleport", classId = Mubia.CLASS_DW, mana = 30, kind = "teleport", distance = 6, description = "Te transporta varias casillas hacia donde miras." },
	{ key = "meteorite", name = "Meteorite", classId = Mubia.CLASS_DW, mana = 12, kind = "attack", power = "magic", base = 40, type = COMBAT_FIREDAMAGE, effect = CONST_ME_EXPLOSIONAREA, shootEffect = CONST_ANI_EXPLOSION, target = true, description = "Un meteorito cae del cielo sobre el enemigo." },
	{ key = "ice", name = "Ice", classId = Mubia.CLASS_DW, mana = 38, kind = "attack", power = "magic", base = 10, type = COMBAT_ICEDAMAGE, effect = CONST_ME_ICEATTACK, shootEffect = CONST_ANI_SMALLICE, target = true, slow = { ticks = 4000, percent = 50 }, description = "Hielo que congela al enemigo y reduce su velocidad." },
	{ key = "poison", name = "Poison", classId = Mubia.CLASS_DW, mana = 42, kind = "attack", power = "magic", base = 12, type = COMBAT_EARTHDAMAGE, effect = CONST_ME_GREEN_RINGS, shootEffect = CONST_ANI_POISON, target = true, poison = { rounds = 5, interval = 2000, percent = 25 }, description = "Algas venenosas que hacen perder vida lentamente." },
	{ key = "flame", name = "Flame", classId = Mubia.CLASS_DW, mana = 50, kind = "attack", power = "magic", base = 25, type = COMBAT_FIREDAMAGE, effect = CONST_ME_HITBYFIRE, target = true, area = "AREA_SQUARE1X1", burn = { rounds = 4, interval = 1000, percent = 20 }, description = "Pilar de llamas que quema de forma continua." },
	{ key = "twister", name = "Twister", classId = Mubia.CLASS_DW, mana = 60, kind = "attack", power = "magic", base = 35, type = COMBAT_ENERGYDAMAGE, effect = CONST_ME_WHIRLWIND_BLOW_GREEN, area = "AREA_WAVE4", direction = true, drunk = 4000, description = "Ciclones que confunden al enemigo." },
	{ key = "evilSpirit", name = "Evil Spirit", classId = Mubia.CLASS_DW, mana = 40, kind = "attack", power = "magic", base = 45, type = COMBAT_DEATHDAMAGE, effect = CONST_ME_MORTAREA, area = "AREA_CIRCLE3X3", description = "Espiritus malignos que golpean a todos alrededor." },
	{ key = "hellfire", name = "Hellfire", classId = Mubia.CLASS_DW, mana = 160, kind = "attack", power = "magic", base = 120, type = COMBAT_FIREDAMAGE, effect = CONST_ME_FIREAREA, area = "AREA_CIRCLE3X3", description = "Fuego del infierno que brota del suelo alrededor tuyo." },
	{ key = "aquaBeam", name = "Aqua Beam", classId = Mubia.CLASS_DW, mana = 140, kind = "attack", power = "magic", base = 80, type = COMBAT_ICEDAMAGE, effect = CONST_ME_WATERSPLASH, area = "AREA_BEAM8", direction = true, description = "Rayo de agua que atraviesa a varios enemigos." },
	{ key = "cometfall", name = "Cometfall", classId = Mubia.CLASS_DW, mana = 90, kind = "attack", power = "magic", base = 70, type = COMBAT_ENERGYDAMAGE, effect = CONST_ME_BIGCLOUDS, target = true, area = "AREA_SQUARE1X1", description = "Rayo de energia que cae del cielo sobre los enemigos." },
	{ key = "inferno", name = "Inferno", classId = Mubia.CLASS_DW, mana = 200, kind = "attack", power = "magic", base = 100, type = COMBAT_FIREDAMAGE, effect = CONST_ME_FIREAREA, area = "MUBIA_AREA_RING", burn = { rounds = 3, interval = 1000, percent = 15 }, description = "Anillo de fuego a tu alrededor que quema a todos." },
	{ key = "soulBarrier", name = "Soul Barrier", classId = Mubia.CLASS_DW, mana = 70, kind = "buff", buff = "soulBarrier", description = "Esfera de energia que reduce los golpes que recibes segun tu energia." },
	{ key = "iceStorm", name = "Ice Storm", classId = Mubia.CLASS_DW, mana = 100, kind = "attack", power = "magic", base = 80, type = COMBAT_ICEDAMAGE, effect = CONST_ME_ICETORNADO, target = true, area = "AREA_CIRCLE2X2", slow = { ticks = 3000, percent = 40 }, description = "Tormenta de hielo muy poderosa que reduce la velocidad." },
	{ key = "decay", name = "Decay", classId = Mubia.CLASS_DW, mana = 110, kind = "attack", power = "magic", base = 95, type = COMBAT_EARTHDAMAGE, effect = CONST_ME_POISONAREA, shootEffect = CONST_ANI_POISON, target = true, area = "AREA_SQUARE1X1", poison = { rounds = 6, interval = 2000, percent = 20 }, description = "Bolas de veneno muy poderosas que envenenan al enemigo." },

	-- Fairy Elf / Muse Elf
	{ key = "multiShot", name = "Multi-Shot", classId = Mubia.CLASS_ELF, mana = 10, kind = "attack", power = "skill", base = 40, type = COMBAT_PHYSICALDAMAGE, effect = CONST_ME_HITAREA, area = "AREA_WAVE4", fan = true, description = "Abanico de cinco flechas hacia donde miras." },
	{ key = "penetration", name = "Penetration", classId = Mubia.CLASS_ELF, mana = 9, kind = "attack", power = "skill", base = 70, type = COMBAT_PHYSICALDAMAGE, effect = CONST_ME_HITAREA, area = "AREA_BEAM8", direction = true, shootEffect = CONST_ANI_ARROW, description = "Flecha que atraviesa a todos en linea recta." },
	{ key = "heal", name = "Heal", classId = Mubia.CLASS_ELF, mana = 20, kind = "heal", description = "Cura la vida tuya o del miembro de tu party mas herido." },
	{ key = "greaterDefense", name = "Greater Defense", classId = Mubia.CLASS_ELF, mana = 30, kind = "buff", buff = "defense", description = "Aumenta la defensa tuya y de tu party." },
	{ key = "greaterDamage", name = "Greater Damage", classId = Mubia.CLASS_ELF, mana = 40, kind = "buff", buff = "damage", description = "Aumenta el ataque tuyo y de tu party." },
	{ key = "summonGoblin", name = "Summon Goblin", classId = Mubia.CLASS_ELF, mana = 40, kind = "summon", monster = "Summoned Goblin", description = "Invoca un Goblin que te ayuda a pelear." },
	{ key = "summonStoneGolem", name = "Summon Stone Golem", classId = Mubia.CLASS_ELF, mana = 70, kind = "summon", monster = "Summoned Stone Golem", description = "Invoca un Stone Golem que te ayuda a pelear." },
	{ key = "summonAssassin", name = "Summon Assassin", classId = Mubia.CLASS_ELF, mana = 110, kind = "summon", monster = "Summoned Assassin", description = "Invoca un Assassin que te ayuda a pelear." },
	{ key = "summonEliteYeti", name = "Summon Elite Yeti", classId = Mubia.CLASS_ELF, mana = 160, kind = "summon", monster = "Summoned Elite Yeti", description = "Invoca un Elite Yeti que te ayuda a pelear." },
	{ key = "summonDarkKnight", name = "Summon Dark Knight", classId = Mubia.CLASS_ELF, mana = 200, kind = "summon", monster = "Summoned Dark Knight", description = "Invoca un Dark Knight que te ayuda a pelear." },
	{ key = "summonBali", name = "Summon Bali", classId = Mubia.CLASS_ELF, mana = 250, kind = "summon", monster = "Summoned Bali", description = "Invoca un Bali que te ayuda a pelear." },
	{ key = "summonSoldier", name = "Summon Soldier", classId = Mubia.CLASS_ELF, mana = 350, kind = "summon", monster = "Summoned Soldier", description = "Invoca un Soldier que te ayuda a pelear." },
	{ key = "iceArrow", name = "Ice Arrow", classId = Mubia.CLASS_ELF, mana = 10, kind = "attack", power = "skill", base = 105, type = COMBAT_ICEDAMAGE, effect = CONST_ME_ICEATTACK, shootEffect = CONST_ANI_SHIVERARROW, target = true, slow = { ticks = 2000, percent = 90 }, description = "Flecha de hielo que congela al enemigo un par de segundos." },
	{ key = "recovery", name = "Recovery", classId = Mubia.CLASS_ELF, mana = 40, kind = "recovery", description = "Recupera el mana tuyo y de tu party." },
	{ key = "focusShot", name = "Focus Shot", classId = Mubia.CLASS_ELF, mana = 20, kind = "attack", power = "skill", base = 50, type = COMBAT_PHYSICALDAMAGE, effect = CONST_ME_HITAREA, shootEffect = CONST_ANI_ARROW, target = true, hits = { 3, 4 }, description = "Concentra el disparo en un objetivo y golpea 3 o 4 veces seguidas." },
	{ key = "starfall", name = "Starfall", classId = Mubia.CLASS_ELF, mana = 30, kind = "attack", power = "skill", base = 120, type = COMBAT_HOLYDAMAGE, effect = CONST_ME_HOLYAREA, shootEffect = CONST_ANI_HOLY, target = true, description = "Rayo de energia del cielo muy poderoso." },

	-- Magic Gladiator
	{ key = "fireSlash", name = "Fire Slash", classId = Mubia.CLASS_MG, mana = 20, kind = "attack", power = "skill", base = 65, type = COMBAT_FIREDAMAGE, effect = CONST_ME_FIREAREA, target = true, range = 2, description = "Corte en llamas contra un objetivo cercano." },
	{ key = "spiralSlash", name = "Spiral Slash", classId = Mubia.CLASS_MG, mana = 25, kind = "attack", power = "skill", base = 85, type = COMBAT_PHYSICALDAMAGE, effect = CONST_ME_HITAREA, area = "AREA_CIRCLE2X2", description = "Giro en espiral que golpea a todos alrededor." },
	{ key = "flameStrike", name = "Flame Strike", classId = Mubia.CLASS_MG, mana = 35, kind = "attack", power = "skill", base = 140, type = COMBAT_FIREDAMAGE, effect = CONST_ME_FIREAREA, area = "AREA_WAVE4", direction = true, description = "Ola de fuego con el arma hacia donde miras." },
	{ key = "giganticStorm", name = "Gigantic Storm", classId = Mubia.CLASS_MG, mana = 120, kind = "attack", power = "magic", base = 110, type = COMBAT_ENERGYDAMAGE, effect = CONST_ME_BIGCLOUDS, area = "AREA_CIRCLE3X3", description = "Tormenta de energia que golpea a todos alrededor." },
	{ key = "manaRays", name = "Mana Rays", classId = Mubia.CLASS_MG, mana = 130, kind = "attack", power = "magic", base = 85, type = COMBAT_ENERGYDAMAGE, effect = CONST_ME_PURPLEENERGY, shootEffect = CONST_ANI_ENERGY, target = true, description = "Rayo de mana concentrado contra un objetivo." },

	-- Dark Lord (de momento sus scrolls no se venden ni se dropean)
	{ key = "force", name = "Force", classId = Mubia.CLASS_DL, mana = 10, kind = "attack", power = "skill", base = 30, type = COMBAT_ENERGYDAMAGE, effect = CONST_ME_ENERGYHIT, shootEffect = CONST_ANI_ENERGY, target = true, range = 4, description = "Onda de fuerza contra un objetivo." },
	{ key = "fireBurst", name = "Fire Burst", classId = Mubia.CLASS_DL, mana = 25, kind = "attack", power = "skill", base = 80, type = COMBAT_FIREDAMAGE, effect = CONST_ME_FIREAREA, shootEffect = CONST_ANI_FIRE, target = true, area = "AREA_SQUARE1X1", description = "Explosion de fuego sobre el objetivo y los que estan a su lado." },
	{ key = "fireScream", name = "Fire Scream", classId = Mubia.CLASS_DL, mana = 45, kind = "attack", power = "skill", base = 110, type = COMBAT_FIREDAMAGE, effect = CONST_ME_FIREAREA, area = "AREA_WAVE4", direction = true, description = "Grito de fuego hacia donde miras." },
	{ key = "electricSpark", name = "Electric Spark", classId = Mubia.CLASS_DL, mana = 50, kind = "attack", power = "skill", base = 130, type = COMBAT_ENERGYDAMAGE, effect = CONST_ME_ENERGYAREA, area = "AREA_BEAM8", direction = true, description = "Rayo electrico que atraviesa a todos en linea recta." },
	{ key = "earthshake", name = "Earthshake", classId = Mubia.CLASS_DL, mana = 40, kind = "attack", power = "skill", base = 150, type = COMBAT_EARTHDAMAGE, effect = CONST_ME_GROUNDSHAKER, area = "AREA_CIRCLE3X3", requiresPet = "Dark Horse", description = "Tu Dark Horse hace temblar la tierra alrededor tuyo. Necesitas tener el Dark Horse puesto." },
	{ key = "chaoticDiseier", name = "Chaotic Diseier", classId = Mubia.CLASS_DL, mana = 60, kind = "attack", power = "skill", base = 170, type = COMBAT_DEATHDAMAGE, effect = CONST_ME_MORTAREA, shootEffect = CONST_ANI_DEATH, target = true, area = "AREA_CIRCLE2X2", description = "Energia caotica que golpea al objetivo y a los que lo rodean." },
	{ key = "criticalDamage", name = "Critical Damage", classId = Mubia.CLASS_DL, mana = 50, kind = "buff", buff = "criticalDamage", description = "Aumenta el dano tuyo y de tu party segun tu Command y tu Energy." },

	-- Summoner / Bloody Summoner (de momento sus scrolls no se venden ni se dropean)
	{ key = "drainLife", name = "Drain Life", classId = Mubia.CLASS_SUMMONER, mana = 50, kind = "attack", power = "magic", base = 35, type = COMBAT_DEATHDAMAGE, effect = CONST_ME_SMALLCLOUDS, shootEffect = CONST_ANI_DEATH, target = true, drain = 25, description = "Golpea a un enemigo y recuperas parte del dano." },
	{ key = "chainLightning", name = "Chain Lightning", classId = Mubia.CLASS_SUMMONER, mana = 85, kind = "attack", power = "magic", base = 70, type = COMBAT_ENERGYDAMAGE, effect = CONST_ME_ENERGYAREA, shootEffect = CONST_ANI_ENERGY, target = true, area = "AREA_SQUARE1X1", description = "Rayo que golpea al objetivo y a los que estan a su lado." },
	{ key = "lightningShock", name = "Lightning Shock", classId = Mubia.CLASS_SUMMONER, mana = 115, kind = "attack", power = "magic", base = 95, type = COMBAT_ENERGYDAMAGE, effect = CONST_ME_PURPLEENERGY, area = "AREA_CIRCLE3X3", description = "Descarga electrica que golpea a todos a tu alrededor." },
	{ key = "explosion", name = "Explosion", classId = Mubia.CLASS_SUMMONER, mana = 90, kind = "attack", power = "magic", base = 40, type = COMBAT_FIREDAMAGE, effect = CONST_ME_EXPLOSIONAREA, shootEffect = CONST_ANI_FIRE, target = true, area = "AREA_SQUARE1X1", requiresGear = "Book of Samut", description = "Explosion sobre el objetivo. Necesitas el Book of Samut." },
	{ key = "requiem", name = "Requiem", classId = Mubia.CLASS_SUMMONER, mana = 110, kind = "attack", power = "magic", base = 65, type = COMBAT_DEATHDAMAGE, effect = CONST_ME_MORTAREA, area = "AREA_BEAM8", direction = true, requiresGear = "Book of Neil", description = "Espiritus que atraviesan en linea recta. Necesitas el Book of Neil." },
	{ key = "pollution", name = "Pollution", classId = Mubia.CLASS_SUMMONER, mana = 120, kind = "attack", power = "magic", base = 80, type = COMBAT_EARTHDAMAGE, effect = CONST_ME_POISONAREA, shootEffect = CONST_ANI_POISON, target = true, area = "AREA_CIRCLE2X2", poison = { rounds = 4, interval = 2000, percent = 15 }, requiresGear = "Book of Lagle", description = "Nube venenosa sobre el objetivo. Necesitas el Book of Lagle." },
	{ key = "sleep", name = "Sleep", classId = Mubia.CLASS_SUMMONER, mana = 20, kind = "debuff", effect = CONST_ME_SLEEP, shootEffect = CONST_ANI_SMALLSTONE, slow = { ticks = 4000, percent = 90 }, text = "Sleep: el enemigo casi no se mueve por 4 segundos.", description = "Casi inmoviliza a un enemigo por unos segundos." },
	{ key = "weakness", name = "Weakness", classId = Mubia.CLASS_SUMMONER, mana = 50, kind = "debuff", effect = CONST_ME_MAGIC_RED, shootEffect = CONST_ANI_DEATH, debuff = "weakness", value = 15, duration = 10000, text = "Weakness: el enemigo pega 15% menos por 10 segundos.", description = "Un enemigo pega menos por unos segundos." },
	{ key = "innovation", name = "Innovation", classId = Mubia.CLASS_SUMMONER, mana = 70, kind = "debuff", effect = CONST_ME_MAGIC_BLUE, shootEffect = CONST_ANI_ENERGY, debuff = "innovation", value = 25, duration = 10000, text = "Innovation: el enemigo pierde 25% de defensa por 10 segundos.", description = "Un enemigo pierde defensa por unos segundos." },
	{ key = "berserker", name = "Berserker", classId = Mubia.CLASS_SUMMONER, mana = 100, kind = "buff", buff = "berserker", description = "Mas dano magico a cambio de menos defensa." },
	{ key = "damageReflection", name = "Damage Reflection", classId = Mubia.CLASS_SUMMONER, mana = 40, kind = "buff", buff = "damageReflection", description = "Devuelve parte del dano que recibes." },
}

-- Completa cada magia: palabras, nivel, vocaciones y su scroll; indexa por key en Mubia.Spells
Mubia.Spells = {}
do
	local nextScroll = {}
	for classId, firstId in pairs(Mubia.ScrollFirstId) do
		nextScroll[classId] = firstId
	end
	for index, def in ipairs(Mubia.SpellList) do
		def.index = index
		def.words = def.words or def.name:lower():gsub("-", " ")
		def.level = def.level or 1
		def.vocations = Mubia.ClassVocations[def.classId]
		def.scrollId = nextScroll[def.classId]
		def.scrollName = "scroll of " .. def.name:lower()
		nextScroll[def.classId] = def.scrollId + 1
		Mubia.Spells[def.key] = def
	end
	for _, key in ipairs(Mubia.MGSharedSpells) do
		local def = Mubia.Spells[key]
		def.sharedWithMG = true
		def.vocations = { def.vocations[1], def.vocations[2], Mubia.ClassVocations[Mubia.CLASS_MG][1] }
	end
end

-- Magias de una clase, en orden
function Mubia.getClassSpells(classId)
	local list = {}
	for _, def in ipairs(Mubia.SpellList) do
		if def.classId == classId then
			list[#list + 1] = def
		end
	end
	return list
end

-- Scroll de la magia que enseña el item (o nil)
Mubia.SpellByScroll = {}
for _, def in ipairs(Mubia.SpellList) do
	Mubia.SpellByScroll[def.scrollId] = def
end

-- Buffs MU activos por jugador: Mubia.buffs[playerId][nombre] = { value = n, expires = ms }
Mubia.buffs = Mubia.buffs or {}

function Mubia.setBuff(player, name, value, duration)
	local playerId = player:getId()
	Mubia.buffs[playerId] = Mubia.buffs[playerId] or {}
	Mubia.buffs[playerId][name] = { value = value, expires = systemTime() + duration }
end

function Mubia.getBuff(creature, name)
	local playerBuffs = Mubia.buffs[creature:getId()]
	local buff = playerBuffs and playerBuffs[name]
	if not buff then
		return 0
	end
	if buff.expires < systemTime() then
		playerBuffs[name] = nil
		return 0
	end
	return buff.value
end

-- Las magias de Tibia quedan sin uso para los jugadores: se registran como "hay que aprenderla"
-- y nadie las aprende (los monstruos que usan alguna por nombre la siguen pudiendo lanzar).
-- Solo las magias MU (Mubia.SpellList) se aprenden, con su scroll.
do
	local muSpellNames = {}
	for _, def in ipairs(Mubia.SpellList) do
		muSpellNames[def.name:lower()] = true
	end

	local register = Spell.register
	function Spell.register(self)
		local name = self:name()
		if type(name) == "string" and name ~= "" and not muSpellNames[name:lower()] then
			self:needLearn(true)
		end
		return register(self)
	end
end
