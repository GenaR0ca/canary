-- Mubia Online: eventos de personaje (stats MU)

local mubiaLogin = CreatureEvent("MubiaLogin")

function mubiaLogin.onLogin(player)
	player:registerEvent("MubiaAdvance")
	player:registerEvent("MubiaExtendedOpcode")
	if Mubia.initPlayer(player) then
		if Mubia.applyStartLevel(player) then
			Mubia.sendMessage(player, MESSAGE_LOGIN, string.format("Mubia ahora empieza en nivel %d: tu personaje volvió a ese nivel con los stats base de su clase.", Mubia.Config.startLevel))
		end
		if Mubia.applyTestLevel(player) then
			Mubia.sendMessage(player, MESSAGE_LOGIN, string.format("Modo pruebas: tu personaje subió a nivel %d.", Mubia.Config.testLevel))
		end
		Mubia.recalc(player)
		local stats = Mubia.getStats(player)
		if stats.points > 0 then
			local commands = Mubia.classUsesStat(Mubia.getClass(player), "cmd") and "/addstr, /addagi, /addvit, /addene o /addcmd" or "/addstr, /addagi, /addvit o /addene"
			Mubia.sendMessage(player, MESSAGE_LOGIN, string.format("Tienes %d puntos para repartir. Usa %s (ejemplo: /addstr 10). Escribe /stats para ver tus stats.", stats.points, commands))
		end
		addEvent(function(playerId)
			local p = Player(playerId)
			if p then
				-- después de los items iniciales de Canary (así ya tiene mochila)
				if Mubia.removeTibiaGear(p) > 0 then
					Mubia.sendMessage(p, MESSAGE_LOGIN, "Los sets y armas de Tibia ya no existen en Mubia: se sacaron de tu equipo.")
				end
				if Mubia.giveStarterGear(p) then
					Mubia.sendMessage(p, MESSAGE_LOGIN, "Recibiste el set inicial de MU de tu clase. Si no se equipó, está en tu mochila: necesitas más STR o AGI.")
				end
				Mubia.sendStats(p)
			end
		end, 1000, player:getId())
	end
	return true
end

mubiaLogin:register()

local mubiaAdvance = CreatureEvent("MubiaAdvance")

function mubiaAdvance.onAdvance(player, skill, oldLevel, newLevel)
	if skill ~= SKILL_LEVEL or not Mubia.getClass(player) then
		return true
	end

	if newLevel > oldLevel then
		local gained = (newLevel - oldLevel) * Mubia.getPointsPerLevel(Mubia.getClass(player))
		Mubia.addPoints(player, gained)
		Mubia.sendMessage(player, MESSAGE_EVENT_ADVANCE, string.format("Has ganado %d puntos de stats.", gained))
	end
	Mubia.recalc(player)
	player:addHealth(player:getMaxHealth())
	player:addMana(player:getMaxMana())
	Mubia.sendStats(player)
	return true
end

mubiaAdvance:register()

-- Peticiones de la ventana de stats del cliente: "add:str:10" o "get"
local mubiaOpcode = CreatureEvent("MubiaExtendedOpcode")

function mubiaOpcode.onExtendedOpcode(player, opcode, buffer)
	if opcode ~= Mubia.Config.opcode then
		return
	end

	local action, stat, amount = buffer:match("^(%a+):?(%a*):?(%d*)$")
	if action == "add" then
		local ok, message = Mubia.addStat(player, stat, amount)
		Mubia.sendMessage(player, ok and MESSAGE_EVENT_ADVANCE or MESSAGE_FAILURE, message)
	elseif action == "get" then
		Mubia.sendStats(player)
	end
end

mubiaOpcode:register()
