-- Mubia Online: Devil Square. Reglas y configuración en data/libs/systems/mubia_devil_square.lua.

local DS = Mubia.DevilSquare

-- reloj del evento: cada segundo revisa las arenas (espera, oleadas, jefes y final)
local think = GlobalEvent("MubiaDevilSquareThink")

function think.onThink(interval)
	DS.think()
	return true
end

think:interval(1000)
think:register()

-- puntos por cada monstruo del evento
local death = CreatureEvent("MubiaDevilSquareDeath")

function death.onDeath(creature, corpse, killer, mostDamageKiller, lastHitUnjustified, mostDamageUnjustified)
	DS.onMonsterDeath(creature, killer, mostDamageKiller)
	return true
end

death:register()

-- si entra al juego dentro de una arena sin evento, vuelve afuera
local login = CreatureEvent("MubiaDevilSquareLogin")

function login.onLogin(player)
	DS.onLogin(player)
	return true
end

login:register()

-- experiencia ganada adentro (el final da un % extra)
local experience = EventCallback("MubiaDevilSquareExperience")

function experience.playerOnGainExperience(player, target, exp, rawExp)
	DS.onGainExperience(player, target, exp)
end

experience:register()

-- Devil's Eye y Devil's Key en el botín de los monstruos de afuera
local drop = EventCallback("MubiaDevilSquareDrop")

function drop.monsterPostDropLoot(monster, corpse)
	DS.rollDrop(monster, corpse)
end

drop:register()

-- GOD: /ds (lista), /ds 3 (entrar a la +3), /ds items (todos los Eye, Key e Invitation),
-- /ds start 3 (empieza ya sin esperar), /ds stop 3 (termina ya y reparte premios)
local command = TalkAction("/ds")

function command.onSay(player, words, param)
	local args = param:split(" ")
	local action = (args[1] or ""):lower()
	local level = tonumber(args[2] or args[1])
	local square = level and DS.squares[level]

	if action == "items" then
		for i = 0, #DS.squares - 1 do
			player:addItem(DS.EYE + i, 1)
			player:addItem(DS.KEY + i, 1)
			player:addItem(DS.INVITATION + i, 1)
		end
		Mubia.sendMessage(player, MESSAGE_EVENT_ADVANCE, "Recibiste Devil's Eye, Key e Invitation de +1 a +7.")
	elseif action == "start" and square then
		if square.state.status == "waiting" then
			square.state.startAt = os.time()
			square.state.endAt = square.state.startAt + DS.duration
		end
		Mubia.sendMessage(player, MESSAGE_EVENT_ADVANCE, string.format("Devil Square +%d: %s.", level, square.state.status == "idle" and "no hay nadie adentro" or "empieza ya"))
	elseif action == "stop" and square then
		if square.state.status == "running" or square.state.status == "waiting" then
			DS.finish(square)
		end
		Mubia.sendMessage(player, MESSAGE_EVENT_ADVANCE, string.format("Devil Square +%d terminada.", level))
	elseif square then
		DS.enter(player, square)
	else
		local lines = { "Devil Square (/ds N entra, /ds items, /ds start N, /ds stop N):" }
		for _, sq in ipairs(DS.squares) do
			local count = 0
			for _ in pairs(sq.state.players) do
				count = count + 1
			end
			lines[#lines + 1] = string.format("+%d: %s, %d jugadores", sq.level, sq.state.status, count)
		end
		Mubia.sendMessage(player, MESSAGE_EVENT_ADVANCE, table.concat(lines, "\n"))
	end
	return true
end

command:separator(" ")
command:groupType("god")
command:register()
