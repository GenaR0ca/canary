-- Mubia Online: Chaos Machine (ventana del cliente, opcode 83) y Fruits.
-- Las recetas están en data/libs/systems/mubia_chaos.lua.
-- El cliente manda "preview|<items>" cada vez que cambian los items, "mix|<items>" para combinar y "close".

local chaosOpcode = CreatureEvent("MubiaChaosMachine")

function chaosOpcode.onExtendedOpcode(player, opcode, buffer)
	if opcode ~= Mubia.CHAOS_OPCODE then
		return
	end

	local action, items = buffer:match("^(%a+)|?(.*)$")
	if action == "preview" then
		Mubia.chaosPreview(player, items)
	elseif action == "mix" then
		Mubia.chaosMix(player, items)
	elseif action == "close" then
		Mubia.closeChaosMachine(player)
	end
end

chaosOpcode:register()

local chaosLogin = CreatureEvent("MubiaChaosLogin")

function chaosLogin.onLogin(player)
	player:registerEvent("MubiaChaosMachine")
	return true
end

chaosLogin:register()

local chaosLogout = CreatureEvent("MubiaChaosLogout")

function chaosLogout.onLogout(player)
	Mubia.closeChaosMachine(player)
	return true
end

chaosLogout:register()

local fruits = Action()

function fruits.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	return Mubia.useFruit(player, item)
end

for itemId in pairs(Mubia.Fruits) do
	fruits:id(itemId)
end
fruits:register()
