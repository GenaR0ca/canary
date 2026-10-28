-- Mubia Online: click derecho en un NPC abre su tienda directamente, como en MU (opcode 85).
-- El cliente manda "open|<id del NPC>". Si el NPC no vende nada, el cliente le dice "hi" como siempre.
-- Vender: el cliente manda "sell|<id del NPC>|<casilla de la bolsa>|<id del item>|<cantidad>|<1 si aceptó el aviso>".
-- Todo NPC con tienda compra cualquier item (data/libs/systems/mubia_shops.lua).

Mubia.NPC_SHOP_OPCODE = 85

local npcShop = CreatureEvent("MubiaNpcShop")

function npcShop.onExtendedOpcode(player, opcode, buffer)
	if opcode ~= Mubia.NPC_SHOP_OPCODE then
		return
	end

	local sellNpc, slot, itemId, count, confirmed = buffer:match("^sell|(%d+)|(%d+)|(%d+)|(%d+)|(%d)$")
	if sellNpc then
		local npc = Npc(tonumber(sellNpc))
		if not npc or not npc:isMerchant() then
			return
		end
		if not npc:isInTalkRange(player:getPosition()) then
			Mubia.sendMessage(player, MESSAGE_FAILURE, "Acércate más al NPC.")
			return
		end
		Mubia.sellFromBag(player, tonumber(slot), tonumber(itemId), tonumber(count), confirmed == "1")
		return
	end

	local npcId = tonumber(buffer:match("^open|(%d+)$"))
	local npc = npcId and Npc(npcId)
	if not npc then
		return
	end

	if not npc:isInTalkRange(player:getPosition()) then
		Mubia.sendMessage(player, MESSAGE_FAILURE, "Acércate más al NPC.")
		return
	end

	-- Messenger of Archangel, Charon...: abren su ventana (data/scripts/mubia/npcs_mu.lua), sin el diálogo
	local openWindow = Mubia.NpcWindows and Mubia.NpcWindows[npc:getName()]
	if openWindow then
		npc:turnToCreature(player)
		openWindow(player)
		return
	end

	if not npc:isMerchant() then
		player:sendExtendedOpcode(Mubia.NPC_SHOP_OPCODE, string.format('{"talk":%d}', npc:getId()))
		return
	end

	-- Igual que si le hubiera dicho "hi": si te alejás, la tienda se cierra sola
	if not npc:isInteractingWithPlayer(player) then
		npc:setPlayerInteraction(player, 0)
	end
	npc:turnToCreature(player)
	npc:openShopWindow(player)
	Mubia.sendSellList(player)
end

npcShop:register()

local npcShopLogin = CreatureEvent("MubiaNpcShopLogin")

function npcShopLogin.onLogin(player)
	player:registerEvent("MubiaNpcShop")
	return true
end

npcShopLogin:register()
