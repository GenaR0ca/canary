-- Mubia Online: Sala del GOD. Solo un personaje GOD (con cuenta GOD) puede ir con /godzone;
-- si ya está dentro, vuelve a donde estaba. La sala (11x11) está en el mapa canary.otbm y no tiene
-- ningún teleport que lleve a ella.

Mubia.GodZone = {
	center = Position(3100, 3100, 7),
	min = Position(3095, 3095, 7),
	max = Position(3105, 3105, 7),
	fallback = Position(1943, 1345, 7), -- templo, si no hay posición guardada
	returns = {},
}

local function isInside(position)
	local zone = Mubia.GodZone
	return position.z == zone.center.z and position.x >= zone.min.x and position.x <= zone.max.x and position.y >= zone.min.y and position.y <= zone.max.y
end

local godZone = TalkAction("/godzone")

function godZone.onSay(player, words, param)
	-- groupType("god") solo mira el tipo de cuenta; aquí se exige además el grupo del personaje
	if player:getGroup():getId() < GROUP_TYPE_GOD then
		player:sendCancelMessage("Solo un GOD puede usar este comando.")
		return false
	end

	local zone = Mubia.GodZone
	local guid = player:getGuid()
	if isInside(player:getPosition()) then
		local destination = zone.returns[guid] or zone.fallback
		if not player:teleportTo(destination) then
			player:sendCancelMessage("No se pudo volver, intenta de nuevo.")
			return false
		end
		zone.returns[guid] = nil
		destination:sendMagicEffect(CONST_ME_TELEPORT)
		return true
	end

	local origin = player:getPosition()
	if not player:teleportTo(zone.center) then
		player:sendCancelMessage("No se pudo entrar a la sala, intenta de nuevo.")
		return false
	end
	zone.returns[guid] = origin
	zone.center:sendMagicEffect(CONST_ME_TELEPORT)
	return true
end

godZone:groupType("god")
godZone:register()
