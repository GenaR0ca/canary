-- Mubia Online: inventario de 40 lugares (tecla I) y mascotas de MU en su propio slot (CONST_SLOT_PET).
-- Los items los crea tools/mubia/pets.py.

-- Slot de mascotas (lo define canary.exe; el número por si el .exe todavía es el viejo)
CONST_SLOT_PET = CONST_SLOT_PET or 14

-- El inventario es una bolsa de 40 lugares que va siempre en el slot de la mochila.
-- El cliente no muestra ese slot: la bolsa se abre con la tecla I. No se puede sacar ni perder.
Mubia.INVENTORY_BAG = 60500

-- damage y absorb en %, hp suma vida máxima, attackSpeed baja el tiempo entre golpes en %,
-- speed suma velocidad al caminar (monturas), exp da % de experiencia extra y zen % de zen extra.
-- mount = montura de Tibia que se ve al equiparla (id de mounts.xml y su clientid).
-- follower = criatura que te sigue (data-canary/monster/mubia/pets). level = nivel mínimo.
Mubia.Pets = {
	[60501] = { name = "Guardian Angel", absorb = 20, hp = 50, follower = "Guardian Angel" },
	[60502] = { name = "Imp", damage = 30, follower = "Imp" },
	[60503] = { name = "Horn of Uniria", speed = 40, mount = { id = 114, look = 1018 } }, -- Arctic Unicorn
	[60504] = { name = "Horn of Dinorant", damage = 15, absorb = 10, speed = 60, mount = { id = 6, look = 373 } }, -- Draptor
	[60505] = { name = "Horn of Fenrir", speed = 100, level = 300, mount = { id = 39, look = 559 } }, -- The Hellgrip (rojo)
	[60506] = { name = "Demon", damage = 40, attackSpeed = 10, follower = "Pet Demon" },
	[60507] = { name = "Spirit of Guardian", absorb = 30, hp = 50, follower = "Spirit of Guardian" },
	[60508] = { name = "Pet Skeleton", damage = 20, attackSpeed = 10, follower = "Pet Skeleton" },
	[60509] = { name = "Pet Panda", exp = 50, follower = "Pet Panda" },
	-- Dark Horse y Dark Raven son del Dark Lord: cuando exista la clase, se le puede limitar
	[60510] = { name = "Dark Horse", absorb = 15, speed = 80, mount = { id = 17, look = 392 } }, -- War Horse
	[60511] = { name = "Dark Raven", follower = "Dark Raven", attacks = true },
	[60512] = { name = "Black Fenrir", damage = 10, speed = 100, level = 300, mount = { id = 32, look = 515 } }, -- Gnarlhound
	[60513] = { name = "Blue Fenrir", absorb = 10, speed = 100, level = 300, mount = { id = 16, look = 390 } }, -- Crystal Wolf
	[60514] = { name = "Gold Fenrir", damage = 10, absorb = 10, hp = 200, speed = 100, level = 300, mount = { id = 40, look = 571 } }, -- Noble Lion
	[60515] = { name = "Pet Rudolf", zen = 30, follower = "Pet Rudolf" },
	[60516] = { name = "Pet Unicorn", zen = 50, absorb = 5, follower = "Pet Unicorn" },
}

-- Nombres de las criaturas que siguen a su dueño (para no confundirlas con las invocaciones de la elfa)
Mubia.PetFollowers = {}
for _, pet in pairs(Mubia.Pets) do
	if pet.follower then
		Mubia.PetFollowers[pet.follower] = true
	end
end

local NO_PET = {}

-- La mascota equipada (o una tabla vacía)
function Mubia.getPet(player)
	local item = player:getSlotItem(CONST_SLOT_PET)
	return item and Mubia.Pets[item:getId()] or NO_PET
end

-- Líneas de lo que hace la mascota (en UTF-8). withLevel: incluir "Nivel mínimo".
function Mubia.getPetLines(item, withLevel)
	local pet = Mubia.Pets[item:getId()]
	if not pet then
		return nil
	end
	local lines = { pet.mount and "Montura. Va en el slot de mascotas." or "Mascota. Va en el slot de mascotas." }
	if pet.attacks then
		lines[#lines + 1] = "Ataca a tu objetivo."
	end
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
	if pet.zen then
		lines[#lines + 1] = string.format("Zen +%d%%.", pet.zen)
	end
	if withLevel and pet.level then
		lines[#lines + 1] = string.format("Nivel mínimo: %d.", pet.level)
	end
	return lines
end

function Mubia.getPetLookText(item)
	local lines = Mubia.getPetLines(item, true)
	return lines and Mubia.toLatin1(table.concat(lines, "\n"))
end

local PET_SPEED_SUBID = 60500

-- Revisa si el jugador puede equipar la mascota (por ahora solo el nivel)
function Mubia.checkPetRequirements(player, itemId)
	local pet = Mubia.Pets[itemId]
	if pet and pet.level and player:getLevel() < pet.level then
		return false, string.format("Para usar %s necesitas nivel %d.", pet.name, pet.level)
	end
	return true
end

-- Saca la montura de mascota anterior (si se la habíamos dado nosotros) y la criatura que lo seguía
local function clearPet(player)
	local kv = player:kv():scoped("mubia-pet")
	local mountId = kv:get("mount")
	if mountId then
		local outfit = player:getOutfit()
		for _, pet in pairs(Mubia.Pets) do
			if pet.mount and pet.mount.id == mountId and outfit.lookMount == pet.mount.look then
				outfit.lookMount = 0
				player:setOutfit(outfit)
			end
		end
		if kv:get("addedMount") then
			player:removeMount(mountId)
		end
		kv:remove("mount")
		kv:remove("addedMount")
	end
	for _, summon in ipairs(player:getSummons()) do
		if Mubia.PetFollowers[summon:getName()] then
			summon:remove()
		end
	end
end

-- Pone a la criatura de la mascota al lado del jugador
local function spawnFollower(playerId, name)
	local player = Player(playerId)
	if not player or Mubia.getPet(player).follower ~= name then
		return
	end
	for _, summon in ipairs(player:getSummons()) do
		if summon:getName() == name then
			return
		end
	end
	local follower = Game.createMonster(name, player:getPosition(), true, true, player)
	if follower then
		follower:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
	end
end

-- Aplica la mascota equipada: velocidad, montura, criatura que te sigue y vida / velocidad de ataque (Mubia.recalc)
function Mubia.applyPet(player)
	player:removeCondition(CONDITION_HASTE, CONDITIONID_COMBAT, PET_SPEED_SUBID)
	clearPet(player)
	local pet = Mubia.getPet(player)
	if pet.speed then
		local condition = Condition(CONDITION_HASTE, CONDITIONID_COMBAT)
		condition:setParameter(CONDITION_PARAM_SUBID, PET_SPEED_SUBID)
		condition:setParameter(CONDITION_PARAM_TICKS, -1)
		condition:setParameter(CONDITION_PARAM_SPEED, pet.speed)
		player:addCondition(condition)
	end
	if pet.mount then
		local kv = player:kv():scoped("mubia-pet")
		kv:set("mount", pet.mount.id)
		if not player:hasMount(pet.mount.id) then
			player:addMount(pet.mount.id)
			kv:set("addedMount", true)
		end
		local outfit = player:getOutfit()
		outfit.lookMount = pet.mount.look
		player:setOutfit(outfit)
	end
	if pet.follower then
		addEvent(spawnFollower, 300, player:getId(), pet.follower)
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
