-- Mubia Online: misión de la segunda evolución con Sebina the Priest. Reglas en data/libs/systems/mubia_sebina.lua.
-- Clic en Sebina abre su ventana (opcode 91, módulo del cliente game_mubia_sebina).
-- El cliente manda "accept" (aceptar la misión) o "deliver" (entregar el item).

local S = Mubia.Sebina

Mubia.NpcWindows = Mubia.NpcWindows or {}
Mubia.NpcWindows[S.npcName] = S.openWindow

local function nearSebina(player)
	for _, spectator in ipairs(Game.getSpectators(player:getPosition(), false, false, 4, 4, 4, 4)) do
		if spectator:isNpc() and spectator:getName() == S.npcName then
			return true
		end
	end
	return false
end

local opcodes = CreatureEvent("MubiaSebinaOpcode")

function opcodes.onExtendedOpcode(player, opcode, buffer)
	if opcode ~= Mubia.SEBINA_OPCODE then
		return
	end
	if buffer ~= "accept" and buffer ~= "deliver" then
		return
	end
	if not nearSebina(player) then
		Mubia.sendMessage(player, MESSAGE_FAILURE, "Acércate más a Sebina.")
		player:sendExtendedOpcode(Mubia.SEBINA_OPCODE, '{"action":"close"}')
		return
	end
	S.onAction(player, buffer)
end

opcodes:register()

local login = CreatureEvent("MubiaSebinaLogin")

function login.onLogin(player)
	player:registerEvent("MubiaSebinaOpcode")
	-- si Canary le sacó la evolución (sin premium), se la devuelve
	if (player:kv():scoped("mubia-sebina"):get("step") or 0) >= S.STEP_DONE and not Mubia.isEvolved(player) then
		local promotion = player:getVocation():getPromotion()
		if promotion then
			player:setVocation(promotion)
		end
	end
	return true
end

login:register()

-- Los items de la misión caen solo a quien la está haciendo
local drop = EventCallback("MubiaSebinaDrop")

function drop.monsterPostDropLoot(monster, corpse)
	S.rollDrop(monster, corpse)
end

drop:register()

-- No se pueden tirar al piso ni intercambiar
local move = EventCallback("MubiaSebinaMove")

function move.playerOnMoveItem(player, item, count, fromPosition, toPosition, fromCylinder, toCylinder)
	if Mubia.isQuestItem(item:getId()) and toPosition.x ~= CONTAINER_POSITION then
		Mubia.sendMessage(player, MESSAGE_FAILURE, "Este item es de la misión de Sebina: no se puede tirar.")
		return false
	end
	return true
end

move:register()

local trade = EventCallback("MubiaSebinaTrade")

function trade.playerOnTradeRequest(player, target, item)
	if Mubia.isQuestItem(item:getId()) then
		Mubia.sendMessage(player, MESSAGE_FAILURE, "Este item es de la misión de Sebina: no se puede intercambiar.")
		return false
	end
	return true
end

trade:register()

-- GOD: /sebina da el item que te pide Sebina ahora (para probar sin cazar). "/sebina reset" vuelve a empezar la misión
-- y te devuelve a la clase base.
local godCommand = TalkAction("/sebina")

function godCommand.onSay(player, words, param)
	if param == "reset" then
		player:kv():scoped("mubia-sebina"):set("step", S.STEP_NONE)
		player:kv():set("promoted", false)
		local vocation = player:getVocation()
		if vocation:getId() ~= vocation:getBaseId() then
			player:setVocation(vocation:getDemotion())
		end
		Mubia.recalc(player)
		Mubia.sendStats(player)
		Mubia.sendMessage(player, MESSAGE_EVENT_ADVANCE, "Misión de Sebina reiniciada.")
		return true
	end
	local wanted = S.getWantedItem(player)
	if not wanted then
		Mubia.sendMessage(player, MESSAGE_FAILURE, "Primero acepta la misión de Sebina (o usa /sebina reset).")
		return true
	end
	local bag = player:getSlotItem(CONST_SLOT_BACKPACK)
	local item = bag and bag:isContainer() and bag:addItem(wanted, 1) or player:addItem(wanted, 1)
	Mubia.sendMessage(player, item and MESSAGE_EVENT_ADVANCE or MESSAGE_FAILURE, item and ("Te di " .. ItemType(wanted):getName() .. ".") or "No tienes lugar en el inventario.")
	return true
end

godCommand:separator(" ")
godCommand:groupType("god")
godCommand:register()
