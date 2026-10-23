-- Mubia Online: barras de SD (Shield Gage) y AG (Ability Gage) como en MU Season 6.
-- SD: escudo para PvP. Cuando otro jugador te pega, el SD se lleva el 90% del golpe y la vida el 10%.
--     Si el SD llega a 0, la vida recibe todo. Se recupera solo dentro de zonas seguras (ciudades).
-- AG: energía que gastan las habilidades. Se recupera sola en cualquier lugar cada 3 segundos.
-- El cliente muestra las barras con el opcode 83.

Mubia.SDAG_OPCODE = 83

Mubia.SDAGConfig = {
	sdRatio = 90, -- % del golpe PvP que va al SD
	sdRegenPercent = 5, -- % del SD máximo que se recupera cada 3 segundos en zona segura
	agRegenPercent = 5, -- % del AG máximo que se recupera cada 3 segundos
	-- AG máximo por clase: STR, AGI, VIT y ENE multiplicados por estos números
	agFormula = {
		[Mubia.CLASS_DK] = { str = 0.15, agi = 0.2, vit = 0.3, ene = 1.0 },
		[Mubia.CLASS_DW] = { str = 0.2, agi = 0.4, vit = 0.3, ene = 0.2 },
		[Mubia.CLASS_ELF] = { str = 0.3, agi = 0.2, vit = 0.1, ene = 0.15 },
	},
}

-- AG que gasta cada habilidad (las que no están no gastan AG)
Mubia.SpellAG = {
	twistingSlash = 10,
	impale = 8,
	deathStab = 12,
	ragefulBlow = 20,
	strikeOfDestruction = 24,
	iceStorm = 5,
	decay = 7,
	multiShot = 7,
	penetration = 9,
	iceArrow = 12,
	focusShot = 10,
	starfall = 15,
}

-- SD y AG actuales de cada jugador conectado (se guardan al salir)
Mubia.sdag = Mubia.sdag or {}

local function store(player)
	return player:kv():scoped("mubia-sdag")
end

local function excellent(player)
	local bonus = Mubia.getEquipmentBonus(player)
	return bonus.exc or {}
end

function Mubia.getMaxSD(player)
	local stats = Mubia.getStats(player)
	local level = player:getLevel()
	local sd = (stats.str + stats.agi + stats.vit + stats.ene) * 1.2 + level * level / 30 + Mubia.getDefense(player)
	local percent = excellent(player).maxSd or 0
	return math.floor(sd * (100 + percent) / 100)
end

function Mubia.getMaxAG(player)
	local class = Mubia.getClass(player)
	local formula
	for classId, f in pairs(Mubia.SDAGConfig.agFormula) do
		if Mubia.Classes[classId] == class then
			formula = f
		end
	end
	if not formula then
		return 0
	end
	local stats = Mubia.getStats(player)
	local ag = stats.str * formula.str + stats.agi * formula.agi + stats.vit * formula.vit + stats.ene * formula.ene
	return math.floor(ag) + (excellent(player).wingAg or 0)
end

local function state(player)
	local id = player:getId()
	local current = Mubia.sdag[id]
	if not current then
		local kv = store(player)
		current = { sd = kv:get("sd") or Mubia.getMaxSD(player), ag = kv:get("ag") or Mubia.getMaxAG(player) }
		Mubia.sdag[id] = current
	end
	current.maxSd = Mubia.getMaxSD(player)
	current.maxAg = Mubia.getMaxAG(player)
	current.sd = math.max(0, math.min(current.sd, current.maxSd))
	current.ag = math.max(0, math.min(current.ag, current.maxAg))
	return current
end

function Mubia.sendSDAG(player)
	if not player:isUsingOtClient() or not Mubia.getClass(player) then
		return
	end
	local s = state(player)
	player:sendExtendedOpcode(Mubia.SDAG_OPCODE, string.format('{"sd":%d,"maxSd":%d,"ag":%d,"maxAg":%d}', s.sd, s.maxSd, s.ag, s.maxAg))
end

function Mubia.saveSDAG(player)
	local s = Mubia.sdag[player:getId()]
	if s then
		local kv = store(player)
		kv:set("sd", s.sd)
		kv:set("ag", s.ag)
	end
	Mubia.sdag[player:getId()] = nil
end

-- Golpe de otro jugador: el SD se lleva el 90%. Devuelve lo que le llega a la vida.
function Mubia.absorbWithSD(player, damage)
	if damage <= 0 or not Mubia.getClass(player) then
		return damage
	end
	local s = state(player)
	if s.sd <= 0 then
		return damage
	end
	local toShield = math.min(s.sd, math.floor(damage * Mubia.SDAGConfig.sdRatio / 100))
	s.sd = s.sd - toShield
	Mubia.sendSDAG(player)
	return damage - toShield
end

-- ¿Tiene AG para esta habilidad? Si tiene, lo gasta.
function Mubia.useAG(player, spellKey)
	local cost = Mubia.SpellAG[spellKey] or 0
	if cost <= 0 then
		return true
	end
	local s = state(player)
	if s.ag < cost then
		Mubia.sendMessage(player, MESSAGE_FAILURE, string.format("No tienes AG suficiente (necesitas %d).", cost))
		player:getPosition():sendMagicEffect(CONST_ME_POFF)
		return false
	end
	s.ag = s.ag - cost
	Mubia.sendSDAG(player)
	return true
end

-- Cada 3 segundos: AG en todos lados y SD en zona segura
function Mubia.regenSDAG(player)
	if not Mubia.getClass(player) then
		return
	end
	local s = state(player)
	local changed = false
	if s.ag < s.maxAg then
		s.ag = math.min(s.maxAg, s.ag + math.max(1, math.floor(s.maxAg * Mubia.SDAGConfig.agRegenPercent / 100)))
		changed = true
	end
	if s.sd < s.maxSd and player:getTile() and player:getTile():hasFlag(TILESTATE_PROTECTIONZONE) then
		s.sd = math.min(s.maxSd, s.sd + math.max(1, math.floor(s.maxSd * Mubia.SDAGConfig.sdRegenPercent / 100)))
		changed = true
	end
	if changed then
		Mubia.sendSDAG(player)
	end
end

function Mubia.getAG(player)
	return state(player).ag
end

-- La ventana de stats y las barras se actualizan juntas (equipo, stats, nivel)
local sendStats = Mubia.sendStats
function Mubia.sendStats(player)
	sendStats(player)
	Mubia.sendSDAG(player)
end

function Mubia.addSD(player, amount)
	if not Mubia.getClass(player) then
		return
	end
	local s = state(player)
	s.sd = math.min(s.maxSd, s.sd + amount)
	Mubia.sendSDAG(player)
end
