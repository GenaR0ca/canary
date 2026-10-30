-- Mubia Online: inventario de 40 lugares (tecla I) y slot de mascotas. Las reglas están en data/libs/systems/mubia_pets.lua.

local inventoryLogin = CreatureEvent("MubiaInventoryLogin")

-- Las manos solo llevan armas y escudos: lo demás (guantes, armaduras...) va a su slot o al inventario
local HAND_SLOTS = { CONST_SLOT_LEFT, CONST_SLOT_RIGHT }
local PIECE_SLOT = { helm = CONST_SLOT_HEAD, armor = CONST_SLOT_ARMOR, pants = CONST_SLOT_LEGS, gloves = CONST_SLOT_GLOVES, boots = CONST_SLOT_FEET }

local function canGoInHand(item)
	return item:getType():getWeaponType() ~= WEAPON_NONE
end

local function fixHands(player)
	local bag = player:getSlotItem(CONST_SLOT_BACKPACK)
	for _, handSlot in ipairs(HAND_SLOTS) do
		local item = player:getSlotItem(handSlot)
		if item and not canGoInHand(item) then
			local gear = Mubia.Gear[item:getId()]
			local slot = gear and PIECE_SLOT[gear.piece]
			if not (slot and not player:getSlotItem(slot) and item:moveToSlot(player, slot)) and bag then
				item:moveTo(bag)
			end
		end
	end
end

-- Un Dark Raven que quedó en el slot de mascotas (antes iba ahí) vuelve al inventario
local function fixPetSlot(player)
	local item = player:getSlotItem(CONST_SLOT_PET)
	local pet = item and Mubia.Pets[item:getId()]
	local bag = player:getSlotItem(CONST_SLOT_BACKPACK)
	if pet and pet.hand and bag then
		item:moveTo(bag)
	end
end

function inventoryLogin.onLogin(player)
	Mubia.ensureInventory(player)
	fixHands(player)
	fixPetSlot(player)
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
	if toPosition.x == CONTAINER_POSITION and (toPosition.y == CONST_SLOT_LEFT or toPosition.y == CONST_SLOT_RIGHT) and not canGoInHand(item) then
		local gear = Mubia.Gear[item:getId()]
		if gear and gear.piece == "gloves" then
			Mubia.sendMessage(player, MESSAGE_FAILURE, "Los guantes van en su slot, a la izquierda del pantalón.")
		else
			Mubia.sendMessage(player, MESSAGE_FAILURE, "En las manos solo van armas y escudos.")
		end
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
	elseif fromPosition.x == CONTAINER_POSITION and (fromPosition.y == CONST_SLOT_LEFT or fromPosition.y == CONST_SLOT_RIGHT) or toPosition.x == CONTAINER_POSITION and (toPosition.y == CONST_SLOT_LEFT or toPosition.y == CONST_SLOT_RIGHT) then
		Mubia.syncHandPet(player)
	end
end

petChange:register()
