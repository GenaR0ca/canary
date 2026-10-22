-- Mubia Online: inventario de 40 lugares (tecla I) y slot de mascotas. Las reglas están en data/libs/systems/mubia_pets.lua.

local inventoryLogin = CreatureEvent("MubiaInventoryLogin")

function inventoryLogin.onLogin(player)
	Mubia.ensureInventory(player)
	Mubia.applyPet(player)
	return true
end

inventoryLogin:register()

local inventoryMove = EventCallback("MubiaInventoryMove")

-- El inventario no se puede sacar de su lugar
function inventoryMove.playerOnMoveItem(player, item, count, fromPosition, toPosition, fromCylinder, toCylinder)
	if item:getId() == Mubia.INVENTORY_BAG then
		Mubia.sendMessage(player, MESSAGE_FAILURE, "El inventario no se puede mover. Se abre con la tecla I.")
		return false
	end
	return true
end

inventoryMove:register()

local inventoryTrade = EventCallback("MubiaInventoryTrade")

function inventoryTrade.playerOnTradeRequest(player, target, item)
	if item:getId() == Mubia.INVENTORY_BAG then
		Mubia.sendMessage(player, MESSAGE_FAILURE, "No puedes intercambiar tu inventario entero. Elige un item de adentro.")
		return false
	end
	return true
end

inventoryTrade:register()

-- Al poner o sacar una mascota se aplican sus bonus (vida, velocidad)
local petChange = EventCallback("MubiaPetChange")

function petChange.playerOnItemMoved(player, item, count, fromPosition, toPosition, fromCylinder, toCylinder)
	if fromPosition.x == CONTAINER_POSITION and fromPosition.y == CONST_SLOT_PET or toPosition.x == CONTAINER_POSITION and toPosition.y == CONST_SLOT_PET then
		Mubia.applyPet(player)
	end
end

petChange:register()
