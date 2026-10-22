-- Mubia Online: magias estilo MU. Se aprenden con su scroll (ver scrolls.lua).
-- Las magias se definen en Mubia.SpellList (data/libs/systems/mubia.lua); aquí se arma cada una.
-- El daño sale de los stats MU y la espera entre magias depende de la AGI.

-- Áreas propias de Mubia (las de Tibia están en data/scripts/lib/register_spells.lua)
MUBIA_AREA_LINE3 = {
	{ 1 },
	{ 1 },
	{ 1 },
	{ 3 },
}

MUBIA_AREA_RING = {
	{ 0, 0, 1, 1, 1, 0, 0 },
	{ 0, 1, 0, 0, 0, 1, 0 },
	{ 1, 0, 0, 0, 0, 0, 1 },
	{ 1, 0, 0, 3, 0, 0, 1 },
	{ 1, 0, 0, 0, 0, 0, 1 },
	{ 0, 1, 0, 0, 0, 1, 0 },
	{ 0, 0, 1, 1, 1, 0, 0 },
}

local PARTY_RANGE = 8 -- casillas a las que llega un buff de party

Mubia.nextCast = Mubia.nextCast or {}

local function getStatsAndClass(player)
	local class = Mubia.getClass(player)
	if not class then
		return nil
	end
	return class, Mubia.getStats(player)
end

-- Comprueba la espera entre magias (AGI). Devuelve false si todavía no puede lanzar.
local function checkCastSpeed(player, class, stats)
	local playerId = player:getId()
	local now = systemTime()
	local nextCast = Mubia.nextCast[playerId] or 0
	if now < nextCast then
		player:sendCancelMessage(RETURNVALUE_YOUAREEXHAUSTED)
		player:getPosition():sendMagicEffect(CONST_ME_POFF)
		return false
	end
	Mubia.nextCast[playerId] = now + Mubia.getCastSpeed(class, stats)
	return true
end

-- Daño mínimo y máximo de una magia de ataque (positivos).
local function getSpellDamage(player, def)
	local class, stats = getStatsAndClass(player)
	if not class then
		return 0, 0
	end

	local minDamage, maxDamage
	if def.power == "magic" then
		if not class.magic then
			return 0, 0
		end
		minDamage, maxDamage = class.magic(stats)
		minDamage, maxDamage = minDamage + def.base, maxDamage + def.base
	else
		minDamage, maxDamage = class.damage(stats)
		local weaponAttack = Mubia.getWeaponAttack(player)
		local multiplier = class.skillMultiplier and class.skillMultiplier(stats) or 1
		minDamage = (minDamage + weaponAttack * 0.8 + def.base) * multiplier
		maxDamage = (maxDamage + weaponAttack + def.base) * multiplier
	end

	local bonus = Mubia.getBuff(player, "damage")
	return math.floor(minDamage + bonus), math.floor(maxDamage + bonus)
end

-- Un golpe extra de una magia (veneno, quemadura, golpes seguidos). El daño ya viene calculado.
function Mubia.spellHit(playerId, targetId, combatType, minDamage, maxDamage, effect)
	local player = Player(playerId)
	local target = Creature(targetId)
	if not player or not target or target:getHealth() <= 0 then
		return
	end
	Mubia.castingSpell[playerId] = true
	doTargetCombatHealth(player, target, combatType, -minDamage, -maxDamage, effect)
	Mubia.castingSpell[playerId] = nil
end

-- Daño por turnos (veneno o fuego): un % del golpe de la magia cada cierto tiempo.
local function addDamageOverTime(player, target, def, dot, combatType, effect)
	local minDamage, maxDamage = getSpellDamage(player, def)
	local tick = math.max(1, math.floor((minDamage + maxDamage) / 2 * dot.percent / 100))
	for round = 1, dot.rounds do
		addEvent(Mubia.spellHit, round * dot.interval, player:getId(), target:getId(), combatType, tick, tick, effect)
	end
end

-- Empuja al objetivo una casilla en dirección contraria al lanzador, si la casilla está libre.
local function pushAway(player, target)
	if target:isPlayer() and Tile(target:getPosition()):hasFlag(TILESTATE_PROTECTIONZONE) then
		return
	end
	local from = target:getPosition()
	local direction = Position.getDirectionTo(player:getPosition(), from)
	local destination = Position(from)
	destination:getNextPosition(direction)
	local tile = Tile(destination)
	if tile and tile:queryAdd(target) == RETURNVALUE_NOERROR then
		target:teleportTo(destination, true)
	end
end

local function sendShoot(player, toPosition, shootEffect)
	if shootEffect then
		player:getPosition():sendDistanceEffect(toPosition, shootEffect)
	end
end

-- Efecto visual de flechas/lanza saliendo hacia donde mira el personaje.
local function sendDirectionShoot(player, def)
	local origin = player:getPosition()
	local direction = player:getDirection()
	if def.fan then
		for spread = -2, 2 do
			local target = Position(origin)
			if direction == DIRECTION_NORTH then
				target.x, target.y = origin.x + spread, origin.y - 4
			elseif direction == DIRECTION_SOUTH then
				target.x, target.y = origin.x + spread, origin.y + 4
			elseif direction == DIRECTION_EAST then
				target.x, target.y = origin.x + 4, origin.y + spread
			else
				target.x, target.y = origin.x - 4, origin.y + spread
			end
			origin:sendDistanceEffect(target, CONST_ANI_ARROW)
		end
	elseif def.shootEffect then
		local target = Position(origin)
		target:getNextPosition(direction, #_G[def.area] - 1)
		origin:sendDistanceEffect(target, def.shootEffect)
	end
end

-- Jugador más cerca de los miembros de su party (incluido él) que estén a mano.
local function getPartyMembersInRange(player)
	local members = { player }
	local party = player:getParty()
	if not party then
		return members
	end
	local origin = player:getPosition()
	local all = party:getMembers()
	table.insert(all, party:getLeader())
	for _, member in ipairs(all) do
		if member ~= player then
			local position = member:getPosition()
			if position.z == origin.z and origin:getDistance(position) <= PARTY_RANGE then
				members[#members + 1] = member
			end
		end
	end
	return members
end

local function startSpell(player)
	local class, stats = getStatsAndClass(player)
	if not class or not checkCastSpeed(player, class, stats) then
		return nil
	end
	return class, stats
end

local function newSpell(def, group, aggressive)
	local spell = Spell("instant")
	spell:group(group)
	spell:name(def.name)
	spell:words(def.words)
	spell:level(def.level)
	spell:mana(def.mana)
	spell:needLearn(true)
	spell:isAggressive(aggressive)
	spell:cooldown(0)
	spell:groupCooldown(0)
	spell:vocation(unpack(def.vocations))
	return spell
end

-- Magias de ataque
local function registerAttack(def)
	local combat = Combat()
	combat:setParameter(COMBAT_PARAM_TYPE, def.type)
	combat:setParameter(COMBAT_PARAM_EFFECT, def.effect)
	if def.area then
		combat:setArea(createCombatArea(_G[def.area]))
	end
	if def.target and not def.area and def.shootEffect then
		combat:setParameter(COMBAT_PARAM_DISTANCEEFFECT, def.shootEffect)
	end

	local valuesName = "mubiaSpellValues_" .. def.key
	_G[valuesName] = function(player, level, magicLevel)
		local minDamage, maxDamage = getSpellDamage(player, def)
		return -minDamage, -maxDamage
	end
	combat:setCallback(CALLBACK_PARAM_LEVELMAGICVALUE, valuesName)

	local slowCondition
	if def.slow then
		slowCondition = Condition(CONDITION_PARALYZE)
		slowCondition:setParameter(CONDITION_PARAM_TICKS, def.slow.ticks)
		local factor = -def.slow.percent / 100
		slowCondition:setFormula(factor, 0, factor, 0)
	end
	local drunkCondition
	if def.drunk then
		drunkCondition = Condition(CONDITION_DRUNK)
		drunkCondition:setParameter(CONDITION_PARAM_TICKS, def.drunk)
	end

	-- efectos extra sobre cada criatura golpeada
	if def.slow or def.drunk or def.poison or def.burn or def.push or def.hits then
		local hitName = "mubiaSpellOnHit_" .. def.key
		_G[hitName] = function(creature, target)
			local player = creature and creature:getPlayer()
			if not player or not target or target == creature then
				return true
			end
			if slowCondition then
				target:addCondition(slowCondition)
			end
			if drunkCondition then
				target:addCondition(drunkCondition)
			end
			if def.poison then
				addDamageOverTime(player, target, def, def.poison, COMBAT_EARTHDAMAGE, CONST_ME_HITBYPOISON)
			end
			if def.burn then
				addDamageOverTime(player, target, def, def.burn, COMBAT_FIREDAMAGE, CONST_ME_HITBYFIRE)
			end
			if def.push then
				pushAway(player, target)
			end
			if def.hits then
				local minDamage, maxDamage = getSpellDamage(player, def)
				local extraHits = math.random(def.hits[1], def.hits[2]) - 1
				for hit = 1, extraHits do
					addEvent(function(playerId, targetId)
						local caster, victim = Player(playerId), Creature(targetId)
						if caster and victim then
							sendShoot(caster, victim:getPosition(), def.shootEffect)
						end
						Mubia.spellHit(playerId, targetId, def.type, minDamage, maxDamage, def.effect)
					end, hit * 250, player:getId(), target:getId())
				end
			end
			return true
		end
		combat:setCallback(CALLBACK_PARAM_TARGETCREATURE, hitName)
	end

	local spell = newSpell(def, "attack", true)

	function spell.onCastSpell(creature, variant)
		local player = creature:getPlayer()
		if not player or not startSpell(player) then
			return false
		end

		local castVariant = variant
		if def.target and def.area then
			-- área alrededor del objetivo
			local target = Creature(variant:getNumber())
			if not target then
				return false
			end
			sendShoot(player, target:getPosition(), def.shootEffect)
			castVariant = Variant(target:getPosition())
		elseif def.direction or def.fan then
			sendDirectionShoot(player, def)
		end

		local playerId = player:getId()
		Mubia.castingSpell[playerId] = true
		local ok = combat:execute(player, castVariant)
		Mubia.castingSpell[playerId] = nil
		return ok
	end

	if def.target then
		spell:needTarget(true)
		spell:range(def.range or 5)
		spell:blockWalls(true)
	end
	if def.direction then
		spell:needDirection(true)
	end
	spell:register()
end

-- Buffs: Swell Life (vida máxima), Greater Defense, Greater Damage y Soul Barrier
local BUFF_SUBID = 47100

local function registerBuff(def)
	local spell = newSpell(def, "support", false)

	function spell.onCastSpell(creature, variant)
		local player = creature:getPlayer()
		if not player then
			return false
		end
		local class, stats = startSpell(player)
		if not class then
			return false
		end

		if def.buff == "swellLife" then
			local percent = math.min(100, 12 + math.floor(stats.ene / 20) + math.floor(stats.vit / 100))
			local duration = (60 + math.floor(stats.ene / 10)) * 1000
			local condition = Condition(CONDITION_ATTRIBUTES)
			condition:setParameter(CONDITION_PARAM_SUBID, BUFF_SUBID)
			condition:setParameter(CONDITION_PARAM_TICKS, duration)
			condition:setParameter(CONDITION_PARAM_STAT_MAXHITPOINTSPERCENT, 100 + percent)
			for _, member in ipairs(getPartyMembersInRange(player)) do
				member:addCondition(condition)
				member:getPosition():sendMagicEffect(CONST_ME_MAGIC_RED)
				Mubia.sendMessage(member, MESSAGE_STATUS, string.format("Swell Life: +%d%% de vida máxima por %d segundos.", percent, duration / 1000))
			end
		elseif def.buff == "soulBarrier" then
			local percent = math.min(50, 10 + math.floor(stats.agi / 50) + math.floor(stats.ene / 200))
			local duration = (60 + math.floor(stats.ene / 40)) * 1000
			for _, member in ipairs(getPartyMembersInRange(player)) do
				Mubia.setBuff(member, "barrier", percent, duration)
				member:getPosition():sendMagicEffect(CONST_ME_ENERGYAREA)
				Mubia.sendMessage(member, MESSAGE_STATUS, string.format("Soul Barrier: recibes %d%% menos de daño por %d segundos.", percent, duration / 1000))
			end
		else
			local value, text
			if def.buff == "defense" then
				value = 2 + math.floor(stats.ene / 8)
				text = "Greater Defense: +%d de defensa por 60 segundos."
			else
				value = 3 + math.floor(stats.ene / 7)
				text = "Greater Damage: +%d de daño por 60 segundos."
			end
			for _, member in ipairs(getPartyMembersInRange(player)) do
				Mubia.setBuff(member, def.buff, value, 60000)
				member:getPosition():sendMagicEffect(def.buff == "defense" and CONST_ME_MAGIC_BLUE or CONST_ME_MAGIC_RED)
				Mubia.sendMessage(member, MESSAGE_STATUS, string.format(text, value))
			end
		end
		return true
	end

	spell:register()
end

-- Heal: cura al más herido entre la elfa y su party
local function registerHeal(def)
	local spell = newSpell(def, "healing", false)

	function spell.onCastSpell(creature, variant)
		local player = creature:getPlayer()
		if not player then
			return false
		end
		local class, stats = startSpell(player)
		if not class then
			return false
		end

		local target, lowest = player, 2
		for _, member in ipairs(getPartyMembersInRange(player)) do
			local ratio = member:getHealth() / math.max(1, member:getMaxHealth())
			if ratio < lowest then
				target, lowest = member, ratio
			end
		end
		local amount = 5 + math.floor(stats.ene / 5)
		target:addHealth(amount)
		target:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
		if target ~= player then
			player:getPosition():sendDistanceEffect(target:getPosition(), CONST_ANI_SMALLHOLY)
		end
		return true
	end

	spell:register()
end

-- Recovery: en MU recupera el SD; aquí recupera mana de la elfa y su party
local function registerRecovery(def)
	local spell = newSpell(def, "healing", false)

	function spell.onCastSpell(creature, variant)
		local player = creature:getPlayer()
		if not player then
			return false
		end
		local class, stats = startSpell(player)
		if not class then
			return false
		end

		local amount = 10 + math.floor(stats.ene / 4)
		for _, member in ipairs(getPartyMembersInRange(player)) do
			member:addMana(amount)
			member:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
		end
		return true
	end

	spell:register()
end

-- Invocaciones de la elfa: solo una a la vez, la nueva reemplaza a la anterior
local function registerSummon(def)
	local spell = newSpell(def, "support", false)

	function spell.onCastSpell(creature, variant)
		local player = creature:getPlayer()
		if not player then
			return false
		end
		local position = player:getPosition()
		if Tile(position):hasFlag(TILESTATE_PROTECTIONZONE) then
			player:sendCancelMessage(RETURNVALUE_ACTIONNOTPERMITTEDINPROTECTIONZONE)
			position:sendMagicEffect(CONST_ME_POFF)
			return false
		end
		if not startSpell(player) then
			return false
		end

		for _, summon in ipairs(player:getSummons()) do
			summon:getPosition():sendMagicEffect(CONST_ME_POFF)
			summon:remove()
		end

		local summon = Game.createMonster(def.monster, position, true, false, player)
		if not summon then
			player:sendCancelMessage(RETURNVALUE_NOTENOUGHROOM)
			position:sendMagicEffect(CONST_ME_POFF)
			return false
		end
		summon:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
		return true
	end

	spell:register()
end

-- Teleport: salta hasta la casilla libre más lejana hacia donde mira (sin atravesar paredes)
local function registerTeleport(def)
	local spell = newSpell(def, "support", false)

	function spell.onCastSpell(creature, variant)
		local player = creature:getPlayer()
		if not player then
			return false
		end

		local origin = player:getPosition()
		local direction = player:getDirection()
		local destination
		local position = Position(origin)
		for step = 1, def.distance do
			position:getNextPosition(direction)
			local tile = Tile(position)
			if not tile or not origin:isSightClear(position) then
				break
			end
			if tile:getGround() and tile:queryAdd(player) == RETURNVALUE_NOERROR and not tile:hasFlag(TILESTATE_TELEPORT) and not tile:hasFlag(TILESTATE_FLOORCHANGE) then
				destination = Position(position)
			end
		end

		if not destination then
			player:sendCancelMessage(RETURNVALUE_NOTPOSSIBLE)
			origin:sendMagicEffect(CONST_ME_POFF)
			return false
		end
		if not startSpell(player) then
			return false
		end

		origin:sendMagicEffect(CONST_ME_PURPLETELEPORT)
		player:teleportTo(destination)
		destination:sendMagicEffect(CONST_ME_PURPLETELEPORT)
		return true
	end

	spell:needDirection(true)
	spell:register()
end

local registerByKind = {
	attack = registerAttack,
	buff = registerBuff,
	heal = registerHeal,
	recovery = registerRecovery,
	summon = registerSummon,
	teleport = registerTeleport,
}

for _, def in ipairs(Mubia.SpellList) do
	registerByKind[def.kind](def)
end
