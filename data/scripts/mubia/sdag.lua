-- Mubia Online: barras de SD y AG. Reglas en data/libs/systems/mubia_sdag.lua.

local sdagLogin = CreatureEvent("MubiaSDAGLogin")

function sdagLogin.onLogin(player)
	addEvent(function(playerId)
		local p = Player(playerId)
		if p then
			Mubia.sendSDAG(p)
		end
	end, 1500, player:getId())
	return true
end

sdagLogin:register()

local sdagLogout = CreatureEvent("MubiaSDAGLogout")

function sdagLogout.onLogout(player)
	Mubia.saveSDAG(player)
	return true
end

sdagLogout:register()

local sdagRegen = GlobalEvent("MubiaSDAGRegen")

function sdagRegen.onThink(interval)
	for _, player in ipairs(Game.getPlayers()) do
		Mubia.regenSDAG(player)
	end
	return true
end

sdagRegen:interval(3000)
sdagRegen:register()
