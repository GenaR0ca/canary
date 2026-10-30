-- Mubia Online: combate contra monstruos como en MU.
-- Los stats de cada monstruo salen de Mubia.MonsterStats (mubia_monster_stats.lua, el Monster.txt de MU).
--  * Precisión y bloqueo: cada golpe puede fallar (MISS) según attackRate contra defenseRate.
--  * La defensa del monstruo se resta a tu daño (igual que tu defensa se resta al daño que te hace él).
--  * Experiencia con la fórmula de MU: (nivel + 25) * nivel / 3, y mucho menos si el monstruo
--    es más de 10 niveles menor que tú.

Mubia.MonsterConfig = {
	-- si la precisión del atacante es menor que el bloqueo del defensor, solo acierta este % de las veces
	hitChanceWhenOutclassed = 5,
}

-- Stats MU de los monstruos salvajes ya registrados (los llena Mubia.registerWildMonster)
Mubia.WildMonsters = Mubia.WildMonsters or {}

-- Stats MU que usa un monstruo: los de Monster.txt o, si no está ahí (o es custom), los de su archivo
function Mubia.getMonsterMuStats(name, cfg)
	local mu = Mubia.MonsterStats[name]
	if mu and not cfg.custom then
		return {
			level = mu.level,
			hp = mu.hp,
			minDamage = mu.minDamage,
			maxDamage = mu.maxDamage,
			defense = mu.defense,
			attackRate = mu.attackRate,
			defenseRate = mu.defenseRate,
			attackSpeed = mu.attackSpeed,
		}
	end
	-- monstruo propio de Mubia: se estiman precisión y bloqueo con su nivel (como los de MU)
	return {
		level = cfg.level,
		hp = cfg.health,
		minDamage = cfg.damage[1],
		maxDamage = cfg.damage[2],
		defense = cfg.defense,
		attackRate = cfg.attackRate or math.floor(cfg.level * 4.6),
		defenseRate = cfg.defenseRate or cfg.level,
		attackSpeed = cfg.attackSpeed or 2000,
	}
end

-- Experiencia base de MU por matar un monstruo de ese nivel
function Mubia.getMonsterBaseExp(level)
	local exp = (level + 25) * level / 3
	if level >= 65 then
		exp = exp + (level - 64) * math.floor(level / 4)
	end
	return math.max(1, math.floor(exp))
end

-- Multiplicador de experiencia para un jugador: en MU, si el monstruo tiene más de 10 niveles
-- menos que tú, la experiencia baja (nivel del monstruo + 10) / tu nivel. Además, un extra al azar de 0 a 50%.
function Mubia.getMonsterExpFactor(player, target)
	local monster = target and target:getMonster()
	local mu = monster and Mubia.WildMonsters[monster:getName()]
	if not mu then
		return 1
	end
	local factor = 1
	local level = player:getLevel()
	if mu.level + 10 < level then
		factor = (mu.level + 10) / level
	end
	return factor * (1 + math.random(0, 50) / 100)
end

-- Precisión del jugador (Attack Success Rate de MU): nivel * 5 + AGI * 1.5 + STR / 4
function Mubia.getAttackRate(player)
	local stats = Mubia.getStats(player)
	return math.floor(player:getLevel() * 5 + stats.agi * 3 / 2 + stats.str / 4)
end

-- Bloqueo del jugador (Defense Success Rate de MU): AGI / 3 (Dark Knight y Dark Wizard) o AGI / 4 (Fairy Elf)
function Mubia.getDefenseRate(player)
	local stats = Mubia.getStats(player)
	local divisor = Mubia.getClass(player) == Mubia.Classes[Mubia.CLASS_ELF] and 4 or 3
	return math.floor(stats.agi / divisor)
end

-- ¿El golpe acierta? Igual que en MU: si la precisión es menor que el bloqueo casi siempre falla;
-- si no, falla cuando un número al azar entre 0 y la precisión cae por debajo del bloqueo.
function Mubia.rollHit(attackRate, defenseRate)
	if attackRate <= 0 then
		return false
	end
	if attackRate < defenseRate then
		return math.random(1, 100) <= Mubia.MonsterConfig.hitChanceWhenOutclassed
	end
	return math.random(0, attackRate - 1) >= defenseRate
end

local function isHealthDamage(combatType)
	return combatType ~= COMBAT_HEALING and combatType ~= COMBAT_LIFEDRAIN and combatType ~= COMBAT_MANADRAIN and combatType ~= COMBAT_NONE
end

local function wildStats(creature)
	local monster = creature and creature:getMonster()
	if not monster or monster:getMaster() then
		return nil
	end
	return Mubia.WildMonsters[monster:getName()]
end

local function miss(target)
	target:getPosition():sendMagicEffect(CONST_ME_POFF)
	return 0, 0
end

-- Se suma al cálculo de daño de mubia.lua (Mubia.modifyDamage): primero si el golpe acierta,
-- después el daño MU normal y al final la defensa del monstruo.
if Mubia.modifyDamage ~= Mubia.monsterModifyDamage then
	Mubia.baseModifyDamage = Mubia.modifyDamage
end

function Mubia.monsterModifyDamage(target, attacker, typePrimary, damagePrimary, typeSecondary, damageSecondary)
	if not attacker or not target or not isHealthDamage(typePrimary) or damagePrimary + damageSecondary <= 0 then
		return Mubia.baseModifyDamage(target, attacker, typePrimary, damagePrimary, typeSecondary, damageSecondary)
	end

	local attackerPlayer = attacker:getPlayer()
	local targetPlayer = target:getPlayer()

	-- jugador contra monstruo de MU
	local targetMu = wildStats(target)
	if attackerPlayer and targetMu and Mubia.getClass(attackerPlayer) then
		if not Mubia.rollHit(Mubia.getAttackRate(attackerPlayer), targetMu.defenseRate) then
			return miss(target)
		end
		damagePrimary, damageSecondary = Mubia.baseModifyDamage(target, attacker, typePrimary, damagePrimary, typeSecondary, damageSecondary)
		local total = damagePrimary + damageSecondary
		if total > 0 then
			local minimum = math.ceil(total * Mubia.Config.minDamageAfterDefense)
			local reduced = math.max(minimum, total - Mubia.reduceDefense(target, targetMu.defense))
			local ratio = reduced / total
			damagePrimary = math.floor(damagePrimary * ratio)
			damageSecondary = reduced - damagePrimary
		end
		return damagePrimary, damageSecondary
	end

	-- monstruo de MU contra jugador (su defensa la resta mubia.lua)
	local attackerMu = wildStats(attacker)
	if targetPlayer and attackerMu and Mubia.getClass(targetPlayer) then
		if not Mubia.rollHit(attackerMu.attackRate, Mubia.getDefenseRate(targetPlayer)) then
			return miss(target)
		end
	end

	return Mubia.baseModifyDamage(target, attacker, typePrimary, damagePrimary, typeSecondary, damageSecondary)
end

Mubia.modifyDamage = Mubia.monsterModifyDamage
