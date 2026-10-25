-- Mubia Online: lo que hacen los NPCs de MU que no son tiendas.
--   Elf Soldier: en cada salida de las ciudades, da un buff de defensa y daño por 30 minutos.
--     El cliente muestra un recuadro con el tiempo que queda (opcode 89, módulo game_mubia_buffs).
--   Messenger of Archangel: abre la ventana para elegir el Blood Castle (opcode 88, módulo game_mubia_bloodcastle).
-- Los archivos de cada NPC están en data-canary/npc/ (elf_soldier.lua, messenger_of_archangel.lua).

Mubia.BUFFS_OPCODE = 89
Mubia.BLOOD_CASTLE_MENU_OPCODE = 88

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

-- Manda al cliente el recuadro de buffs (por ahora solo el del Elf Soldier)
function Mubia.sendBuffs(player)
	local buffs = {}
	local store = elfSoldierStore(player)
	local left = (store:get("until") or 0) - os.time()
	if left > 0 then
		local text = string.format("+%d defensa, +%d daño", store:get("defense") or 0, store:get("damage") or 0)
		buffs[#buffs + 1] = string.format('{"id":"elfSoldier","name":"Elf Soldier","text":%s,"seconds":%d}', jsonString(text), left)
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
	npc:say(Mubia.toLatin1(string.format("Que la bendición de las elfas te proteja, %s.", player:getName())), TALKTYPE_PRIVATE_NP, false, player)
	Mubia.sendMessage(player, MESSAGE_STATUS, string.format("Elf Soldier: +%d de defensa y +%d de daño por %d minutos.", defense, damage, math.floor(config.duration / 60)))
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

-- Messenger of Archangel: ventana de castillos --------------------------------------------------

local function castleLabel(castle)
	if castle.minResets then
		return string.format("Castillo %d (nivel %d + %d reset)", castle.level, castle.minLevel, castle.minResets)
	end
	return string.format("Castillo %d (nivel %d-%d)", castle.level, castle.minLevel, castle.maxLevel)
end

local function nearMessenger(player)
	local spectators = Game.getSpectators(player:getPosition(), false, false, 4, 4, 4, 4)
	for _, creature in ipairs(spectators) do
		if creature:isNpc() and creature:getName() == "Messenger of Archangel" then
			return true
		end
	end
	return false
end

function Mubia.openBloodCastleMenu(player)
	local BC = Mubia.BloodCastle
	if not BC then
		return
	end
	local mine = BC.getCastleForPlayer(player)
	local parts = {}
	for _, castle in ipairs(BC.castles) do
		local ok, reason = BC.canEnter(player, castle)
		parts[#parts + 1] = string.format('{"level":%d,"label":%s,"enabled":%s,"mine":%s,"reason":%s}', castle.level, jsonString(castleLabel(castle)), ok and "true" or "false", castle == mine and "true" or "false", jsonString(reason or ""))
	end
	player:sendExtendedOpcode(Mubia.BLOOD_CASTLE_MENU_OPCODE, '{"action":"open","castles":[' .. table.concat(parts, ",") .. "]}")
end

local opcodes = CreatureEvent("MubiaNpcOpcodes")

function opcodes.onExtendedOpcode(player, opcode, buffer)
	if opcode == Mubia.BUFFS_OPCODE then
		Mubia.sendBuffs(player)
	elseif opcode == Mubia.BLOOD_CASTLE_MENU_OPCODE then
		local number = tonumber(buffer:match("^enter:(%d+)$"))
		local BC = Mubia.BloodCastle
		local castle = number and BC and BC.castles[number]
		if not castle then
			return
		end
		if not nearMessenger(player) then
			Mubia.sendMessage(player, MESSAGE_FAILURE, "Tienes que estar al lado del Messenger of Archangel.")
			return
		end
		if BC.enter(player, castle) then
			player:sendExtendedOpcode(Mubia.BLOOD_CASTLE_MENU_OPCODE, '{"action":"close"}')
		else
			Mubia.openBloodCastleMenu(player)
		end
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
