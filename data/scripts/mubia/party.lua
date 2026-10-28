-- Mubia Online: party de máximo 5 y panel de vida de la party (data/libs/systems/mubia_party.lua).

-- No deja entrar a nadie si la party ya tiene el máximo de personas
local join = EventCallback("MubiaPartyLimit")

function join.partyOnJoin(party, player)
	local max = Mubia.PartyConfig.maxMembers
	if Mubia.isPartyFull(party) then
		Mubia.sendMessage(player, MESSAGE_PARTY_MANAGEMENT, string.format("Esa party ya está llena (máximo %d personas).", max))
		local leader = party:getLeader()
		if leader then
			Mubia.sendMessage(leader, MESSAGE_PARTY_MANAGEMENT, string.format("%s no pudo entrar: la party ya tiene %d personas.", player:getName(), max))
		end
		return false
	end

	-- el jugador recién entra después de esto: se revisa un instante más tarde
	local leader = party:getLeader()
	local leaderId = leader and leader:getId()
	addEvent(function()
		local leaderNow = leaderId and Player(leaderId)
		local partyNow = leaderNow and leaderNow:getParty()
		if partyNow then
			Mubia.revokeExtraInvites(partyNow)
		end
		Mubia.updatePartyPanels()
	end, 100)
	return true
end

join:register()

-- Panel de vida: se actualiza cada medio segundo (solo se manda si algo cambió)
local panel = GlobalEvent("MubiaPartyPanel")

function panel.onThink(interval)
	Mubia.updatePartyPanels()
	return true
end

panel:interval(500)
panel:register()

-- al entrar al juego se borra lo último mandado, así el cliente recibe la party de nuevo
local login = CreatureEvent("MubiaPartyLogin")

function login.onLogin(player)
	Mubia.forgetPartyPanel(player)
	return true
end

login:register()

local logout = CreatureEvent("MubiaPartyLogout")

function logout.onLogout(player)
	Mubia.forgetPartyPanel(player)
	return true
end

logout:register()
