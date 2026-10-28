-- Mubia Online: Blood Castle. Reglas y configuración en data/libs/systems/mubia_blood_castle.lua.

local BC = Mubia.BloodCastle

-- reloj del evento: cada segundo revisa los castillos (espera, puente, pasos, arma y final)
local think = GlobalEvent("MubiaBloodCastleThink")

function think.onThink(interval)
	BC.think()
	return true
end

think:interval(1000)
think:register()

-- monstruos, puerta y estatua del evento
local death = CreatureEvent("MubiaBloodCastleDeath")

function death.onDeath(creature, corpse, killer, mostDamageKiller, lastHitUnjustified, mostDamageUnjustified)
	BC.onMonsterDeath(creature, killer, mostDamageKiller)
	return true
end

death:register()

-- si entra al juego dentro de un castillo sin evento, vuelve afuera
local login = CreatureEvent("MubiaBloodCastleLogin")

function login.onLogin(player)
	BC.onLogin(player)
	return true
end

login:register()

-- experiencia ganada adentro (el final da un % extra)
local experience = EventCallback("MubiaBloodCastleExperience")

function experience.playerOnGainExperience(player, target, exp, rawExp)
	BC.onGainExperience(player, target, exp)
end

experience:register()

-- Scroll of Archangel y Blood Bone en el botín de los monstruos de afuera
local drop = EventCallback("MubiaBloodCastleDrop")

function drop.monsterPostDropLoot(monster, corpse)
	BC.rollDrop(monster, corpse)
end

drop:register()

-- el arma del Archangel no sale del castillo
local move = EventCallback("MubiaBloodCastleMove")

function move.playerOnMoveItem(player, item, count, fromPosition, toPosition, fromCylinder, toCylinder)
	if not BC.canMoveWeapon(player, item, toPosition) then
		Mubia.sendMessage(player, MESSAGE_FAILURE, "El arma del Archangel no puede salir del castillo.")
		return false
	end
	return true
end

move:register()

-- GOD: /bc (lista), /bc 3 (entrar al 3), /bc items (todos los Scroll, Bone y Cloak),
-- /bc start 3 (baja el puente ya), /bc next 3 (salta al paso siguiente), /bc stop 3 (termina sin premio)
local command = TalkAction("/bc")

function command.onSay(player, words, param)
	local args = param:split(" ")
	local action = (args[1] or ""):lower()
	local level = tonumber(args[2] or args[1])
	local castle = level and BC.castles[level]

	if action == "items" then
		for i = 0, #BC.castles - 1 do
			player:addItem(BC.SCROLL + i, 1)
			player:addItem(BC.BONE + i, 1)
			player:addItem(BC.CLOAK + i, 1)
		end
		Mubia.sendMessage(player, MESSAGE_EVENT_ADVANCE, "Recibiste Scroll of Archangel, Blood Bone y Cloak of Invisibility de +1 a +8.")
	elseif action == "start" and castle then
		if castle.state.status == "waiting" then
			castle.state.startAt = os.time()
			castle.state.endAt = castle.state.startAt + BC.duration
		end
		Mubia.sendMessage(player, MESSAGE_EVENT_ADVANCE, string.format("Blood Castle %d: %s.", level, castle.state.status == "idle" and "no hay nadie adentro" or "baja el puente"))
	elseif action == "next" and castle then
		if not BC.skipStep(castle) then
			Mubia.sendMessage(player, MESSAGE_FAILURE, string.format("Blood Castle %d: no hay un paso para saltar (¿empezó el evento?).", level))
		end
	elseif action == "stop" and castle then
		if castle.state.status == "running" or castle.state.status == "waiting" then
			BC.finish(castle, nil)
		end
		Mubia.sendMessage(player, MESSAGE_EVENT_ADVANCE, string.format("Blood Castle %d terminado.", level))
	elseif castle then
		BC.enter(player, castle)
	else
		local lines = { "Blood Castle (/bc N entra, /bc items, /bc start N, /bc next N, /bc stop N):" }
		for _, c in ipairs(BC.castles) do
			local count = 0
			for _ in pairs(c.state.players) do
				count = count + 1
			end
			lines[#lines + 1] = string.format("%d: %s%s, %d jugadores", c.level, c.state.status, c.state.step and (" / " .. c.state.step) or "", count)
		end
		Mubia.sendMessage(player, MESSAGE_EVENT_ADVANCE, table.concat(lines, "\n"))
	end
	return true
end

command:separator(" ")
command:groupType("god")
command:register()
