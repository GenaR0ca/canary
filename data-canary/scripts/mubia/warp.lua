-- Mubia Online: menú de ciudades (como la tecla M de MU). El cliente pide la lista con "list"
-- y viaja con "go:<número>". Va en data-canary porque usa posiciones del mapa canary.otbm.

Mubia.Warp = {
	opcode = 81,
	-- name, position (donde aparece el jugador), level (nivel mínimo), zen (precio)
	destinations = {
		{ name = "Templo", position = Position(1943, 1345, 7), level = 0, zen = 0 },
		{ name = "Lorencia", position = Position(924, 660, 7), level = 0, zen = 0 },
		{ name = "Noria", position = Position(1288, 648, 7), level = 0, zen = 0 },
		{ name = "Devias", position = Position(1587, 739, 7), level = 0, zen = 0 },
		{ name = "Devias 2", position = Position(1587, 557, 7), level = 0, zen = 0 },
		{ name = "Devias 3", position = Position(1776, 746, 7), level = 0, zen = 0 },
		{ name = "Devias 4", position = Position(1735, 594, 7), level = 0, zen = 0 },
		{ name = "Zona de NPCs", position = Position(4804, 5088, 7), level = 0, zen = 0 },
		{ name = "Zona de entrenamiento", position = Position(5008, 5004, 7), level = 0, zen = 0 },
	},
}

local function sendList(player)
	local parts = {}
	for index, dest in ipairs(Mubia.Warp.destinations) do
		parts[#parts + 1] = string.format('{"id":%d,"name":"%s","level":%d,"zen":%d}', index, Mubia.toLatin1(dest.name), dest.level, dest.zen)
	end
	player:sendExtendedOpcode(Mubia.Warp.opcode, '{"action":"list","destinations":[' .. table.concat(parts, ",") .. "]}")
end

local function warp(player, index)
	local dest = Mubia.Warp.destinations[index]
	if not dest then
		return
	end
	if player:isPzLocked() then
		Mubia.sendMessage(player, MESSAGE_FAILURE, "No puedes viajar mientras estás en combate.")
		return
	end
	if player:getLevel() < dest.level then
		Mubia.sendMessage(player, MESSAGE_FAILURE, string.format("Necesitas nivel %d para viajar a %s.", dest.level, dest.name))
		return
	end
	if dest.zen > 0 and not player:removeMoneyBank(dest.zen) then
		Mubia.sendMessage(player, MESSAGE_FAILURE, string.format("Necesitas %d de zen para viajar a %s.", dest.zen, dest.name))
		return
	end

	player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
	player:teleportTo(dest.position)
	dest.position:sendMagicEffect(CONST_ME_TELEPORT)
	Mubia.sendMessage(player, MESSAGE_EVENT_ADVANCE, string.format("Viajaste a %s.", dest.name))
end

local warpOpcode = CreatureEvent("MubiaWarp")

function warpOpcode.onExtendedOpcode(player, opcode, buffer)
	if opcode ~= Mubia.Warp.opcode then
		return
	end

	if buffer == "list" then
		sendList(player)
		return
	end

	local index = tonumber(buffer:match("^go:(%d+)$"))
	if index then
		warp(player, index)
	end
end

warpOpcode:register()

local warpLogin = CreatureEvent("MubiaWarpLogin")

function warpLogin.onLogin(player)
	player:registerEvent("MubiaWarp")
	return true
end

warpLogin:register()
