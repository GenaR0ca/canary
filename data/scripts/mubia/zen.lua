-- Mubia Online: zen como en MU (se junta solo al matar) y sin capacidad. Reglas en data/libs/systems/mubia_zen.lua.

local zenLogin = CreatureEvent("MubiaZenLogin")

function zenLogin.onLogin(player)
	Mubia.removeCapacity(player)
	addEvent(function(playerId)
		local p = Player(playerId)
		if p then
			local converted = Mubia.convertCoins(p)
			if converted > 0 then
				Mubia.sendMessage(p, MESSAGE_LOGIN, string.format("Tus monedas de oro se convirtieron en %d zen. El zen ya no ocupa lugar en el inventario.", converted))
			end
			Mubia.sendZen(p)
		end
	end, 1000, player:getId())
	return true
end

zenLogin:register()

-- Al morir un monstruo, las monedas de su botín pasan directo como zen a quien tiene derecho al botín.
-- También se tiran los dados de los items de MU que dejó (Luck, opción y Excellent).
local zenLoot = EventCallback("MubiaZenLoot")

function zenLoot.monsterPostDropLoot(monster, corpse)
	local player = Player(corpse:getCorpseOwner())
	-- items de MU del botín: Luck, opción y Excellent al azar
	local excellent = Mubia.rollContainerOptions(corpse)
	if player then
		for _, name in ipairs(excellent) do
			Mubia.sendMessage(player, MESSAGE_LOOT, string.format("¡Cayó un item Excellent: %s!", name))
		end
		-- RHP / RMP del arma: vida y mana al matar
		Mubia.applyExcellentKill(player)
		-- Mubia Helper: recoge los items elegidos (data/libs/systems/mubia_helper.lua)
		if Mubia.helperPickup then
			Mubia.helperPickup(player, corpse)
		end
	end

	-- Mubia Helper con el zen sin marcar: las monedas quedan en el cuerpo
	if player and Mubia.helperWantsZen and not Mubia.helperWantsZen(player) then
		return
	end
	local zen = Mubia.takeCoins(corpse)
	if zen <= 0 then
		return
	end
	if player then
		-- mascotas (Pet Rudolf, Pet Unicorn) y la opción ZEN de las armaduras dan zen extra
		zen = math.floor(zen * (100 + (Mubia.getPet(player).zen or 0) + Mubia.getEquipmentBonus(player).exc.zen) / 100)
		Mubia.addZen(player, zen)
		Mubia.sendMessage(player, MESSAGE_LOOT, string.format("Obtuviste %d zen.", zen))
	end
end

zenLoot:register()
