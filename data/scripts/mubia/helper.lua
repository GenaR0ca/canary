-- Mubia Online: Mubia Helper (opcode 86). Reglas en data/libs/systems/mubia_helper.lua.

local helperOpcode = CreatureEvent("MubiaHelperOpcode")

function helperOpcode.onExtendedOpcode(player, opcode, buffer)
	if opcode ~= Mubia.HELPER_OPCODE then
		return
	end
	Mubia.onHelperOpcode(player, buffer)
end

helperOpcode:register()

local helperLogin = CreatureEvent("MubiaHelperLogin")

function helperLogin.onLogin(player)
	player:registerEvent("MubiaHelperOpcode")
	Mubia.loadAutoQuiver(player)
	return true
end

helperLogin:register()

local helperLogout = CreatureEvent("MubiaHelperLogout")

function helperLogout.onLogout(player)
	Mubia.helpers[player:getId()] = nil
	return true
end

helperLogout:register()

-- Cada segundo: aceptar o rechazar parties y llenar el quiver de la elfa (pestaña "Other Settings" del Helper)
local partyInvites = GlobalEvent("MubiaHelperPartyInvites")

function partyInvites.onThink(interval)
	Mubia.checkPartyInvites()
	Mubia.checkAutoQuivers()
	return true
end

partyInvites:interval(1000)
partyInvites:register()
