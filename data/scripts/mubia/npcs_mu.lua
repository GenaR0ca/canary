-- Mubia Online: lo que hacen los NPCs de MU que no son tiendas.
-- Elf Soldier (buff para personajes de nivel bajo) y Lahap (junta y separa paquetes de joyas).
-- Los archivos de cada NPC están en data-canary/npc/ (elf_soldier.lua, lahap.lua).

-- Elf Soldier: como en MU, da gratis más defensa y más daño a los personajes de nivel bajo.
Mubia.ElfSoldier = {
	maxLevel = 200, -- hasta este nivel (incluido) da el buff
	duration = 60 * 60 * 1000, -- 60 minutos
	godAlways = true, -- PRUEBAS: los GOD lo reciben aunque tengan más nivel
}

-- Defensa y daño según el nivel (fórmula de MU: nivel / 5 + 50 y nivel / 3 + 45)
function Mubia.ElfSoldier.values(level)
	return math.floor(level / 5) + 50, math.floor(level / 3) + 45
end

function Mubia.ElfSoldier.give(npc, player)
	local config = Mubia.ElfSoldier
	local level = player:getLevel()
	local isGod = player:getGroup():getAccess()
	if level > config.maxLevel and not (config.godAlways and isGod) then
		npc:say(Mubia.toLatin1(string.format("Ya eres muy fuerte, %s. Mi bendición es solo para aventureros de nivel %d o menos.", player:getName(), config.maxLevel)), TALKTYPE_PRIVATE_NP, false, player)
		return false
	end

	local defense, damage = config.values(math.min(level, config.maxLevel))
	Mubia.setBuff(player, "elfSoldierDefense", defense, config.duration)
	Mubia.setBuff(player, "elfSoldierDamage", damage, config.duration)
	player:getPosition():sendMagicEffect(CONST_ME_HOLYDAMAGE)
	local minutes = math.floor(config.duration / 60000)
	npc:say(Mubia.toLatin1(string.format("Que la bendición de las elfas te proteja, %s.", player:getName())), TALKTYPE_PRIVATE_NP, false, player)
	Mubia.sendMessage(player, MESSAGE_STATUS, string.format("Elf Soldier: +%d de defensa y +%d de daño por %d minutos.", defense, damage, minutes))
	return true
end

-- El buff del Elf Soldier no se suma a Greater Defense / Greater Damage de la Elfa: vale el más alto.
if not Mubia.elfSoldierGetBuffWrapped then
	Mubia.elfSoldierGetBuffWrapped = true
	local getBuff = Mubia.getBuff
	local npcBuff = { defense = "elfSoldierDefense", damage = "elfSoldierDamage" }
	function Mubia.getBuff(creature, name)
		local value = getBuff(creature, name)
		if npcBuff[name] then
			value = math.max(value, getBuff(creature, npcBuff[name]))
		end
		return value
	end
end

-- Lahap: junta 10 Jewels of Bless o de Soul en un paquete (x10) y separa paquetes (x10, x20, x30).
Mubia.Lahap = {
	bundleZen = 0, -- PRUEBAS: gratis. En MU cuesta 500.000 zen por paquete
	unbundleZen = 0, -- PRUEBAS: gratis. En MU cuesta 1.000.000 zen por paquete
	jewels = {
		{ jewel = Mubia.JEWEL_OF_BLESS, bundle = 60309 }, -- Bless Bundle x10
		{ jewel = Mubia.JEWEL_OF_SOUL, bundle = 60312 }, -- Soul Bundle x10
	},
}

local function lahapSay(npc, player, text)
	npc:say(Mubia.toLatin1(text), TALKTYPE_PRIVATE_NP, false, player)
end

local function getBag(player)
	local bag = player:getSlotItem(CONST_SLOT_BACKPACK)
	if bag and bag:isContainer() then
		return bag
	end
end

local function payZen(player, cost)
	return cost <= 0 or player:removeMoney(cost, 0, true)
end

function Mubia.Lahap.bundle(npc, player)
	local config = Mubia.Lahap
	local bag = getBag(player)
	if not bag then
		return false
	end

	local made = {}
	for _, entry in ipairs(config.jewels) do
		local packs = math.floor(player:getItemCount(entry.jewel) / 10)
		while packs > 0 do
			if bag:getEmptySlots(false) < 1 then
				lahapSay(npc, player, "No tienes espacio en tu inventario (tecla I) para más paquetes.")
				packs = 0
				break
			end
			if not payZen(player, config.bundleZen) then
				lahapSay(npc, player, "No tienes suficiente zen.")
				packs = 0
				break
			end
			if not player:removeItem(entry.jewel, 10) then
				break
			end
			bag:addItem(entry.bundle, 1, -1, FLAG_IGNOREAUTOSTACK)
			made[entry.bundle] = (made[entry.bundle] or 0) + 1
			packs = packs - 1
		end
	end

	local names = {}
	for bundleId, count in pairs(made) do
		names[#names + 1] = string.format("%dx %s", count, ItemType(bundleId):getName())
	end
	if #names == 0 then
		lahapSay(npc, player, "Necesitas al menos 10 Jewels of Bless o 10 Jewels of Soul en tu inventario.")
		return false
	end
	player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
	lahapSay(npc, player, "Listo, aquí tienes: " .. table.concat(names, ", ") .. ".")
	return true
end

function Mubia.Lahap.unbundle(npc, player)
	local config = Mubia.Lahap
	local bag = getBag(player)
	if not bag then
		return false
	end

	local opened = 0
	for bundleId, bundle in pairs(Mubia.JewelBundles) do
		while player:getItemCount(bundleId) > 0 do
			-- las joyas se apilan: con una casilla libre alcanza (el paquete libera la suya)
			if bag:getEmptySlots(false) < 1 then
				lahapSay(npc, player, "Necesitas al menos una casilla libre en tu inventario (tecla I).")
				break
			end
			if not payZen(player, config.unbundleZen) then
				lahapSay(npc, player, "No tienes suficiente zen.")
				break
			end
			if not player:removeItem(bundleId, 1) then
				break
			end
			player:addItem(bundle.jewel, bundle.amount)
			opened = opened + 1
		end
	end

	if opened == 0 then
		lahapSay(npc, player, "No tienes paquetes de joyas para separar.")
		return false
	end
	player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
	lahapSay(npc, player, string.format("Listo, separé %d paquete(s). Las joyas están en tu inventario.", opened))
	return true
end
