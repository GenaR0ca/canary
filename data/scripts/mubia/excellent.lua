-- Mubia Online: Luck y opciones Excellent. Las reglas están en data/libs/systems/mubia_excellent.lua.

-- DSR de las armaduras: +10% de bloqueo contra monstruos (Defense Success Rate de mubia_monsters.lua).
-- Se engancha al arrancar el servidor, cuando ya están cargados todos los sistemas.
local dsrStartup = GlobalEvent("MubiaExcellentDefenseRate")

function dsrStartup.onStartup()
	if Mubia.getDefenseRate and not Mubia.baseGetDefenseRate then
		Mubia.baseGetDefenseRate = Mubia.getDefenseRate
		function Mubia.getDefenseRate(player)
			local rate = Mubia.baseGetDefenseRate(player)
			local bonus = Mubia.getEquipmentBonus(player).exc.defenseRate
			return math.floor(rate * (100 + bonus) / 100)
		end
	end
	return true
end

dsrStartup:register()

-- GOD: crea un item de MU Excellent para probar.
--   /exc legendary sword          -> Luck, opción +12 y 2 opciones Excellent al azar
--   /exc legendary sword, 6       -> con 6 opciones (todas)
--   /exc legendary sword, mh dd   -> con las opciones que elijas (siglas)
local excCommand = TalkAction("/exc")

function excCommand.onSay(player, words, param)
	local name, extra = param:match("^%s*([^,]+),?%s*(.-)%s*$")
	if not name then
		Mubia.sendMessage(player, MESSAGE_FAILURE, "Uso: /exc nombre o id del item[, cantidad de opciones o siglas]. Ejemplo: /exc legendary sword, 3")
		return true
	end
	name = name:match("^(.-)%s*$")
	local itemType = ItemType(tonumber(name) or name)
	if not itemType or itemType:getId() == 0 then
		Mubia.sendMessage(player, MESSAGE_FAILURE, "No existe un item con ese nombre o id.")
		return true
	end
	local item = Game.createItem(itemType:getId(), 1)
	if not item or not Mubia.getExcellentGroup(item) then
		if item then
			item:remove()
		end
		Mubia.sendMessage(player, MESSAGE_FAILURE, "Ese item no puede ser Excellent (solo sets, armas, escudos y alas de 2da o 3ra generación).")
		return true
	end

	local keys
	local count = tonumber(extra)
	if extra ~= "" and not count then
		keys = {}
		for key in extra:gmatch("%a+") do
			keys[#keys + 1] = key
		end
	else
		keys = Mubia.randomExcellentKeys(item, count or 2)
	end
	item:setCustomAttribute("muRolled", 1)
	item:setCustomAttribute("muLuck", 1)
	if Mubia.getItemKind(item) ~= "wings" then
		item:setCustomAttribute("muOption", 3)
	end
	Mubia.setExcellentKeys(item, keys)

	if player:addItemEx(item) ~= RETURNVALUE_NOERROR then
		item:remove()
		Mubia.sendMessage(player, MESSAGE_FAILURE, "No tienes lugar en el inventario.")
		return true
	end
	Mubia.sendMessage(player, MESSAGE_EVENT_ADVANCE, string.format("Creaste: %s (%s).", item:getName(), table.concat(Mubia.getExcellentKeys(item), ", ")))
	return true
end

excCommand:separator(" ")
excCommand:groupType("god")
excCommand:register()
