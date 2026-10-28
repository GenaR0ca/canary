-- Mubia Online: menú de ciudades (como la tecla M de MU). El cliente pide la lista con "list"
-- y viaja con "go:<número>". Va en data-canary porque usa posiciones del mapa canary.otbm.

Mubia.Warp = {
	opcode = 81,
	-- name, position (donde aparece el jugador), level (nivel mínimo), zen (precio), wings (pide alas equipadas)
	destinations = {
		{ name = "Templo", position = Position(1943, 1345, 7), level = 0, zen = 0 },
		{ name = "Lorencia", position = Position(927, 654, 7), level = 0, zen = 0 },
		{ name = "Noria", position = Position(1257, 720, 7), level = 0, zen = 0 },
		{ name = "Devias", position = Position(1587, 739, 7), level = 0, zen = 0 },
		{ name = "Devias 2", position = Position(1587, 557, 7), level = 0, zen = 0 },
		{ name = "Devias 3", position = Position(1776, 746, 7), level = 0, zen = 0 },
		{ name = "Devias 4", position = Position(1735, 594, 7), level = 0, zen = 0 },
		{ name = "Arena", position = Position(1958, 616, 7), level = 0, zen = 0 },
		{ name = "Dungeon", position = Position(947, 629, 8), level = 0, zen = 0 },
		{ name = "Dungeon 2", position = Position(850, 764, 9), level = 0, zen = 0 },
		{ name = "Dungeon 3", position = Position(742, 537, 10), level = 0, zen = 0 },
		{ name = "Atlans", position = Position(1317, 1062, 7), level = 0, zen = 0 },
		{ name = "Atlans 2", position = Position(1352, 1272, 7), level = 0, zen = 0 },
		{ name = "Atlans 3", position = Position(1462, 1107, 7), level = 0, zen = 0 },
		{ name = "Lost Tower", position = Position(974, 1701, 14), level = 0, zen = 0 },
		{ name = "Lost Tower 2", position = Position(907, 1692, 13), level = 0, zen = 0 },
		{ name = "Lost Tower 3", position = Position(837, 1619, 12), level = 0, zen = 0 },
		{ name = "Lost Tower 4", position = Position(907, 1660, 11), level = 0, zen = 0 },
		{ name = "Lost Tower 5", position = Position(944, 1700, 10), level = 0, zen = 0 },
		{ name = "Lost Tower 6", position = Position(911, 1700, 9), level = 0, zen = 0 },
		{ name = "Lost Tower 7", position = Position(873, 1653, 8), level = 0, zen = 0 },
		{ name = "Tarkan", position = Position(1634, 1205, 7), level = 0, zen = 0 },
		{ name = "Tarkan 2", position = Position(1734, 1099, 7), level = 0, zen = 0 },
		{ name = "Aida", position = Position(1310, 1406, 7), level = 0, zen = 0 },
		{ name = "Aida 2", position = Position(1477, 1509, 7), level = 0, zen = 0 },
		{ name = "Icarus", position = Position(2223, 1254, 7), level = 0, zen = 0, wings = true },
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
	if dest.wings and Mubia.hasWings and not Mubia.hasWings(player) then
		Mubia.sendMessage(player, MESSAGE_FAILURE, string.format("Necesitas tener alas equipadas para viajar a %s.", dest.name))
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
