-- Mubia Online: Devil Square (evento de MU). Se entra hablando con Charon; durante 5 minutos aparecen
-- oleadas de monstruos cada vez más fuertes y al final se reparte zen, joyas y experiencia según los puntos.
-- Mapa: 7 arenas en x2310-2547 y600-627 (tools/mubia/mapas/devil_square.py). Scripts: data/scripts/mubia/devil_square.lua.
-- Items: Devil's Eye +1..+7 (60601-60607), Devil's Key (60611-60617), Devil's Invitation (60621-60627).

Mubia.DevilSquare = {
	-- mientras probamos, Charon deja entrar siempre: sin invitación y a cualquier Devil Square
	requireInvitation = false,
	checkLevel = false,

	duration = 5 * 60, -- segundos de monstruos
	prepare = 10, -- segundos de espera antes de que salgan los monstruos
	bossAt = 4 * 60, -- en el último minuto salen los jefes
	maxPlayers = 20,
	aliveBase = 15, -- monstruos vivos a la vez: base + por jugador (hasta aliveMax)
	alivePerPlayer = 5,
	aliveMax = 50,
	spawnPerTick = 6, -- cuántos aparecen por segundo como máximo
	bossPoints = 20, -- puntos por matar a un jefe (los demás dan 1)
	bonusExpPercent = 50, -- al terminar: % extra de la experiencia que ganaste adentro
	dropChance = 1000, -- de 100000 (1%): Devil's Eye o Devil's Key en los monstruos de afuera

	EYE = 60601,
	KEY = 60611,
	INVITATION = 60621,
	JEWELS = { 60303, 60301, 60302, 60304, 60305 }, -- Bless, Soul, Life, Chaos, Creation

	-- monsters: de más débil a más fuerte (cada oleada usa los más fuertes que ya se habilitaron)
	-- zen = { 1er puesto, 10mo puesto }; jewels = { 1er puesto, 2do y 3er puesto }
	squares = {
		{ minLevel = 15, maxLevel = 130, monsters = { "Larva", "Ghost", "Skeleton Archer", "Hell Hound" }, bosses = { "Ice Queen" }, zen = { 10000000, 1000000 }, jewels = { 3, 1 } },
		{ minLevel = 131, maxLevel = 180, monsters = { "Hell Spider", "Elite Skeleton", "Thunder Lich", "Poison Bull" }, bosses = { "Gorgon" }, zen = { 11000000, 2000000 }, jewels = { 3, 1 } },
		{ minLevel = 181, maxLevel = 230, monsters = { "Shadow", "Dark Knight", "Poison Shadow", "Cursed Wizard" }, bosses = { "Death Gorgon" }, zen = { 12000000, 3000000 }, jewels = { 3, 1 } },
		{ minLevel = 231, maxLevel = 280, monsters = { "Death Cow", "Devil", "Death Knight", "Death Gorgon" }, bosses = { "Balrog" }, zen = { 13000000, 4000000 }, jewels = { 5, 2 } },
		{ minLevel = 281, maxLevel = 330, monsters = { "Ogre Archer", "Elite Ogre", "Metal Balrog" }, bosses = { "Cursed King" }, zen = { 14000000, 5000000 }, jewels = { 5, 2 } },
		{ minLevel = 331, maxLevel = 400, monsters = { "Bloody Wolf", "Iron Wheel", "Tantallos", "Beam Knight" }, bosses = { "Death Beam Knight" }, zen = { 15000000, 6000000 }, jewels = { 5, 2 } },
		{ minLevel = 400, maxLevel = 400, minResets = 1, monsters = { "Gigantis", "Berserker", "Balram (Trainee)", "Soram (Trainee)", "Persona" }, bosses = { "Dreadfear", "Dark Elf" }, zen = { 16000000, 7000000 }, jewels = { 5, 2 } },
	},
}

local DS = Mubia.DevilSquare

-- posiciones de cada arena (las mismas que arma tools/mubia/mapas/devil_square.py)
for level, square in ipairs(DS.squares) do
	local x0 = 2310 + (level - 1) * 34
	square.level = level
	square.center = Position(x0 + 14, 614, 7)
	square.fromPos = Position(x0 + 1, 601, 7)
	square.toPos = Position(x0 + 26, 626, 7)
	square.state = { status = "idle", players = {}, scores = {}, monsters = {} }
end

function DS.getSquareAt(position)
	for _, square in ipairs(DS.squares) do
		if position:isInRange(square.fromPos, square.toPos) then
			return square
		end
	end
	return nil
end

local function getResets(player)
	return Mubia.getStats and Mubia.getStats(player).resets or 0
end

-- la Devil Square que le toca al personaje por nivel y resets
function DS.getSquareForPlayer(player)
	local level, resets = player:getLevel(), getResets(player)
	for i = #DS.squares, 1, -1 do
		local square = DS.squares[i]
		if resets >= (square.minResets or 0) and level >= square.minLevel then
			return square
		end
	end
	return nil
end

local function squareLabel(square)
	if square.minResets then
		return string.format("Devil Square +%d (nivel %d con %d reset o más)", square.level, square.minLevel, square.minResets)
	end
	return string.format("Devil Square +%d (nivel %d a %d)", square.level, square.minLevel, square.maxLevel)
end

local function broadcast(square, messageType, text)
	for playerId in pairs(square.state.players) do
		local player = Player(playerId)
		if player then
			Mubia.sendMessage(player, messageType, text)
		end
	end
end

local function countPlayers(square)
	local count = 0
	for _ in pairs(square.state.players) do
		count = count + 1
	end
	return count
end

-- revisa si puede entrar; devuelve true o false y el motivo
function DS.canEnter(player, square)
	local state = square.state
	if state.players[player:getId()] then
		return false, "Ya estás adentro."
	end
	if state.status == "ending" then
		return false, string.format("La Devil Square +%d está terminando. Espera unos segundos.", square.level)
	end
	if countPlayers(square) >= DS.maxPlayers then
		return false, string.format("La Devil Square +%d está llena (%d jugadores).", square.level, DS.maxPlayers)
	end
	if DS.checkLevel then
		local level, resets = player:getLevel(), getResets(player)
		if level < square.minLevel or level > square.maxLevel and not square.minResets or resets < (square.minResets or 0) then
			return false, "No tienes el nivel para esa Devil Square. Te corresponde: " .. squareLabel(DS.getSquareForPlayer(player) or DS.squares[1])
		end
	end
	if DS.requireInvitation and player:getItemCount(DS.INVITATION + square.level - 1) < 1 then
		return false, string.format("Necesitas una Devil's Invitation +%d.", square.level)
	end
	return true
end

function DS.enter(player, square)
	local ok, reason = DS.canEnter(player, square)
	if not ok then
		Mubia.sendMessage(player, MESSAGE_FAILURE, reason)
		return false
	end

	-- la invitación se gasta solo si es obligatoria
	if DS.requireInvitation then
		player:removeItem(DS.INVITATION + square.level - 1, 1)
	end

	local state = square.state
	local playerId = player:getId()
	state.players[playerId] = true
	state.scores[playerId] = state.scores[playerId] or { name = player:getName(), points = 0, kills = 0, exp = 0 }
	player:kv():scoped("mubia-devil-square"):set("exit", { x = player:getPosition().x, y = player:getPosition().y, z = player:getPosition().z })

	player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
	player:teleportTo(square.center)
	square.center:sendMagicEffect(CONST_ME_MORTAREA)

	if state.status == "idle" then
		state.status = "waiting"
		state.startAt = os.time() + DS.prepare
		state.endAt = state.startAt + DS.duration
		state.bossDone = false
		state.lastMinute = nil
		Mubia.sendMessage(player, MESSAGE_EVENT_ADVANCE, string.format("Entraste a la Devil Square +%d. ¡Los monstruos salen en %d segundos!", square.level, DS.prepare))
	elseif state.status == "waiting" then
		Mubia.sendMessage(player, MESSAGE_EVENT_ADVANCE, string.format("Entraste a la Devil Square +%d. ¡Los monstruos salen en %d segundos!", square.level, math.max(0, state.startAt - os.time())))
	else
		Mubia.sendMessage(player, MESSAGE_EVENT_ADVANCE, string.format("Entraste a la Devil Square +%d. ¡Ya empezó! Quedan %d segundos.", square.level, math.max(0, state.endAt - os.time())))
	end
	return true
end

-- adonde vuelve el jugador al salir: donde habló con Charon (o el templo de su ciudad)
function DS.getExitPosition(player)
	local exit = player:kv():scoped("mubia-devil-square"):get("exit")
	if type(exit) == "table" and exit.x then
		local position = Position(exit.x, exit.y, exit.z)
		if not DS.getSquareAt(position) and Tile(position) then
			return position
		end
	end
	return player:getTown():getTemplePosition()
end

function DS.sendOut(player)
	player:teleportTo(DS.getExitPosition(player))
	player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
	player:kv():scoped("mubia-devil-square"):remove("exit")
end

local function isFreeTile(position)
	local tile = Tile(position)
	if not tile or not tile:getGround() then
		return false
	end
	if tile:hasFlag(TILESTATE_BLOCKSOLID) or tile:hasFlag(TILESTATE_PROTECTIONZONE) then
		return false
	end
	return tile:getCreatureCount() == 0
end

local function randomFreePosition(square)
	for _ = 1, 30 do
		local position = Position(math.random(square.fromPos.x, square.toPos.x), math.random(square.fromPos.y, square.toPos.y), square.fromPos.z)
		-- que no aparezcan pegados al centro (donde llegan los jugadores)
		if position:getDistance(square.center) > 2 and isFreeTile(position) then
			return position
		end
	end
	return nil
end

local function spawnMonster(square, name, boss)
	local position = randomFreePosition(square)
	if not position then
		return nil
	end
	local monster = Game.createMonster(name, position, false, false)
	if not monster then
		return nil
	end
	monster:registerEvent("MubiaDevilSquareDeath")
	square.state.monsters[monster:getId()] = boss and "boss" or "normal"
	position:sendMagicEffect(boss and CONST_ME_MORTAREA or CONST_ME_TELEPORT)
	return monster
end

local function countMonsters(square)
	local count = 0
	for monsterId in pairs(square.state.monsters) do
		if Monster(monsterId) then
			count = count + 1
		else
			square.state.monsters[monsterId] = nil
		end
	end
	return count
end

-- oleada 1, 2 o 3 según el tiempo que pasó; cada una suma monstruos más fuertes
local function wavePool(square, elapsed)
	local wave = math.min(3, math.floor(elapsed * 3 / DS.duration) + 1)
	local list = square.monsters
	local last = math.max(2, math.ceil(#list * wave / 3))
	local first = math.max(1, last - 2)
	local pool = {}
	for i = first, math.min(last, #list) do
		pool[#pool + 1] = list[i]
	end
	return pool, wave
end

local function removeMonsters(square)
	for monsterId in pairs(square.state.monsters) do
		local monster = Monster(monsterId)
		if monster then
			monster:getPosition():sendMagicEffect(CONST_ME_POFF)
			monster:remove()
		end
	end
	square.state.monsters = {}
end

local function resetSquare(square)
	removeMonsters(square)
	square.state = { status = "idle", players = {}, scores = {}, monsters = {} }
end

local function zenForPlace(square, place)
	if place > 10 then
		return 0
	end
	local first, tenth = square.zen[1], square.zen[2]
	return math.floor(first - (first - tenth) * (place - 1) / 9)
end

local function giveJewels(player, count)
	local names = {}
	for _ = 1, count do
		local jewelId = DS.JEWELS[math.random(#DS.JEWELS)]
		if player:addItem(jewelId, 1) then
			names[#names + 1] = ItemType(jewelId):getName()
		end
	end
	return names
end

-- fin del evento: ranking, premios y todos afuera
function DS.finish(square)
	local state = square.state
	state.status = "ending"
	removeMonsters(square)

	local ranking = {}
	for playerId in pairs(state.players) do
		local player = Player(playerId)
		if player then
			local score = state.scores[playerId]
			score.playerId = playerId
			ranking[#ranking + 1] = score
		end
	end
	table.sort(ranking, function(a, b)
		if a.points ~= b.points then
			return a.points > b.points
		end
		return a.kills > b.kills
	end)

	local lines = { string.format("Devil Square +%d terminada. Ranking:", square.level) }
	for place, score in ipairs(ranking) do
		lines[#lines + 1] = string.format("%d. %s - %d puntos (%d monstruos)", place, score.name, score.points, score.kills)
	end
	local rankingText = table.concat(lines, "\n")

	for place, score in ipairs(ranking) do
		local player = Player(score.playerId)
		if player then
			Mubia.sendMessage(player, MESSAGE_EVENT_ADVANCE, rankingText)
			local rewards = {}
			if score.points > 0 then
				local zen = zenForPlace(square, place)
				if zen > 0 then
					Mubia.addZen(player, zen)
					rewards[#rewards + 1] = string.format("%d zen", zen)
				end
				local jewels = place == 1 and square.jewels[1] or place <= 3 and square.jewels[2] or 0
				if jewels > 0 then
					rewards[#rewards + 1] = table.concat(giveJewels(player, jewels), ", ")
				end
				local exp = math.floor(score.exp * DS.bonusExpPercent / 100)
				if exp > 0 then
					player:addExperience(exp, true)
					rewards[#rewards + 1] = string.format("%d de experiencia", exp)
				end
			end
			if #rewards > 0 then
				Mubia.sendMessage(player, MESSAGE_EVENT_ADVANCE, string.format("Puesto %d. Premio: %s.", place, table.concat(rewards, " + ")))
			else
				Mubia.sendMessage(player, MESSAGE_EVENT_ADVANCE, string.format("Puesto %d. Sin premio: no mataste ningún monstruo.", place))
			end
			player:getPosition():sendMagicEffect(CONST_ME_FIREWORK_YELLOW)
		end
	end

	-- unos segundos para leer el ranking y afuera
	addEvent(function(level)
		local sq = DS.squares[level]
		for playerId in pairs(sq.state.players) do
			local player = Player(playerId)
			if player and DS.getSquareAt(player:getPosition()) == sq then
				DS.sendOut(player)
			end
		end
		resetSquare(sq)
	end, 5000, square.level)
end

-- cada segundo (GlobalEvent en data/scripts/mubia/devil_square.lua)
function DS.think()
	local now = os.time()
	for _, square in ipairs(DS.squares) do
		local state = square.state
		if state.status == "waiting" or state.status == "running" then
			-- se va quien murió, se desconectó o salió de la arena
			for playerId in pairs(state.players) do
				local player = Player(playerId)
				if not player or DS.getSquareAt(player:getPosition()) ~= square then
					state.players[playerId] = nil
				end
			end

			if not next(state.players) then
				resetSquare(square)
			elseif state.status == "waiting" then
				if now >= state.startAt then
					state.status = "running"
					broadcast(square, MESSAGE_EVENT_ADVANCE, string.format("¡Comienza la Devil Square +%d! Tienes %d minutos: mata todos los monstruos que puedas.", square.level, DS.duration / 60))
				end
			else
				local elapsed = now - state.startAt
				local left = state.endAt - now
				if left <= 0 then
					DS.finish(square)
				else
					local pool, wave = wavePool(square, elapsed)
					if state.wave ~= wave then
						if state.wave then
							broadcast(square, MESSAGE_EVENT_ADVANCE, string.format("¡Oleada %d! Llegan monstruos más fuertes.", wave))
						end
						state.wave = wave
					end
					if not state.bossDone and elapsed >= DS.bossAt then
						state.bossDone = true
						local extra = math.floor(countPlayers(square) / 5)
						for _, name in ipairs(square.bosses) do
							for _ = 0, extra do
								spawnMonster(square, name, true)
							end
						end
						broadcast(square, MESSAGE_EVENT_ADVANCE, "¡Aparecieron los jefes de la Devil Square! Valen " .. DS.bossPoints .. " puntos.")
					end
					local target = math.min(DS.aliveMax, DS.aliveBase + DS.alivePerPlayer * countPlayers(square))
					local missing = math.min(DS.spawnPerTick, target - countMonsters(square))
					for _ = 1, missing do
						spawnMonster(square, pool[math.random(#pool)], false)
					end
					if left % 60 == 0 and state.lastMinute ~= left then
						state.lastMinute = left
						broadcast(square, MESSAGE_EVENT_ADVANCE, left == 60 and "Devil Square: queda 1 minuto." or string.format("Devil Square: quedan %d minutos.", left / 60))
					end
				end
			end
		end
	end
end

-- muere un monstruo del evento: puntos para quien lo mató (o el dueño de la mascota/invocación)
function DS.onMonsterDeath(monster, killer, mostDamageKiller)
	local square = DS.getSquareAt(monster:getPosition())
	if not square then
		return
	end
	local kind = square.state.monsters[monster:getId()]
	square.state.monsters[monster:getId()] = nil
	if not kind or square.state.status ~= "running" then
		return
	end

	local function owner(creature)
		if not creature then
			return nil
		end
		if creature:isPlayer() then
			return creature
		end
		local master = creature:getMaster()
		return master and master:isPlayer() and master or nil
	end

	local player = owner(killer) or owner(mostDamageKiller)
	if not player then
		return
	end
	local score = square.state.scores[player:getId()]
	if not score or not square.state.players[player:getId()] then
		return
	end
	local points = kind == "boss" and DS.bossPoints or 1
	score.points = score.points + points
	score.kills = score.kills + 1
	player:sendTextMessage(MESSAGE_STATUS, Mubia.toLatin1(string.format("Devil Square: +%d punto%s (total %d).", points, points == 1 and "" or "s", score.points)))
end

-- experiencia que gana adentro (para el premio extra del final)
function DS.onGainExperience(player, target, exp)
	if not target or target:isPlayer() then
		return
	end
	local square = DS.getSquareAt(player:getPosition())
	if not square or square.state.status ~= "running" then
		return
	end
	local score = square.state.scores[player:getId()]
	if score then
		score.exp = score.exp + exp
	end
end

-- si entra al juego dentro de una arena sin evento (se cayó el server o se desconectó), lo saca
function DS.onLogin(player)
	local square = DS.getSquareAt(player:getPosition())
	if square and not square.state.players[player:getId()] then
		DS.sendOut(player)
		Mubia.sendMessage(player, MESSAGE_EVENT_ADVANCE, "La Devil Square terminó mientras no estabas.")
	end
end

-- Devil's Eye y Devil's Key caen de los monstruos de afuera, del nivel que corresponde al monstruo
local DROP_LEVELS = { 15, 36, 50, 60, 70, 80, 100 } -- nivel mínimo del monstruo para +1, +2, ... +7

function DS.rollDrop(monster, corpse)
	if not corpse or DS.getSquareAt(monster:getPosition()) then
		return
	end
	local mu = Mubia.WildMonsters and Mubia.WildMonsters[monster:getName()] or Mubia.MonsterStats and Mubia.MonsterStats[monster:getName()]
	if not mu or not mu.level or mu.level < DROP_LEVELS[1] then
		return
	end
	if math.random(100000) > DS.dropChance then
		return
	end
	local level = 1
	for i, minLevel in ipairs(DROP_LEVELS) do
		if mu.level >= minLevel then
			level = i
		end
	end
	local itemId = (math.random(2) == 1 and DS.EYE or DS.KEY) + level - 1
	corpse:addItem(itemId, 1)
end

-- Charon: NPC de entrada. Di "entrar" (te lleva a la que te corresponde) o el número de la Devil Square (1 a 7).
-- No vende nada, así el clic derecho le habla en vez de abrir una tienda.
function DS.registerCharon(npcType, npcConfig)
	npcConfig.name = npcType:name()
	npcConfig.description = npcConfig.name
	npcConfig.health = 100
	npcConfig.maxHealth = npcConfig.health
	npcConfig.walkInterval = 0
	npcConfig.walkRadius = 0
	npcConfig.flags = { floorchange = false }
	npcConfig.voices = {
		interval = 15000,
		chance = 20,
		{ text = Mubia.toLatin1("¡La Devil Square espera a los valientes! Háblame para entrar.") },
	}

	local keywordHandler = KeywordHandler:new()
	local npcHandler = NpcHandler:new(keywordHandler)

	npcType.onThink = function(npc, interval)
		npcHandler:onThink(npc, interval)
	end
	npcType.onAppear = function(npc, creature)
		npcHandler:onAppear(npc, creature)
	end
	npcType.onDisappear = function(npc, creature)
		npcHandler:onDisappear(npc, creature)
	end
	npcType.onMove = function(npc, creature, fromPosition, toPosition)
		npcHandler:onMove(npc, creature, fromPosition, toPosition)
	end
	npcType.onSay = function(npc, creature, type, message)
		npcHandler:onSay(npc, creature, type, message)
	end
	npcType.onCloseChannel = function(npc, player)
		npcHandler:onCloseChannel(npc, player)
	end

	local function listText(player)
		local lines = {}
		for _, square in ipairs(DS.squares) do
			local state = square.state
			local status = state.status == "idle" and "libre" or string.format("%d jugador%s adentro", countPlayers(square), countPlayers(square) == 1 and "" or "es")
			lines[#lines + 1] = string.format("{%d}: %s, %s", square.level, squareLabel(square), status)
		end
		return table.concat(lines, "\n")
	end

	local function tryEnter(npc, player, square)
		if DS.enter(player, square) then
			npcHandler:removeInteraction(npc, player)
		else
			local _, reason = DS.canEnter(player, square)
			if reason then
				npcHandler:say(Mubia.toLatin1(reason), npc, player)
			end
		end
	end

	npcHandler:setCallback(CALLBACK_GREET, function(npc, player)
		local text = "Soy Charon, el guardián de la Devil Square. Durante 5 minutos te atacarán oleadas de monstruos: "
			.. "los 10 que más maten se llevan zen, y los 3 primeros también joyas. "
		if DS.requireInvitation then
			text = text .. "Necesitas una Devil's Invitation del nivel de la Devil Square. "
		else
			text = text .. "Por ahora te dejo entrar sin invitación. "
		end
		text = text .. "Di {entrar} para ir a la que te corresponde o el número (1 a 7):\n" .. listText(player)
		npcHandler:setMessage(MESSAGE_GREET, Mubia.toLatin1(text))
		return true
	end)

	npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, function(npc, player, type, msg)
		if not npcHandler:checkInteraction(npc, player) then
			return false
		end
		local number = tonumber(msg:match("(%d+)"))
		if number and DS.squares[number] then
			tryEnter(npc, player, DS.squares[number])
		elseif MsgContains(msg, "entrar") or MsgContains(msg, "devil") or MsgContains(msg, "square") or MsgContains(msg, "yes") or MsgContains(msg, "si") then
			local square = DS.getSquareForPlayer(player)
			if not square then
				npcHandler:say(Mubia.toLatin1(string.format("Necesitas al menos nivel %d para la Devil Square.", DS.squares[1].minLevel)), npc, player)
			else
				tryEnter(npc, player, square)
			end
		elseif MsgContains(msg, "lista") or MsgContains(msg, "info") then
			npcHandler:say(Mubia.toLatin1(listText(player)), npc, player)
		end
		return true
	end)

	npcHandler:setMessage(MESSAGE_FAREWELL, Mubia.toLatin1("Que los dioses te protejan."))
	npcHandler:setMessage(MESSAGE_WALKAWAY, Mubia.toLatin1("Vuelve cuando tengas valor."))
	npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

	npcType:register(npcConfig)
end
