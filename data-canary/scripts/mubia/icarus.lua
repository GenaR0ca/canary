-- Mubia Online: Icarus. Como en MU, solo se entra con alas equipadas (slot de alas).
-- La entrada es el portal de Lost Tower 7; el menú M también pide alas (ver warp.lua).
-- Si alguien se saca las alas estando en Icarus, cae a Lost Tower 7.
-- Va en data-canary porque usa posiciones del mapa canary.otbm.

CONST_SLOT_WINGS = CONST_SLOT_WINGS or 12

Mubia.Icarus = {
	spawn = Position(2223, 1254, 7), -- la flecha verde del mapa (centro de la zona segura)
	portal = Position(1033, 1665, 8), -- portal de Lost Tower 7
	lostTower = Position(1032, 1665, 8), -- donde se queda el jugador en Lost Tower 7
	from = Position(2100, 1100, 7),
	to = Position(2384, 1404, 7),
}

function Mubia.hasWings(player)
	return player:getSlotItem(CONST_SLOT_WINGS) ~= nil
end

function Mubia.isInIcarus(position)
	return position:isInRange(Mubia.Icarus.from, Mubia.Icarus.to)
end

local portal = MoveEvent()

function portal.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return true
	end
	if not Mubia.hasWings(player) then
		player:teleportTo(Mubia.Icarus.lostTower, true)
		Mubia.Icarus.lostTower:sendMagicEffect(CONST_ME_POFF)
		Mubia.sendMessage(player, MESSAGE_FAILURE, "Necesitas tener alas equipadas para entrar a Icarus.")
		return true
	end
	position:sendMagicEffect(CONST_ME_TELEPORT)
	player:teleportTo(Mubia.Icarus.spawn)
	Mubia.Icarus.spawn:sendMagicEffect(CONST_ME_TELEPORT)
	Mubia.sendMessage(player, MESSAGE_EVENT_ADVANCE, "Bienvenido a Icarus.")
	return true
end

portal:type("stepin")
portal:position(Mubia.Icarus.portal)
portal:register()

-- sin alas no se puede estar en Icarus: se cae a Lost Tower 7
local fall = GlobalEvent("MubiaIcarusWings")

function fall.onThink(interval)
	for _, player in ipairs(Game.getPlayers()) do
		if Mubia.isInIcarus(player:getPosition()) and not Mubia.hasWings(player) then
			player:getPosition():sendMagicEffect(CONST_ME_POFF)
			player:teleportTo(Mubia.Icarus.lostTower)
			Mubia.Icarus.lostTower:sendMagicEffect(CONST_ME_TELEPORT)
			Mubia.sendMessage(player, MESSAGE_FAILURE, "Sin alas no puedes volar en Icarus: caíste a Lost Tower 7.")
		end
	end
	return true
end

fall:interval(3000)
fall:register()
