-- Mubia Online: zen como en MU. No es una moneda que se lleva en el inventario: es un número
-- (se guarda como saldo del banco) que se junta solo al matar monstruos. Las tiendas de los NPC
-- cobran de ahí. El cliente lo muestra en el recuadro de zen (opcode 82).
-- También: sin capacidad (Cap), cada personaje puede llevar lo que quiera.

Mubia.ZEN_OPCODE = 82
Mubia.NO_CAPACITY = 1000000000 -- 10.000.000 oz, nunca se llena

-- Monedas de Tibia y cuánto zen vale cada una
Mubia.ZenCoins = {
	[3031] = 1, -- gold coin
	[3035] = 100, -- platinum coin
	[3043] = 10000, -- crystal coin
}

function Mubia.getZen(player)
	return player:getBankBalance()
end

function Mubia.sendZen(player)
	if player:isUsingOtClient() then
		player:sendExtendedOpcode(Mubia.ZEN_OPCODE, string.format('{"zen":%d}', Mubia.getZen(player)))
	end
end

function Mubia.addZen(player, amount)
	if amount <= 0 then
		return
	end
	player:setBankBalance(player:getBankBalance() + amount)
	Mubia.sendZen(player)
end

-- Saca las monedas de un contenedor (y de los que tenga adentro) y devuelve cuánto zen valían
function Mubia.takeCoins(container)
	local zen = 0
	for i = container:getSize() - 1, 0, -1 do
		local item = container:getItem(i)
		if item then
			local value = Mubia.ZenCoins[item:getId()]
			if value then
				zen = zen + value * item:getCount()
				item:remove()
			elseif item:isContainer() then
				zen = zen + Mubia.takeCoins(item)
			end
		end
	end
	return zen
end

-- Monedas que haya en el inventario o el equipo: pasan a ser zen
function Mubia.convertCoins(player)
	local zen = 0
	for slot = CONST_SLOT_FIRST, CONST_SLOT_AMMO do
		local item = player:getSlotItem(slot)
		if item then
			local value = Mubia.ZenCoins[item:getId()]
			if value then
				zen = zen + value * item:getCount()
				item:remove()
			elseif item:isContainer() then
				zen = zen + Mubia.takeCoins(item)
			end
		end
	end
	Mubia.addZen(player, zen)
	return zen
end

function Mubia.removeCapacity(player)
	if player:getCapacity() < Mubia.NO_CAPACITY then
		player:setCapacity(Mubia.NO_CAPACITY)
	end
end

-- Cada vez que se cobra zen (reset, viajes, etc.) se actualiza el recuadro del cliente
local removeMoneyBank = Player.removeMoneyBank
function Player.removeMoneyBank(self, amount)
	local ok = removeMoneyBank(self, amount)
	if ok then
		Mubia.sendZen(self)
	end
	return ok
end
