-- Mubia Online: magias estilo MU. Se aprenden con su scroll (ver scrolls.lua).
-- El daño sale de los stats MU y la espera entre magias depende de la AGI.

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
	local now = os.mtime()
	local nextCast = Mubia.nextCast[playerId] or 0
	if now < nextCast then
		player:sendCancelMessage(RETURNVALUE_YOUAREEXHAUSTED)
		player:getPosition():sendMagicEffect(CONST_ME_POFF)
		return false
	end
	Mubia.nextCast[playerId] = now + Mubia.getCastSpeed(class, stats)
	return true
end

-- Ejecuta el combate marcando que el daño ya viene calculado (no lo pisa Mubia.modifyDamage).
local function executeMuSpell(combat, player, variant)
	local playerId = player:getId()
	Mubia.castingSpell[playerId] = true
	local ok = combat:execute(player, variant)
	Mubia.castingSpell[playerId] = nil
	return ok
end

Mubia.nextCast = Mubia.nextCast or {}

local function registerMuSpell(def, combat)
	local spell = Spell("instant")

	function spell.onCastSpell(creature, variant)
		local player = creature:getPlayer()
		if not player then
			return false
		end
		local class, stats = getStatsAndClass(player)
		if not class or not checkCastSpeed(player, class, stats) then
			return false
		end
		if def.onCast then
			def.onCast(player)
		end
		return executeMuSpell(combat, player, variant)
	end

	spell:group("attack")
	spell:name(def.name)
	spell:words(def.words)
	spell:level(def.level)
	spell:mana(def.mana)
	spell:needLearn(true)
	spell:isAggressive(true)
	spell:cooldown(0)
	spell:groupCooldown(0)
	spell:vocation(table.unpack(def.vocations))
	spell:register()
end

-- Twisting Slash (Dark Knight): giro con el arma que golpea a todo alrededor.
-- Daño físico + arma, multiplicado por 200% + ENE/10 % como en MU.
do
	local combat = Combat()
	combat:setParameter(COMBAT_PARAM_TYPE, COMBAT_PHYSICALDAMAGE)
	combat:setParameter(COMBAT_PARAM_EFFECT, CONST_ME_HITAREA)
	combat:setArea(createCombatArea(AREA_CIRCLE2X2))

	function mubiaTwistingSlashValues(player, level, magicLevel)
		local class, stats = getStatsAndClass(player)
		if not class then
			return 0, 0
		end
		local minDamage, maxDamage = class.damage(stats)
		local weaponAttack = Mubia.getWeaponAttack(player)
		local multiplier = class.skillMultiplier and class.skillMultiplier(stats) or 1
		minDamage = (minDamage + weaponAttack * 0.8) * multiplier
		maxDamage = (maxDamage + weaponAttack) * multiplier
		return -math.floor(minDamage), -math.floor(maxDamage)
	end

	combat:setCallback(CALLBACK_PARAM_LEVELMAGICVALUE, "mubiaTwistingSlashValues")
	registerMuSpell(Mubia.Spells.twistingSlash, combat)
end

-- Evil Spirit (Dark Wizard): espíritus que dañan todo alrededor.
-- Daño mágico (ENE) + daño base de la magia.
do
	local def = Mubia.Spells.evilSpirit
	local combat = Combat()
	combat:setParameter(COMBAT_PARAM_TYPE, COMBAT_DEATHDAMAGE)
	combat:setParameter(COMBAT_PARAM_EFFECT, CONST_ME_MORTAREA)
	combat:setArea(createCombatArea(AREA_CIRCLE3X3))

	function mubiaEvilSpiritValues(player, level, magicLevel)
		local class, stats = getStatsAndClass(player)
		if not class or not class.magic then
			return 0, 0
		end
		local minDamage, maxDamage = class.magic(stats)
		return -(minDamage + def.baseDamage), -(maxDamage + def.baseDamage)
	end

	combat:setCallback(CALLBACK_PARAM_LEVELMAGICVALUE, "mubiaEvilSpiritValues")
	registerMuSpell(def, combat)
end

-- Multi-Shot (Fairy Elf): abanico de flechas hacia donde mira.
-- Daño físico + arma + daño base de la magia.
do
	local def = Mubia.Spells.multiShot
	local combat = Combat()
	combat:setParameter(COMBAT_PARAM_TYPE, COMBAT_PHYSICALDAMAGE)
	combat:setParameter(COMBAT_PARAM_EFFECT, CONST_ME_HITAREA)
	combat:setArea(createCombatArea(AREA_WAVE4))

	function mubiaMultiShotValues(player, level, magicLevel)
		local class, stats = getStatsAndClass(player)
		if not class then
			return 0, 0
		end
		local minDamage, maxDamage = class.damage(stats)
		local weaponAttack = Mubia.getWeaponAttack(player)
		minDamage = minDamage + weaponAttack * 0.8 + def.baseDamage
		maxDamage = maxDamage + weaponAttack + def.baseDamage
		return -math.floor(minDamage), -math.floor(maxDamage)
	end

	combat:setCallback(CALLBACK_PARAM_LEVELMAGICVALUE, "mubiaMultiShotValues")

	-- 5 flechas en abanico, solo visual
	def.onCast = function(player)
		local origin = player:getPosition()
		local direction = player:getDirection()
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
	end

	registerMuSpell(def, combat)
end
