-- Mubia Online: Jewels de MU (Bless, Soul, Life, Harmony, Luck, Excellent) y alas. Las reglas están en data/libs/systems/mubia_items.lua.

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
	if level >= Mubia.ItemConfig.soulMaxLevel then
		say(player, string.format("Jewel of Soul sube items hasta +%d. De +%d a +15 se sube en la Chaos Machine del Chaos Goblin.", Mubia.ItemConfig.soulMaxLevel, Mubia.ItemConfig.soulMaxLevel + 1))
		return false
	end
	local chance = Mubia.ItemConfig.soulChance[level + 1] or 0
	if Mubia.hasLuck(target) then
		chance = math.min(100, chance + Mubia.ExcellentConfig.luckSuccessRate) -- Luck: +25%
	end
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

-- Jewel of Harmony, Luck y Excellent: las reglas están en mubia_harmony.lua
local function useWith(rule)
	return function(player, target)
		local used, message = rule(target)
		say(player, message)
		if used then
			finish(player, not message:find("^Falló"))
			Mubia.recalc(player)
		end
		return used
	end
end

local JEWELS = {
	[Mubia.JEWEL_OF_BLESS] = useBless,
	[Mubia.JEWEL_OF_SOUL] = useSoul,
	[Mubia.JEWEL_OF_LIFE] = useLife,
	[Mubia.JEWEL_OF_HARMONY] = useWith(Mubia.useHarmony),
	[Mubia.JEWEL_OF_LUCK] = useWith(Mubia.useLuckJewel),
	[Mubia.JEWEL_OF_EXCELLENT] = useWith(Mubia.useExcellentJewel),
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

-- Sets, armas, escudos, alas y mascotas de MU: al equiparse se revisa la clase, STR, AGI y nivel.
-- (Los sets y armas de Tibia ya no se pueden equipar: lo bloquea canary.exe)
local function onGearEquip(player, item, slot, isCheck)
	if not isCheck then
		return true
	end
	local ok, reason = Mubia.checkEquipRequirements(player, item)
	if not ok then
		Mubia.sendMessage(player, MESSAGE_FAILURE, reason)
	end
	return ok
end

local PIECE_SLOTS = { helm = "head", armor = "armor", pants = "legs", gloves = "gloves", boots = "feet" }
local idsBySlot = { wings = {}, pet = {} }
for itemId in pairs(Mubia.Wings) do
	table.insert(idsBySlot.wings, itemId)
end
for itemId, pet in pairs(Mubia.Pets) do
	if pet.level then
		table.insert(idsBySlot.pet, itemId)
	end
end
for itemId, gear in pairs(Mubia.Gear) do
	local slot = gear.kind == "armor" and PIECE_SLOTS[gear.piece] or "hand"
	idsBySlot[slot] = idsBySlot[slot] or {}
	table.insert(idsBySlot[slot], itemId)
end

for slot, ids in pairs(idsBySlot) do
	local equip = MoveEvent()
	equip.onEquip = onGearEquip
	equip:type("equip")
	equip:slot(slot)
	equip:id(unpack(ids))
	equip:register()
end

-- Al cambiar el equipo se actualiza la ventana de stats (defensa, daño)
local equipChange = EventCallback("MubiaEquipmentStats")

function equipChange.playerOnItemMoved(player, item, count, fromPosition, toPosition, fromCylinder, toCylinder)
	if fromPosition.x == CONTAINER_POSITION and fromPosition.y < 0x40 or toPosition.x == CONTAINER_POSITION and toPosition.y < 0x40 then
		Mubia.recalc(player) -- vida, mana y velocidad (opciones Excellent)
		Mubia.sendStats(player)
	end
end

equipChange:register()
