-- Mubia Online: Blood Castle (evento de MU). Se entra con el Messenger of Archangel; adentro hay que:
--   1. matar monstruos en el patio hasta llegar a la cantidad pedida (depende de cuántos jugadores entraron),
--   2. romper la Castle Gate,
--   3. matar a los Magic Skeleton del salón del santo,
--   4. romper la Statue of Saint,
--   5. llevarle al Archangel (en la llegada) el arma que deja la estatua.
-- Quien entrega el arma (y su party) gana zen, una joya (a veces una caja de 10) y experiencia extra;
-- los demás que siguen adentro ganan un poco de zen y experiencia. Si se acaban los 15 minutos, nadie gana premio.
-- Mapa: 8 castillos en x2306-2595 y650-716 (tools/mubia/mapas/blood_castle.py). Scripts: data/scripts/mubia/blood_castle.lua.
-- Items: Scroll of Archangel +1..+8 (60631-60638), Blood Bone (60641-60648), Cloak of Invisibility (60651-60658),
-- armas del Archangel (60661-60663).

Mubia.BloodCastle = {
	-- mientras probamos, el Messenger deja entrar siempre: sin Cloak of Invisibility y a cualquier castillo
	requireCloak = false,
	checkLevel = false,

	prepare = 30, -- segundos de espera antes de que baje el puente (solo se puede entrar en ese tiempo)
	duration = 15 * 60, -- segundos de evento
	maxPlayers = 15,
	killsPerPlayer = 40, -- monstruos del patio para que aparezca la puerta (por jugador)
	killsMax = 300,
	skeletonsPerPlayer = 5, -- Magic Skeleton del salón (por jugador)
	skeletonsMax = 50,
	aliveBase = 15, -- monstruos vivos a la vez en el patio: base + por jugador (hasta aliveMax)
	alivePerPlayer = 5,
	aliveMax = 45,
	spawnPerTick = 6, -- cuántos aparecen por segundo como máximo
	winnerExpPercent = 100, -- al ganar: % extra de la experiencia que ganaste adentro (los demás, otherExpPercent)
	otherExpPercent = 50,
	dropChance = 1000, -- de 100000 (1%): Scroll of Archangel o Blood Bone en los monstruos de afuera

	SCROLL = 60631,
	BONE = 60641,
	CLOAK = 60651,
	WEAPONS = { 60661, 60662, 60663 }, -- Divine Sword, Staff y Crossbow of Archangel
	BARS = 2185,
	-- premio: una de estas joyas; con boxChance% sale la "caja" de 10 (paquete de 10 si existe, si no 10 joyas)
	JEWELS = {
		{ id = 60304, box = nil }, -- Jewel of Chaos
		{ id = 60301, box = 60312 }, -- Jewel of Soul (Soul Bundle x10)
		{ id = 60303, box = 60309 }, -- Jewel of Bless (Bless Bundle x10)
	},

	-- zen = { ganador, los demás }; boxChance = % de la caja de 10 joyas (mudream)
	castles = {
		{ minLevel = 15, maxLevel = 80, zen = { 20000, 10000 }, boxChance = 15 },
		{ minLevel = 81, maxLevel = 130, zen = { 50000, 25000 }, boxChance = 15 },
		{ minLevel = 131, maxLevel = 180, zen = { 90000, 45000 }, boxChance = 20 },
		{ minLevel = 181, maxLevel = 230, zen = { 140000, 70000 }, boxChance = 20 },
		{ minLevel = 231, maxLevel = 280, zen = { 190000, 95000 }, boxChance = 25 },
		{ minLevel = 281, maxLevel = 330, zen = { 250000, 120000 }, boxChance = 25 },
		{ minLevel = 331, maxLevel = 400, zen = { 300000, 140000 }, boxChance = 30 },
		{ minLevel = 400, maxLevel = 400, minResets = 1, zen = { 350000, 160000 }, boxChance = 30 },
	},
}

local BC = Mubia.BloodCastle

-- monstruos de cada castillo (data-canary/monster/mubia/blood_castle, generados por tools/mubia/blood_castle_monsters.py)
local YARD_MONSTERS = { "Chief Skeleton Warrior", "Chief Skeleton Archer", "Dark Skull Soldier", "Giant Ogre", "Red Skeleton Knight" }

-- posiciones de cada castillo (las mismas que arma tools/mubia/mapas/blood_castle.py)
for level, castle in ipairs(BC.castles) do
	local x0 = 2306 + (level - 1) * 37
	castle.level = level
	castle.fromPos = Position(x0 + 1, 651, 7)
	castle.toPos = Position(x0 + 29, 715, 7)
	castle.arrive = Position(x0 + 15, 712, 7)
	castle.archangel = Position(x0 + 15, 705, 7)
	castle.altar = Position(x0 + 15, 653, 7)
	castle.gate = { Position(x0 + 14, 665, 7), Position(x0 + 15, 665, 7), Position(x0 + 16, 665, 7) }
	castle.gateMonster = Position(x0 + 15, 665, 7)
	castle.barrier = {}
	for x = x0 + 13, x0 + 17 do
		castle.barrier[#castle.barrier + 1] = Position(x, 696, 7)
	end
	castle.yard = { Position(x0 + 1, 666, 7), Position(x0 + 29, 694, 7) }
	castle.hall = { Position(x0 + 1, 651, 7), Position(x0 + 29, 664, 7) }
	castle.monsters = {}
	for _, name in ipairs(YARD_MONSTERS) do
		castle.monsters[#castle.monsters + 1] = name .. " " .. level
	end
	castle.skeleton = "Magic Skeleton " .. level
	castle.state = { status = "idle", players = {}, scores = {}, monsters = {} }
end

function BC.getCastleAt(position)
	for _, castle in ipairs(BC.castles) do
		if position:isInRange(castle.fromPos, castle.toPos) then
			return castle
		end
	end
	return nil
end

local function getResets(player)
	return Mubia.getStats and Mubia.getStats(player).resets or 0
end

-- el castillo que le toca al personaje por nivel y resets
function BC.getCastleForPlayer(player)
	local level, resets = player:getLevel(), getResets(player)
	for i = #BC.castles, 1, -1 do
		local castle = BC.castles[i]
		if resets >= (castle.minResets or 0) and level >= castle.minLevel then
			return castle
		end
	end
	return nil
end

local function castleLabel(castle)
	if castle.minResets then
		return string.format("Blood Castle %d (nivel %d con %d reset o más)", castle.level, castle.minLevel, castle.minResets)
	end
	return string.format("Blood Castle %d (nivel %d a %d)", castle.level, castle.minLevel, castle.maxLevel)
end

local function broadcast(castle, messageType, text)
	for playerId in pairs(castle.state.players) do
		local player = Player(playerId)
		if player then
			Mubia.sendMessage(player, messageType, text)
		end
	end
end

local function countPlayers(castle)
	local count = 0
	for _ in pairs(castle.state.players) do
		count = count + 1
	end
	return count
end

local function isWeapon(itemId)
	for _, id in ipairs(BC.WEAPONS) do
		if id == itemId then
			return true
		end
	end
	return false
end

local function removeWeapons(player)
	for _, id in ipairs(BC.WEAPONS) do
		local count = player:getItemCount(id)
		if count > 0 then
			player:removeItem(id, count)
		end
	end
end

local function carriesWeapon(player)
	for _, id in ipairs(BC.WEAPONS) do
		if player:getItemCount(id) > 0 then
			return true
		end
	end
	return false
end

-- ---------- rejas del puente y de la puerta ----------

local function addBars(position)
	local tile = Tile(position)
	if tile and not tile:getItemById(BC.BARS) then
		Game.createItem(BC.BARS, 1, position)
	end
end

local function removeBars(position)
	local tile = Tile(position)
	local item = tile and tile:getItemById(BC.BARS)
	if item then
		item:remove()
		position:sendMagicEffect(CONST_ME_POFF)
	end
end

local function closeCastle(castle)
	for _, position in ipairs(castle.barrier) do
		addBars(position)
	end
	for _, position in ipairs(castle.gate) do
		addBars(position)
	end
end

-- ---------- entrar y salir ----------

-- revisa si puede entrar; devuelve true o false y el motivo
function BC.canEnter(player, castle)
	local state = castle.state
	if state.players[player:getId()] then
		return false, "Ya estás adentro."
	end
	if state.status == "running" then
		return false, string.format("El Blood Castle %d ya empezó y el puente está abajo: no se puede entrar. Quedan %d segundos.", castle.level, math.max(0, state.endAt - os.time()))
	end
	if state.status == "ending" then
		return false, string.format("El Blood Castle %d está terminando. Espera unos segundos.", castle.level)
	end
	if countPlayers(castle) >= BC.maxPlayers then
		return false, string.format("El Blood Castle %d está lleno (%d jugadores).", castle.level, BC.maxPlayers)
	end
	if BC.checkLevel then
		local level, resets = player:getLevel(), getResets(player)
		if level < castle.minLevel or level > castle.maxLevel and not castle.minResets or resets < (castle.minResets or 0) then
			return false, "No tienes el nivel para ese Blood Castle. Te corresponde: " .. castleLabel(BC.getCastleForPlayer(player) or BC.castles[1])
		end
	end
	if BC.requireCloak and player:getItemCount(BC.CLOAK + castle.level - 1) < 1 then
		return false, string.format("Necesitas una Cloak of Invisibility +%d.", castle.level)
	end
	return true
end

function BC.enter(player, castle)
	local ok, reason = BC.canEnter(player, castle)
	if not ok then
		Mubia.sendMessage(player, MESSAGE_FAILURE, reason)
		return false
	end

	-- la capa se gasta solo si es obligatoria
	if BC.requireCloak then
		player:removeItem(BC.CLOAK + castle.level - 1, 1)
	end

	local state = castle.state
	local playerId = player:getId()
	state.players[playerId] = true
	state.scores[playerId] = state.scores[playerId] or { name = player:getName(), exp = 0, kills = 0 }
	local position = player:getPosition()
	player:kv():scoped("mubia-blood-castle"):set("exit", { x = position.x, y = position.y, z = position.z })

	position:sendMagicEffect(CONST_ME_TELEPORT)
	player:teleportTo(castle.arrive)
	castle.arrive:sendMagicEffect(CONST_ME_HOLYAREA)

	if state.status == "idle" then
		closeCastle(castle)
		state.status = "waiting"
		state.startAt = os.time() + BC.prepare
		state.endAt = state.startAt + BC.duration
	end
	Mubia.sendMessage(player, MESSAGE_EVENT_ADVANCE, string.format("Entraste al Blood Castle %d. El puente baja en %d segundos: mata a los monstruos del patio, rompe la puerta, mata a los Magic Skeleton, rompe la Statue of Saint y trae el arma al Archangel.", castle.level, math.max(0, state.startAt - os.time())))
	return true
end

-- adonde vuelve el jugador al salir: donde habló con el Messenger (o el templo de su ciudad)
function BC.getExitPosition(player)
	local exit = player:kv():scoped("mubia-blood-castle"):get("exit")
	if type(exit) == "table" and exit.x then
		local position = Position(exit.x, exit.y, exit.z)
		if not BC.getCastleAt(position) and Tile(position) then
			return position
		end
	end
	return player:getTown():getTemplePosition()
end

function BC.sendOut(player)
	removeWeapons(player)
	player:teleportTo(BC.getExitPosition(player))
	player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
	player:kv():scoped("mubia-blood-castle"):remove("exit")
end

-- ---------- monstruos ----------

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

local function randomFreePosition(area)
	for _ = 1, 30 do
		local position = Position(math.random(area[1].x, area[2].x), math.random(area[1].y, area[2].y), area[1].z)
		if isFreeTile(position) then
			return position
		end
	end
	return nil
end

local function spawnMonster(castle, name, kind, position)
	position = position or randomFreePosition(kind == "skeleton" and castle.hall or castle.yard)
	if not position then
		return nil
	end
	local monster = Game.createMonster(name, position, false, true)
	if not monster then
		return nil
	end
	monster:registerEvent("MubiaBloodCastleDeath")
	castle.state.monsters[monster:getId()] = kind
	position:sendMagicEffect(kind == "normal" and CONST_ME_TELEPORT or CONST_ME_MORTAREA)
	return monster
end

local function countMonsters(castle, kind)
	local count = 0
	for monsterId, monsterKind in pairs(castle.state.monsters) do
		if not Monster(monsterId) then
			castle.state.monsters[monsterId] = nil
		elseif monsterKind == kind then
			count = count + 1
		end
	end
	return count
end

local function removeMonsters(castle)
	for monsterId in pairs(castle.state.monsters) do
		local monster = Monster(monsterId)
		if monster then
			monster:getPosition():sendMagicEffect(CONST_ME_POFF)
			monster:remove()
		end
	end
	castle.state.monsters = {}
end

-- busca las armas del Archangel tiradas en el castillo (las borra si borrar = true)
local function findWeaponsOnGround(castle, remove)
	local found = 0
	for y = castle.fromPos.y, castle.toPos.y do
		for x = castle.fromPos.x, castle.toPos.x do
			local tile = Tile(Position(x, y, castle.fromPos.z))
			if tile then
				for _, id in ipairs(BC.WEAPONS) do
					local item = tile:getItemById(id)
					if item then
						found = found + 1
						if remove then
							item:remove()
						end
					end
				end
			end
		end
	end
	return found
end

local function resetCastle(castle)
	removeMonsters(castle)
	findWeaponsOnGround(castle, true)
	closeCastle(castle)
	castle.state = { status = "idle", players = {}, scores = {}, monsters = {} }
end

-- ---------- pasos del evento ----------

local function killGoal(castle)
	return math.min(BC.killsMax, BC.killsPerPlayer * math.max(1, countPlayers(castle)))
end

local function skeletonGoal(castle)
	return math.min(BC.skeletonsMax, BC.skeletonsPerPlayer * math.max(1, countPlayers(castle)))
end

local function stepText(castle)
	local state = castle.state
	if state.step == "monsters" then
		return string.format("Paso 1: monstruos del patio %d/%d.", state.kills, killGoal(castle))
	elseif state.step == "gate" then
		return "Paso 2: ¡rompe la Castle Gate!"
	elseif state.step == "skeletons" then
		return string.format("Paso 3: Magic Skeleton %d/%d.", state.skeletonKills, skeletonGoal(castle))
	elseif state.step == "statue" then
		return "Paso 4: ¡rompe la Statue of Saint en el altar!"
	elseif state.step == "weapon" then
		return "Paso 5: ¡lleva el arma del Archangel a la entrada!"
	end
	return ""
end

-- vida de la puerta y la estatua: 2 y 3 veces la de un Magic Skeleton del mismo castillo
local function objectHealth(castle, times)
	local skeletonType = MonsterType(castle.skeleton)
	local health = skeletonType and skeletonType:maxHealth() or 3000 * castle.level
	return health * times
end

local function openGate(castle)
	local state = castle.state
	state.step = "gate"
	removeBars(castle.gateMonster)
	local gate = spawnMonster(castle, "Castle Gate", "gate", castle.gateMonster)
	if gate then
		local health = objectHealth(castle, 2)
		gate:setMaxHealth(health)
		gate:addHealth(health)
	end
	broadcast(castle, MESSAGE_EVENT_ADVANCE, "¡Mataron suficientes monstruos! Apareció la Castle Gate: rómpanla para entrar al salón del santo.")
end

local function gateBroken(castle)
	local state = castle.state
	state.step = "skeletons"
	state.skeletonKills = 0
	for _, position in ipairs(castle.gate) do
		removeBars(position)
	end
	broadcast(castle, MESSAGE_EVENT_ADVANCE, string.format("¡La Castle Gate cayó! Maten %d Magic Skeleton en el salón del santo.", skeletonGoal(castle)))
end

local function spawnStatue(castle)
	local state = castle.state
	state.step = "statue"
	local statue = spawnMonster(castle, "Statue of Saint", "statue", castle.altar)
	if not statue then
		-- si alguien está parado en el altar, al lado
		statue = spawnMonster(castle, "Statue of Saint", "statue", Position(castle.altar.x, castle.altar.y + 1, castle.altar.z))
	end
	if statue then
		local health = objectHealth(castle, 3)
		statue:setMaxHealth(health)
		statue:addHealth(health)
	end
	broadcast(castle, MESSAGE_EVENT_ADVANCE, "¡Apareció la Statue of Saint en el altar! Rómpanla para recuperar el arma del Archangel.")
end

local function dropWeapon(castle, position)
	local state = castle.state
	state.step = "weapon"
	state.weaponId = state.weaponId or BC.WEAPONS[math.random(#BC.WEAPONS)]
	Game.createItem(state.weaponId, 1, position)
	position:sendMagicEffect(CONST_ME_HOLYAREA)
end

-- ---------- final ----------

local function giveJewel(player, castle)
	local jewel = BC.JEWELS[math.random(#BC.JEWELS)]
	if math.random(100) <= castle.boxChance then
		if jewel.box then
			player:addItem(jewel.box, 1)
			return ItemType(jewel.box):getName()
		end
		player:addItem(jewel.id, 10)
		return "10x " .. ItemType(jewel.id):getName()
	end
	player:addItem(jewel.id, 1)
	return ItemType(jewel.id):getName()
end

-- ganadores: quien entregó el arma y los de su party que están adentro
local function winnersOf(castle, deliverer)
	local winners = { [deliverer:getId()] = true }
	local party = deliverer:getParty()
	if party then
		local members = party:getMembers() or {}
		members[#members + 1] = party:getLeader()
		for _, member in ipairs(members) do
			if member and castle.state.players[member:getId()] then
				winners[member:getId()] = true
			end
		end
	end
	return winners
end

-- fin del evento: deliverer = jugador que entregó el arma (nil si se acabó el tiempo)
function BC.finish(castle, deliverer)
	local state = castle.state
	state.status = "ending"
	removeMonsters(castle)
	findWeaponsOnGround(castle, true)

	local winners = deliverer and winnersOf(castle, deliverer) or {}
	if deliverer then
		broadcast(castle, MESSAGE_EVENT_ADVANCE, string.format("¡%s le devolvió el arma al Archangel! Blood Castle %d completado.", deliverer:getName(), castle.level))
	else
		broadcast(castle, MESSAGE_EVENT_ADVANCE, string.format("Se acabó el tiempo. Nadie le devolvió el arma al Archangel: Blood Castle %d fallado.", castle.level))
	end

	for playerId in pairs(state.players) do
		local player = Player(playerId)
		if player then
			removeWeapons(player)
			if deliverer then
				local score = state.scores[playerId]
				local winner = winners[playerId]
				local rewards = {}
				local zen = winner and castle.zen[1] or castle.zen[2]
				Mubia.addZen(player, zen)
				rewards[#rewards + 1] = string.format("%d zen", zen)
				if winner then
					rewards[#rewards + 1] = giveJewel(player, castle)
				end
				local exp = math.floor(score.exp * (winner and BC.winnerExpPercent or BC.otherExpPercent) / 100)
				if exp > 0 then
					player:addExperience(exp, true)
					rewards[#rewards + 1] = string.format("%d de experiencia", exp)
				end
				Mubia.sendMessage(player, MESSAGE_EVENT_ADVANCE, string.format("%s Premio: %s.", winner and "¡Ganaste!" or "Ayudaste en el castillo.", table.concat(rewards, " + ")))
				player:getPosition():sendMagicEffect(winner and CONST_ME_FIREWORK_YELLOW or CONST_ME_FIREWORK_BLUE)
			end
		end
	end

	-- unos segundos para leer y afuera
	addEvent(function(level)
		local c = BC.castles[level]
		for playerId in pairs(c.state.players) do
			local player = Player(playerId)
			if player and BC.getCastleAt(player:getPosition()) == c then
				BC.sendOut(player)
			end
		end
		resetCastle(c)
	end, 8000, castle.level)
end

-- GOD (/bc next N): salta al paso siguiente para probar sin matar todo
function BC.skipStep(castle)
	local state = castle.state
	if state.status ~= "running" then
		return false
	end
	if state.step == "monsters" then
		openGate(castle)
	elseif state.step == "gate" then
		for monsterId, kind in pairs(state.monsters) do
			local monster = Monster(monsterId)
			if kind == "gate" and monster then
				state.monsters[monsterId] = nil
				monster:remove()
			end
		end
		gateBroken(castle)
	elseif state.step == "skeletons" then
		spawnStatue(castle)
	elseif state.step == "statue" then
		for monsterId, kind in pairs(state.monsters) do
			local monster = Monster(monsterId)
			if kind == "statue" and monster then
				state.monsters[monsterId] = nil
				monster:remove()
			end
		end
		dropWeapon(castle, castle.altar)
		broadcast(castle, MESSAGE_EVENT_ADVANCE, "El arma del Archangel está en el altar.")
	else
		return false
	end
	return true
end

-- el Archangel recibe el arma
function BC.deliver(player, castle)
	local state = castle.state
	if state.status ~= "running" or not state.players[player:getId()] or not carriesWeapon(player) then
		return false
	end
	removeWeapons(player)
	BC.finish(castle, player)
	return true
end

-- ---------- reloj (cada segundo, GlobalEvent en data/scripts/mubia/blood_castle.lua) ----------

local function checkWeapon(castle)
	local state = castle.state
	if state.step ~= "weapon" then
		return
	end
	for playerId in pairs(state.players) do
		local player = Player(playerId)
		if player and carriesWeapon(player) then
			return
		end
	end
	-- nadie la tiene: si no está tirada en el castillo (se murió o se fue quien la llevaba), vuelve al altar
	if findWeaponsOnGround(castle, false) == 0 then
		dropWeapon(castle, castle.altar)
		broadcast(castle, MESSAGE_EVENT_ADVANCE, "¡El arma del Archangel volvió al altar!")
	end
end

function BC.think()
	local now = os.time()
	for _, castle in ipairs(BC.castles) do
		local state = castle.state
		if state.status == "waiting" or state.status == "running" then
			-- se va quien murió, se desconectó o salió del castillo (y si llevaba el arma, la pierde)
			for playerId in pairs(state.players) do
				local player = Player(playerId)
				if not player or BC.getCastleAt(player:getPosition()) ~= castle then
					state.players[playerId] = nil
					if player then
						removeWeapons(player)
					end
				end
			end

			if not next(state.players) then
				resetCastle(castle)
			elseif state.status == "waiting" then
				local left = state.startAt - now
				if left <= 0 then
					state.status = "running"
					state.step = "monsters"
					state.kills = 0
					for _, position in ipairs(castle.barrier) do
						removeBars(position)
					end
					broadcast(castle, MESSAGE_EVENT_ADVANCE, string.format("¡Bajó el puente del Blood Castle %d! Tienen %d minutos. Maten %d monstruos en el patio para que aparezca la puerta.", castle.level, BC.duration / 60, killGoal(castle)))
				elseif left == 10 then
					broadcast(castle, MESSAGE_EVENT_ADVANCE, "Blood Castle: el puente baja en 10 segundos.")
				end
			else
				local left = state.endAt - now
				if left <= 0 then
					BC.finish(castle, nil)
				else
					checkWeapon(castle)
					-- el patio siempre tiene monstruos (sirve para subir de nivel todo el evento)
					local target = math.min(BC.aliveMax, BC.aliveBase + BC.alivePerPlayer * countPlayers(castle))
					local missing = math.min(BC.spawnPerTick, target - countMonsters(castle, "normal"))
					for _ = 1, missing do
						spawnMonster(castle, castle.monsters[math.random(#castle.monsters)], "normal")
					end
					if state.step == "skeletons" then
						local remaining = skeletonGoal(castle) - state.skeletonKills
						local missingSkeletons = math.min(BC.spawnPerTick, remaining - countMonsters(castle, "skeleton"))
						for _ = 1, missingSkeletons do
							spawnMonster(castle, castle.skeleton, "skeleton")
						end
					end
					if left % 60 == 0 and state.lastMinute ~= left then
						state.lastMinute = left
						broadcast(castle, MESSAGE_EVENT_ADVANCE, string.format("Blood Castle: %s. %s", left == 60 and "queda 1 minuto" or string.format("quedan %d minutos", left / 60), stepText(castle)))
					end
				end
			end
		end
	end
end

-- ---------- muertes ----------

local function ownerOf(creature)
	if not creature then
		return nil
	end
	if creature:isPlayer() then
		return creature
	end
	local master = creature:getMaster()
	return master and master:isPlayer() and master or nil
end

function BC.onMonsterDeath(monster, killer, mostDamageKiller)
	local castle = BC.getCastleAt(monster:getPosition())
	if not castle then
		return
	end
	local state = castle.state
	local kind = state.monsters[monster:getId()]
	state.monsters[monster:getId()] = nil
	if not kind or state.status ~= "running" then
		return
	end

	local player = ownerOf(killer) or ownerOf(mostDamageKiller)
	local score = player and state.scores[player:getId()]
	if score then
		score.kills = score.kills + 1
	end

	if kind == "normal" and state.step == "monsters" then
		state.kills = state.kills + 1
		local goal = killGoal(castle)
		if state.kills >= goal then
			openGate(castle)
		elseif state.kills % 5 == 0 or goal - state.kills <= 5 then
			broadcast(castle, MESSAGE_STATUS, stepText(castle))
		end
	elseif kind == "gate" then
		gateBroken(castle)
	elseif kind == "skeleton" and state.step == "skeletons" then
		state.skeletonKills = state.skeletonKills + 1
		if state.skeletonKills >= skeletonGoal(castle) then
			spawnStatue(castle)
		else
			broadcast(castle, MESSAGE_STATUS, stepText(castle))
		end
	elseif kind == "statue" then
		dropWeapon(castle, monster:getPosition())
		broadcast(castle, MESSAGE_EVENT_ADVANCE, string.format("¡La Statue of Saint se rompió y dejó la %s en el altar! Levántala y llévasela al Archangel en la entrada.", ItemType(state.weaponId):getName()))
	end
end

-- experiencia que gana adentro (para el premio extra del final)
function BC.onGainExperience(player, target, exp)
	if not target or target:isPlayer() then
		return
	end
	local castle = BC.getCastleAt(player:getPosition())
	if not castle or castle.state.status ~= "running" then
		return
	end
	local score = castle.state.scores[player:getId()]
	if score then
		score.exp = score.exp + exp
	end
end

-- si entra al juego dentro de un castillo sin evento (se cayó el server o se desconectó), lo saca; el arma nunca sale del castillo
function BC.onLogin(player)
	local castle = BC.getCastleAt(player:getPosition())
	if castle and not castle.state.players[player:getId()] then
		BC.sendOut(player)
		Mubia.sendMessage(player, MESSAGE_EVENT_ADVANCE, "El Blood Castle terminó mientras no estabas.")
	elseif not castle then
		removeWeapons(player)
	end
end

-- el arma no se puede sacar del castillo ni tirarse fuera de él
function BC.canMoveWeapon(player, item, toPosition)
	if not isWeapon(item:getId()) then
		return true
	end
	if toPosition.x == CONTAINER_POSITION then
		return true
	end
	return BC.getCastleAt(toPosition) ~= nil
end

-- Scroll of Archangel y Blood Bone caen de los monstruos de afuera, del nivel que corresponde al monstruo
local DROP_LEVELS = { 15, 30, 45, 58, 70, 80, 90, 101 } -- nivel mínimo del monstruo para +1, +2, ... +8

function BC.rollDrop(monster, corpse)
	if not corpse or BC.getCastleAt(monster:getPosition()) then
		return
	end
	if Mubia.DevilSquare and Mubia.DevilSquare.getSquareAt(monster:getPosition()) then
		return
	end
	local mu = Mubia.WildMonsters and Mubia.WildMonsters[monster:getName()] or Mubia.MonsterStats and Mubia.MonsterStats[monster:getName()]
	if not mu or not mu.level or mu.level < DROP_LEVELS[1] then
		return
	end
	if math.random(100000) > BC.dropChance then
		return
	end
	local level = 1
	for i, minLevel in ipairs(DROP_LEVELS) do
		if mu.level >= minLevel then
			level = i
		end
	end
	local itemId = (math.random(2) == 1 and BC.SCROLL or BC.BONE) + level - 1
	corpse:addItem(itemId, 1)
end

-- ---------- criaturas ----------

-- Castle Gate y Statue of Saint: no caminan ni atacan, no dan botín
function BC.registerObject(mType, monster, cfg)
	monster.description = "the " .. mType:name():lower()
	monster.experience = 0
	monster.health = cfg.health
	monster.maxHealth = cfg.health
	monster.race = "undead"
	monster.corpse = cfg.corpse
	monster.speed = 0
	monster.manaCost = 0
	monster.changeTarget = { interval = 4000, chance = 0 }
	monster.strategiesTarget = { nearest = 100 }
	monster.flags = {
		summonable = false,
		attackable = true,
		hostile = false,
		convinceable = false,
		pushable = false,
		rewardBoss = false,
		illusionable = false,
		canPushItems = false,
		canPushCreatures = false,
		staticAttackChance = 100,
		targetDistance = 1,
		runHealth = 0,
		healthHidden = false,
		isBlockable = false,
		canWalkOnEnergy = false,
		canWalkOnFire = false,
		canWalkOnPoison = false,
	}
	monster.light = { level = 0, color = 0 }
	monster.loot = {}
	monster.attacks = {}
	monster.defenses = { defense = 0, armor = 0 }
	monster.elements = {}
	monster.immunities = {
		{ type = "paralyze", condition = true },
		{ type = "outfit", condition = true },
		{ type = "invisible", condition = true },
		{ type = "bleed", condition = false },
	}
	mType:register(monster)
end

local function registerTalkNpc(npcType, npcConfig, voice, onGreet, onMessage)
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
		{ text = Mubia.toLatin1(voice) },
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

	npcHandler:setCallback(CALLBACK_GREET, function(npc, player)
		npcHandler:setMessage(MESSAGE_GREET, Mubia.toLatin1(onGreet(npc, player, npcHandler)))
		return true
	end)
	npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, function(npc, player, type, msg)
		if not npcHandler:checkInteraction(npc, player) then
			return false
		end
		onMessage(npc, player, msg, npcHandler)
		return true
	end)
	npcHandler:setMessage(MESSAGE_FAREWELL, Mubia.toLatin1("Que la luz te guíe."))
	npcHandler:setMessage(MESSAGE_WALKAWAY, Mubia.toLatin1("Que la luz te guíe."))
	npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

	npcType:register(npcConfig)
end

local function listText()
	local lines = {}
	for _, castle in ipairs(BC.castles) do
		local state = castle.state
		local status
		if state.status == "idle" then
			status = "libre"
		elseif state.status == "waiting" then
			status = string.format("se puede entrar (%d s, %d adentro)", math.max(0, state.startAt - os.time()), countPlayers(castle))
		else
			status = string.format("en curso, %d adentro", countPlayers(castle))
		end
		lines[#lines + 1] = string.format("{%d}: %s, %s", castle.level, castleLabel(castle), status)
	end
	return table.concat(lines, "\n")
end

-- Messenger of Archangel: NPC de entrada. Di "entrar" (te lleva al que te corresponde) o el número del castillo (1 a 8).
-- No vende nada, así el clic derecho le habla en vez de abrir una tienda.
function BC.registerMessenger(npcType, npcConfig)
	local function tryEnter(npc, player, castle, npcHandler)
		if BC.enter(player, castle) then
			npcHandler:removeInteraction(npc, player)
		else
			local _, reason = BC.canEnter(player, castle)
			if reason then
				npcHandler:say(Mubia.toLatin1(reason), npc, player)
			end
		end
	end

	registerTalkNpc(npcType, npcConfig, "¡Los demonios robaron el arma del Archangel! Háblame para entrar al Blood Castle.", function(npc, player)
		local text = "Soy el mensajero del Archangel. Los demonios le robaron su arma y la guardan en el Blood Castle. " .. "Adentro: mata los monstruos del patio, rompe la puerta, mata a los Magic Skeleton, rompe la Statue of Saint " .. "y llévale el arma al Archangel. Tienes 15 minutos y solo se puede entrar antes de que baje el puente. "
		if BC.requireCloak then
			text = text .. "Necesitas una Cloak of Invisibility del nivel del castillo. "
		else
			text = text .. "Por ahora te dejo entrar sin Cloak of Invisibility. "
		end
		return text .. "Di {entrar} para ir al que te corresponde o el número (1 a 8):\n" .. listText()
	end, function(npc, player, msg, npcHandler)
		local number = tonumber(msg:match("(%d+)"))
		if number and BC.castles[number] then
			tryEnter(npc, player, BC.castles[number], npcHandler)
		elseif MsgContains(msg, "entrar") or MsgContains(msg, "blood") or MsgContains(msg, "castle") or MsgContains(msg, "yes") or MsgContains(msg, "si") then
			local castle = BC.getCastleForPlayer(player)
			if not castle then
				npcHandler:say(Mubia.toLatin1(string.format("Necesitas al menos nivel %d para el Blood Castle.", BC.castles[1].minLevel)), npc, player)
			else
				tryEnter(npc, player, castle, npcHandler)
			end
		elseif MsgContains(msg, "lista") or MsgContains(msg, "info") then
			npcHandler:say(Mubia.toLatin1(listText()), npc, player)
		end
	end)
end

-- Archangel: está en la llegada de cada castillo. Si le hablas con su arma, ganas. "salir" te saca del castillo.
function BC.registerArchangel(npcType, npcConfig)
	registerTalkNpc(npcType, npcConfig, "¡Valientes, recuperen mi arma!", function(npc, player)
		local castle = BC.getCastleAt(npc:getPosition())
		if castle and carriesWeapon(player) and BC.deliver(player, castle) then
			return "¡Mi arma! Gracias, valiente. La luz te recompensa."
		end
		local text = "Los demonios robaron mi arma. "
		if castle and castle.state.status == "running" then
			text = text .. stepText(castle) .. string.format(" Quedan %d segundos. ", math.max(0, castle.state.endAt - os.time()))
		end
		return text .. "Di {salir} si quieres volver a la ciudad."
	end, function(npc, player, msg, npcHandler)
		local castle = BC.getCastleAt(npc:getPosition())
		if castle and carriesWeapon(player) and BC.deliver(player, castle) then
			npcHandler:say(Mubia.toLatin1("¡Mi arma! Gracias, valiente. La luz te recompensa."), npc, player)
			npcHandler:removeInteraction(npc, player)
		elseif MsgContains(msg, "salir") then
			npcHandler:removeInteraction(npc, player)
			if castle then
				castle.state.players[player:getId()] = nil
			end
			BC.sendOut(player)
		end
	end)
end
