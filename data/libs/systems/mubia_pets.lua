-- Mubia Online: inventario de 40 lugares (tecla I) y mascotas de MU en su propio slot (CONST_SLOT_PET).
-- Los items los crea tools/mubia/pets.py.

-- Slot de mascotas (lo define canary.exe; el número por si el .exe todavía es el viejo)
CONST_SLOT_PET = CONST_SLOT_PET or 14

-- El inventario es una bolsa de 40 lugares que va siempre en el slot de la mochila.
-- El cliente no muestra ese slot: la bolsa se abre con la tecla I. No se puede sacar ni perder.
Mubia.INVENTORY_BAG = 60500

-- damage y absorb en %, hp suma vida máxima, attackSpeed baja el tiempo entre golpes en %,
-- speed suma velocidad al caminar (monturas) y exp da % de experiencia extra.
Mubia.Pets = {
	[60501] = { name = "Guardian Angel", absorb = 20, hp = 50 },
	[60502] = { name = "Imp", damage = 30 },
	[60503] = { name = "Horn of Uniria", mount = true, speed = 40 },
	[60504] = { name = "Horn of Dinorant", mount = true, damage = 15, absorb = 10, speed = 60 },
	[60505] = { name = "Horn of Fenrir", mount = true, damage = 10, absorb = 10, speed = 100 },
	[60506] = { name = "Demon", damage = 40, attackSpeed = 10 },
	[60507] = { name = "Spirit of Guardian", absorb = 30, hp = 50 },
	[60508] = { name = "Pet Skeleton", damage = 20, attackSpeed = 10 },
	[60509] = { name = "Pet Panda", exp = 50 },
}

local NO_PET = {}

-- La mascota equipada (o una tabla vacía)
function Mubia.getPet(player)
	local item = player:getSlotItem(CONST_SLOT_PET)
	return item and Mubia.Pets[item:getId()] or NO_PET
end

function Mubia.getPetLookText(item)
	local pet = Mubia.Pets[item:getId()]
	if not pet then
		return nil
	end
	local lines = { pet.mount and "Montura. Va en el slot de mascotas." or "Mascota. Va en el slot de mascotas." }
	if pet.damage then
		lines[#lines + 1] = string.format("Aumenta el daño %d%%.", pet.damage)
	end
	if pet.absorb then
		lines[#lines + 1] = string.format("Absorbe el %d%% del daño recibido.", pet.absorb)
	end
	if pet.hp then
		lines[#lines + 1] = string.format("Vida máxima +%d.", pet.hp)
	end
	if pet.attackSpeed then
		lines[#lines + 1] = string.format("Velocidad de ataque +%d%%.", pet.attackSpeed)
	end
	if pet.speed then
		lines[#lines + 1] = string.format("Velocidad al caminar +%d.", pet.speed)
	end
	if pet.exp then
		lines[#lines + 1] = string.format("Experiencia +%d%%.", pet.exp)
	end
	return Mubia.toLatin1(table.concat(lines, "\n"))
end

local PET_SPEED_SUBID = 60500

-- Aplica la mascota equipada: velocidad de las monturas y vida / velocidad de ataque (Mubia.recalc)
function Mubia.applyPet(player)
	player:removeCondition(CONDITION_HASTE, CONDITIONID_COMBAT, PET_SPEED_SUBID)
	local pet = Mubia.getPet(player)
	if pet.speed then
		local condition = Condition(CONDITION_HASTE, CONDITIONID_COMBAT)
		condition:setParameter(CONDITION_PARAM_SUBID, PET_SPEED_SUBID)
		condition:setParameter(CONDITION_PARAM_TICKS, -1)
		condition:setParameter(CONDITION_PARAM_SPEED, pet.speed)
		player:addCondition(condition)
	end
	Mubia.recalc(player)
end

-- Se asegura de que el jugador tenga el inventario de 40 lugares en el slot de la mochila.
-- Si tenía una mochila de Tibia, pasa lo que tenía adentro al inventario nuevo.
function Mubia.ensureInventory(player)
	local old = player:getSlotItem(CONST_SLOT_BACKPACK)
	if old and old:getId() == Mubia.INVENTORY_BAG then
		return false
	end

	local bag = Game.createItem(Mubia.INVENTORY_BAG, 1)
	if not bag then
		return false
	end

	local leftovers = 0
	if old then
		local oldContainer = old:isContainer() and old
		if oldContainer then
			for i = oldContainer:getSize() - 1, 0, -1 do
				local child = oldContainer:getItem(i)
				if child and bag:getEmptySlots() > 0 then
					local copy = child:clone()
					if copy and bag:addItemEx(copy) == RETURNVALUE_NOERROR then
						child:remove()
					end
				end
			end
			leftovers = oldContainer:getSize()
		end
		if leftovers > 0 then
			-- no entró todo: la mochila vieja queda en el piso con lo que sobró
			old:moveTo(player:getPosition())
		else
			old:remove()
		end
	end

	player:addItemEx(bag, false, CONST_SLOT_BACKPACK)
	if leftovers > 0 then
		Mubia.sendMessage(player, MESSAGE_LOGIN, string.format("Tu inventario ahora tiene 40 lugares (tecla I). No entró todo: tu mochila vieja quedó en el piso con %d cosas.", leftovers))
	elseif old then
		Mubia.sendMessage(player, MESSAGE_LOGIN, "Tu inventario ahora tiene 40 lugares (tecla I). Lo que tenías en la mochila ya está adentro.")
	end
	return true
end
