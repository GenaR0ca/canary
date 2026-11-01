-- Mubia Online: items que caen de los monstruos al piso. Reglas en data/libs/systems/mubia_drops.lua.

-- Los primeros segundos solo los puede agarrar quien mató al monstruo (o su party)
local protect = EventCallback("MubiaDropProtect")

function protect.playerOnMoveItem(player, item, count, fromPosition, toPosition, fromCylinder, toCylinder)
	if fromPosition.x ~= CONTAINER_POSITION and Mubia.isDropOnGround(item) and not Mubia.canPickDrop(player, item) then
		Mubia.sendMessage(player, MESSAGE_FAILURE, "Este item todavía no es tuyo: espera unos segundos.")
		return false
	end
	return true
end

protect:register()

-- Al levantarlo deja de ser un drop (ya no desaparece)
local picked = EventCallback("MubiaDropPicked")

function picked.playerOnItemMoved(player, item, count, fromPosition, toPosition, fromCylinder, toCylinder)
	if toPosition.x == CONTAINER_POSITION and Mubia.isDropOnGround(item) then
		Mubia.clearDropMarks(item)
	end
end

picked:register()
