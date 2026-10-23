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

-- Al morir un monstruo, las monedas de su botín pasan directo como zen a quien tiene derecho al botín
local zenLoot = EventCallback("MubiaZenLoot")

function zenLoot.monsterPostDropLoot(monster, corpse)
	local zen = Mubia.takeCoins(corpse)
	if zen <= 0 then
		return
	end
	local player = Player(corpse:getCorpseOwner())
	if player then
		-- mascotas que dan zen extra (Pet Rudolf, Pet Unicorn)
		zen = math.floor(zen * (100 + (Mubia.getPet(player).zen or 0)) / 100)
		Mubia.addZen(player, zen)
		Mubia.sendMessage(player, MESSAGE_LOOT, string.format("Obtuviste %d zen.", zen))
	end
end

zenLoot:register()
