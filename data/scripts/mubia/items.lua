-- Mubia Online: Jewels de MU (Bless, Soul, Life) y alas. Las reglas están en data/libs/systems/mubia_items.lua.

local function say(player, text)
	Mubia.sendMessage(player, MESSAGE_EVENT_ADVANCE, text)
end

local function finish(player, success)
	player:getPosition():sendMagicEffect(success and CONST_ME_FIREWORK_YELLOW or CONST_ME_POFF)
	Mubia.sendStats(player)
end

local function useBless(player, target)
	local level = Mubia.getItemLevel(target)
	if level >= Mubia.ItemConfig.blessMaxLevel then
		say(player, string.format("Jewel of Bless sube items hasta +%d. Para seguir usá Jewel of Soul.", Mubia.ItemConfig.blessMaxLevel))
		return false
	end
	Mubia.setItemLevel(target, level + 1)
	say(player, string.format("¡Éxito! Tu item ahora es +%d.", level + 1))
	finish(player, true)
	return true
end

local function useSoul(player, target)
	local level = Mubia.getItemLevel(target)
	if level < Mubia.ItemConfig.blessMaxLevel then
		say(player, string.format("Primero subí el item a +%d con Jewel of Bless.", Mubia.ItemConfig.blessMaxLevel))
		return false
	end
	if level >= Mubia.ItemConfig.maxLevel then
		say(player, string.format("Este item ya está en +%d, el máximo.", Mubia.ItemConfig.maxLevel))
		return false
	end
	local chance = Mubia.ItemConfig.soulChance[level + 1] or 0
	if math.random(100) <= chance then
		Mubia.setItemLevel(target, level + 1)
		say(player, string.format("¡Éxito! Tu item ahora es +%d.", level + 1))
		finish(player, true)
	else
		local newLevel = math.max(0, level - Mubia.ItemConfig.soulFailLevels)
		Mubia.setItemLevel(target, newLevel)
		say(player, string.format("Falló (tenía %d%% de éxito). Tu item bajó a +%d.", chance, newLevel))
		finish(player, false)
	end
	return true
end

local function useLife(player, target)
	local option = Mubia.getItemOption(target)
	local step = Mubia.ItemConfig.optionStep
	if option >= Mubia.ItemConfig.maxOption then
		say(player, string.format("Este item ya tiene la opción máxima (+%d).", option * step))
		return false
	end
	if math.random(100) <= Mubia.ItemConfig.lifeChance then
		Mubia.setItemOption(target, option + 1)
		say(player, string.format("¡Éxito! Opción adicional +%d.", (option + 1) * step))
		finish(player, true)
	else
		if Mubia.ItemConfig.lifeFailReset and option > 0 then
			Mubia.setItemOption(target, 0)
			say(player, string.format("Falló (tenía %d%% de éxito). El item perdió su opción adicional.", Mubia.ItemConfig.lifeChance))
		else
			say(player, string.format("Falló (tenía %d%% de éxito).", Mubia.ItemConfig.lifeChance))
		end
		finish(player, false)
	end
	return true
end

local JEWELS = {
	[Mubia.JEWEL_OF_BLESS] = useBless,
	[Mubia.JEWEL_OF_SOUL] = useSoul,
	[Mubia.JEWEL_OF_LIFE] = useLife,
}

local jewels = Action()

function jewels.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not target or type(target) ~= "userdata" or not target:isItem() or target == item then
		say(player, 'Usá la joya sobre un arma, escudo, armadura o alas (clic derecho en la joya, "Usar con..." y clic en el item).')
		return true
	end
	if not Mubia.getItemKind(target) then
		say(player, "Las joyas solo sirven en armas, escudos, armaduras, cascos, pantalones, botas y alas.")
		return true
	end
	if JEWELS[item:getId()](player, target) then
		item:remove(1)
	end
	return true
end

for id in pairs(JEWELS) do
	jewels:id(id)
end
jewels:register()

-- Alas: solo las puede equipar su clase
local wingsClass = EventCallback("MubiaWingsClass")

function wingsClass.playerOnMoveItem(player, item, count, fromPosition, toPosition, fromCylinder, toCylinder)
	if toPosition.x == CONTAINER_POSITION and toPosition.y == CONST_SLOT_WINGS and Mubia.Wings[item:getId()] then
		if not Mubia.canUseWings(player, item) then
			local wing = Mubia.Wings[item:getId()]
			Mubia.sendMessage(player, MESSAGE_FAILURE, string.format("Solo un %s puede usar estas alas.", Mubia.Classes[wing.classId].name))
			return false
		end
		Mubia.refreshItemText(item)
	end
	return true
end

wingsClass:register()

-- Al cambiar el equipo se actualiza la ventana de stats (defensa, daño)
local equipChange = EventCallback("MubiaEquipmentStats")

function equipChange.playerOnItemMoved(player, item, count, fromPosition, toPosition, fromCylinder, toCylinder)
	if fromPosition.x == CONTAINER_POSITION and fromPosition.y < 0x40 or toPosition.x == CONTAINER_POSITION and toPosition.y < 0x40 then
		Mubia.sendStats(player)
	end
end

equipChange:register()
