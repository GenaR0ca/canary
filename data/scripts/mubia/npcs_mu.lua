-- Mubia Online: lo que hacen los NPCs de MU que no son tiendas.
--   Shadow Phantom Soldier (antes Elf Soldier): en cada salida de las ciudades, da un buff de defensa y daño por 30 minutos.
--     El cliente muestra un recuadro con el tiempo que queda (opcode 89, módulo game_mubia_buffs).
--   Messenger of Archangel y Charon: abren la ventana para elegir el Blood Castle (opcode 88) o la
--     Devil Square (opcode 90), como en MU (módulo del cliente game_mubia_bloodcastle).
-- Los archivos de cada NPC están en data-canary/npc/ (elf_soldier.lua, messenger_of_archangel.lua, charon.lua).

Mubia.BUFFS_OPCODE = 89
Mubia.BLOOD_CASTLE_MENU_OPCODE = 88
Mubia.DEVIL_SQUARE_MENU_OPCODE = 90

-- texto para el cliente: en Latin-1 (como espera OTClient) y escapado para JSON
local function jsonString(text)
	text = Mubia.toLatin1(text)
	return '"' .. text:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n") .. '"'
end

-- Elf Soldier ----------------------------------------------------------------------------------

Mubia.ElfSoldier = {
	duration = 30 * 60, -- segundos
	maxLevel = 0, -- 0 = cualquier nivel recibe el buff (en MU solo hasta nivel 180-220)
}

-- Defensa y daño según el nivel (fórmula de MU: nivel / 5 + 50 y nivel / 3 + 45)
function Mubia.ElfSoldier.values(level)
	return math.floor(level / 5) + 50, math.floor(level / 3) + 45
end

local function elfSoldierStore(player)
	return player:kv():scoped("mubia-elf-soldier")
end

-- Manda al cliente el recuadro de buffs (Shadow Phantom Soldier y bebidas: Ale, Olive of Love)
function Mubia.sendBuffs(player)
	local buffs = {}
	local store = elfSoldierStore(player)
	local left = (store:get("until") or 0) - os.time()
	if left > 0 then
		local text = string.format("+%d defensa, +%d daño", store:get("defense") or 0, store:get("damage") or 0)
		buffs[#buffs + 1] = string.format('{"id":"elfSoldier","name":"Shadow Phantom","text":%s,"seconds":%d}', jsonString(text), left)
	end
	local drink = Mubia.drinkBuffs and Mubia.drinkBuffs[player:getId()]
	if drink and drink.ends > os.time() then
		buffs[#buffs + 1] = string.format('{"id":"drink","name":%s,"text":%s,"seconds":%d}', jsonString(drink.name), jsonString(drink.text), drink.ends - os.time())
	end
	player:sendExtendedOpcode(Mubia.BUFFS_OPCODE, '{"buffs":[' .. table.concat(buffs, ",") .. "]}")
end

-- Vuelve a poner el buff que quedaba (al entrar al juego)
local function restoreElfSoldier(player)
	local store = elfSoldierStore(player)
	local left = (store:get("until") or 0) - os.time()
	if left > 0 then
		Mubia.setBuff(player, "elfSoldierDefense", store:get("defense") or 0, left * 1000)
		Mubia.setBuff(player, "elfSoldierDamage", store:get("damage") or 0, left * 1000)
	end
end

function Mubia.ElfSoldier.give(npc, player)
	local config = Mubia.ElfSoldier
	local level = player:getLevel()
	if config.maxLevel > 0 and level > config.maxLevel then
		npc:say(Mubia.toLatin1(string.format("Mi bendición es solo para aventureros de nivel %d o menos.", config.maxLevel)), TALKTYPE_PRIVATE_NP, false, player)
		return false
	end

	local defense, damage = config.values(level)
	local store = elfSoldierStore(player)
	store:set("until", os.time() + config.duration)
	store:set("defense", defense)
	store:set("damage", damage)
	restoreElfSoldier(player)
	Mubia.sendBuffs(player)

	player:getPosition():sendMagicEffect(CONST_ME_HOLYDAMAGE)
	npc:say(Mubia.toLatin1(string.format("Que la sombra del Phantom te proteja, %s.", player:getName())), TALKTYPE_PRIVATE_NP, false, player)
	Mubia.sendMessage(player, MESSAGE_STATUS, string.format("Shadow Phantom: +%d de defensa y +%d de daño por %d minutos.", defense, damage, math.floor(config.duration / 60)))
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

-- Ventanas de eventos: Messenger of Archangel (Blood Castle) y Charon (Devil Square) --------------
-- Al hablarles o hacerles clic se abre la ventana con los castillos / squares, sin el diálogo del NPC.

local function rangeLabel(prefix, entry)
	if entry.minResets then
		return string.format("%s %d (nivel %d + %d reset)", prefix, entry.level, entry.minLevel, entry.minResets)
	end
	return string.format("%s %d (nivel %d-%d)", prefix, entry.level, entry.minLevel, entry.maxLevel)
end

Mubia.EventMenus = {
	[Mubia.BLOOD_CASTLE_MENU_OPCODE] = {
		npc = "Messenger of Archangel",
		title = "Messenger of Archangel",
		message = "Tu voluntad de ayudar al Arcángel es apreciada. Pero ten cuidado, joven guerrero: Blood Castle es un lugar peligroso. Que Dios te acompañe.",
		prefix = "Castillo",
		system = function()
			local BC = Mubia.BloodCastle
			return BC, BC and BC.castles, BC and BC.getCastleForPlayer
		end,
	},
	[Mubia.DEVIL_SQUARE_MENU_OPCODE] = {
		npc = "Charon",
		title = "Devil Square",
		message = "Se te dio la oportunidad de probar tu valentía. Nadie ha entrado todavía a la Devil Square. No creas nada de lo que veas ahí dentro: solo tu valentía y tu fuerza te mantendrán con vida.",
		prefix = "Square",
		system = function()
			local DS = Mubia.DevilSquare
			return DS, DS and DS.squares, DS and DS.getSquareForPlayer
		end,
	},
}

local function nearNpc(player, name)
	local spectators = Game.getSpectators(player:getPosition(), false, false, 4, 4, 4, 4)
	for _, creature in ipairs(spectators) do
		if creature:isNpc() and creature:getName() == name then
			return true
		end
	end
	return false
end

function Mubia.openEventMenu(player, opcode)
	local menu = Mubia.EventMenus[opcode]
	local system, entries, getForPlayer = menu.system()
	if not system then
		return
	end
	local mine = getForPlayer(player)
	local parts = {}
	for _, entry in ipairs(entries) do
		local ok, reason = system.canEnter(player, entry)
		parts[#parts + 1] = string.format('{"level":%d,"label":%s,"enabled":%s,"mine":%s,"reason":%s}', entry.level, jsonString(rangeLabel(menu.prefix, entry)), ok and "true" or "false", entry == mine and "true" or "false", jsonString(reason or ""))
	end
	player:sendExtendedOpcode(opcode, string.format('{"action":"open","title":%s,"message":%s,"entries":[%s]}', jsonString(menu.title), jsonString(menu.message), table.concat(parts, ",")))
end

function Mubia.openBloodCastleMenu(player)
	Mubia.openEventMenu(player, Mubia.BLOOD_CASTLE_MENU_OPCODE)
end

function Mubia.openDevilSquareMenu(player)
	Mubia.openEventMenu(player, Mubia.DEVIL_SQUARE_MENU_OPCODE)
end

-- NPCs que con clic (opcode de la tienda, data/scripts/mubia/npc_shop.lua) abren su ventana en vez de hablar
Mubia.NpcWindows = {
	["Messenger of Archangel"] = Mubia.openBloodCastleMenu,
	["Charon"] = Mubia.openDevilSquareMenu,
}

local function enterEvent(player, opcode, buffer)
	local menu = Mubia.EventMenus[opcode]
	local system, entries = menu.system()
	local number = tonumber(buffer:match("^enter:(%d+)$"))
	local entry = number and entries and entries[number]
	if not entry then
		return
	end
	if not nearNpc(player, menu.npc) then
		Mubia.sendMessage(player, MESSAGE_FAILURE, string.format("Tienes que estar al lado de %s.", menu.npc))
		return
	end
	if system.enter(player, entry) then
		player:sendExtendedOpcode(opcode, '{"action":"close"}')
	else
		Mubia.openEventMenu(player, opcode)
	end
end

local opcodes = CreatureEvent("MubiaNpcOpcodes")

function opcodes.onExtendedOpcode(player, opcode, buffer)
	if opcode == Mubia.BUFFS_OPCODE then
		Mubia.sendBuffs(player)
	elseif Mubia.EventMenus[opcode] then
		enterEvent(player, opcode, buffer)
	end
end

opcodes:register()

local login = CreatureEvent("MubiaNpcLogin")

function login.onLogin(player)
	player:registerEvent("MubiaNpcOpcodes")
	restoreElfSoldier(player)
	-- un instante después, cuando el cliente ya cargó sus módulos
	local playerId = player:getId()
	addEvent(function()
		local p = Player(playerId)
		if p then
			Mubia.sendBuffs(p)
		end
	end, 1000)
	return true
end

login:register()
