-- Mubia Online: MU Helper (opcode 86). Reglas en data/libs/systems/mubia_helper.lua.

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
	return true
end

helperLogin:register()

local helperLogout = CreatureEvent("MubiaHelperLogout")

function helperLogout.onLogout(player)
	Mubia.helpers[player:getId()] = nil
	return true
end

helperLogout:register()
