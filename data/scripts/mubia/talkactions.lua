-- Mubia Online: comandos de stats estilo MU (/addstr 10, /stats, /reset)

for _, stat in ipairs(Mubia.STATS) do
	local addStat = TalkAction("/add" .. stat)

	function addStat.onSay(player, words, param)
		local ok, message = Mubia.addStat(player, stat, param)
		Mubia.sendMessage(player, ok and MESSAGE_EVENT_ADVANCE or MESSAGE_FAILURE, message)
		return true
	end

	addStat:separator(" ")
	addStat:groupType("normal")
	addStat:register()
end

local showStats = TalkAction("/stats")

function showStats.onSay(player, words, param)
	local class = Mubia.getClass(player)
	if not class then
		Mubia.sendMessage(player, MESSAGE_FAILURE, "Tu clase no usa stats.")
		return true
	end

	local stats = Mubia.getStats(player)
	local minDamage, maxDamage = class.damage(stats)
	local magicText = "-"
	if class.magic then
		local minMagic, maxMagic = class.magic(stats)
		magicText = string.format("%d-%d", minMagic, maxMagic)
	end
	local lines = {
		string.format("%s | Nivel %d | Resets %d", class.name, player:getLevel(), stats.resets),
		string.format("STR %d | AGI %d | VIT %d | ENE %d | Puntos libres: %d", stats.str, stats.agi, stats.vit, stats.ene, stats.points),
		string.format("Daño físico %d-%d | Daño mágico %s | Defensa %d", minDamage, maxDamage, magicText, class.defense(stats)),
		string.format("Vel. ataque %.2fs | Vel. magia %.2fs | Vida %d | Mana %d", Mubia.getAttackSpeed(class, stats) / 1000, Mubia.getCastSpeed(class, stats) / 1000, player:getMaxHealth(), player:getMaxMana()),
	}
	Mubia.sendMessage(player, MESSAGE_EVENT_ADVANCE, table.concat(lines, "\n"))
	Mubia.sendStats(player)
	return true
end

showStats:groupType("normal")
showStats:register()

local resetCommand = TalkAction("/reset")

function resetCommand.onSay(player, words, param)
	local ok, message = Mubia.reset(player)
	Mubia.sendMessage(player, ok and MESSAGE_EVENT_ADVANCE or MESSAGE_FAILURE, message)
	return true
end

resetCommand:groupType("normal")
resetCommand:register()
