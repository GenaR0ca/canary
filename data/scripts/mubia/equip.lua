-- Mubia Online: clic derecho en un set, arma, escudo, alas o mascota de MU para equiparlo o sacártelo.
-- Si está en el inventario y cumples los requisitos, va a su slot (lo que había ahí vuelve al inventario).
-- Si ya lo tienes puesto, vuelve al inventario (tecla I).

local PIECE_SLOT = { helm = CONST_SLOT_HEAD, armor = CONST_SLOT_ARMOR, pants = CONST_SLOT_LEGS, gloves = CONST_SLOT_GLOVES, boots = CONST_SLOT_FEET }

-- Slot donde va el item (o nil si no es equipo de MU)
local function getTargetSlot(itemId)
	if Mubia.Wings[itemId] then
		return CONST_SLOT_WINGS
	elseif Mubia.Pets[itemId] then
		return CONST_SLOT_PET
	end
	local gear = Mubia.Gear[itemId]
	if not gear then
		return nil
	elseif gear.kind == "armor" then
		return PIECE_SLOT[gear.piece]
	elseif gear.kind == "shield" then
		return CONST_SLOT_RIGHT
	end
	return CONST_SLOT_LEFT -- armas y bastones
end

local function isShield(item)
	return item:getType():getWeaponType() == WEAPON_SHIELD
end

local function isTwoHanded(item)
	local gear = Mubia.Gear[item:getId()]
	return gear and gear.twoHanded or false
end

local function isEquipped(position)
	return position.x == CONTAINER_POSITION and position.y < 0x40
end

-- Lo que hay en la otra mano y no puede quedarse (arma de dos manos, dos escudos, dos armas)
local function getHandConflict(player, item, slot)
	if slot == CONST_SLOT_LEFT then
		local other = player:getSlotItem(CONST_SLOT_RIGHT)
		if other and (isTwoHanded(item) or not isShield(other)) then
			return other
		end
	elseif slot == CONST_SLOT_RIGHT then
		local other = player:getSlotItem(CONST_SLOT_LEFT)
		if other and (isTwoHanded(other) or isShield(other)) then
			return other
		end
	end
	return nil
end

local function refresh(player, slot)
	Mubia.recalc(player)
	Mubia.sendStats(player)
	if slot == CONST_SLOT_PET then
		Mubia.applyPet(player)
	end
end

local function toInventory(player, item)
	local bag = player:getSlotItem(CONST_SLOT_BACKPACK)
	if not bag or not bag:isContainer() or bag:getEmptySlots() == 0 then
		return false
	end
	return item:moveTo(bag)
end

local equipAction = Action()

function equipAction.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local slot = getTargetSlot(item:getId())
	if not slot or fromPosition.x ~= CONTAINER_POSITION then
		Mubia.sendMessage(player, MESSAGE_FAILURE, "Primero levanta el item.")
		return true
	end

	-- Ya lo tiene puesto: se lo saca
	if isEquipped(fromPosition) then
		local fromSlot = fromPosition.y
		if not toInventory(player, item) then
			Mubia.sendMessage(player, MESSAGE_FAILURE, "No tienes lugar en el inventario.")
			return true
		end
		refresh(player, fromSlot)
		return true
	end

	local ok, reason = Mubia.checkEquipRequirements(player, item)
	if not ok then
		Mubia.sendMessage(player, MESSAGE_FAILURE, reason)
		return true
	end

	local conflict = getHandConflict(player, item, slot)
	if conflict and not toInventory(player, conflict) then
		Mubia.sendMessage(player, MESSAGE_FAILURE, "No tienes lugar en el inventario para lo que tienes en la otra mano.")
		return true
	end

	-- Si el slot está ocupado, el servidor los intercambia: lo que había vuelve a donde estaba este item
	if not item:moveToSlot(player, slot) then
		Mubia.sendMessage(player, MESSAGE_FAILURE, "No puedes equiparte este item ahora.")
	end
	refresh(player, slot)
	return true
end

for itemId in pairs(Mubia.Gear) do
	equipAction:id(itemId)
end
for itemId in pairs(Mubia.Wings) do
	equipAction:id(itemId)
end
for itemId in pairs(Mubia.Pets) do
	equipAction:id(itemId)
end
equipAction:register()
