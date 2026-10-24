-- Mubia Online: party estilo MU Online y nivel máximo.
-- * Máximo Mubia.PartyConfig.maxMembers personas por party (el líder cuenta).
-- * El cliente muestra arriba a la derecha la vida de todos los de la party (opcode 87,
--   módulo game_mubia_party). El servidor manda la lista cada medio segundo, solo si cambió.
-- * Mubia.capExperience corta la experiencia en Mubia.Config.maxLevel (ver events/scripts/player.lua).

Mubia = Mubia or {}

Mubia.PARTY_OPCODE = 87

Mubia.PartyConfig = {
	maxMembers = 5,
	nearRange = 15, -- casillas: más lejos (o en otro piso) se ve gris en el panel
	maxLevelMessageDelay = 60, -- segundos entre avisos de "nivel máximo"
}

-- Lista de la party con el líder primero; nil si no tiene party.
function Mubia.getPartyPlayers(player)
	local party = player:getParty()
	if not party then
		return nil
	end
	local list = {}
	local leader = party:getLeader()
	if leader then
		list[#list + 1] = leader
	end
	for _, member in ipairs(party:getMembers() or {}) do
		list[#list + 1] = member
	end
	return list, party
end

function Mubia.getPartySize(party)
	return (party:getLeader() and 1 or 0) + party:getMemberCount()
end

function Mubia.isPartyFull(party)
	return Mubia.getPartySize(party) >= Mubia.PartyConfig.maxMembers
end

local function jsonString(text)
	return '"' .. tostring(text):gsub('\\', '\\\\'):gsub('"', '\\"') .. '"'
end

local function className(player)
	local class = Mubia.getClass and Mubia.getClass(player)
	return class and class.name or player:getVocation():getName()
end

-- Texto JSON que ve "viewer": {"members":[{...}, ...]} (vacío si no tiene party).
function Mubia.buildPartyPayload(viewer)
	local players, party = Mubia.getPartyPlayers(viewer)
	if not players then
		return '{"members":[]}'
	end
	local leader = party:getLeader()
	local viewerPos = viewer:getPosition()
	local range = Mubia.PartyConfig.nearRange
	local rows = {}
	for _, member in ipairs(players) do
		local pos = member:getPosition()
		local near = pos.z == viewerPos.z and math.abs(pos.x - viewerPos.x) <= range and math.abs(pos.y - viewerPos.y) <= range
		rows[#rows + 1] = string.format(
			'{"id":%d,"name":%s,"class":%s,"level":%d,"hp":%d,"maxHp":%d,"leader":%s,"self":%s,"near":%s}',
			member:getId(),
			jsonString(member:getName()),
			jsonString(className(member)),
			member:getLevel(),
			member:getHealth(),
			member:getMaxHealth(),
			tostring(leader and member:getId() == leader:getId()),
			tostring(member:getId() == viewer:getId()),
			tostring(near)
		)
	end
	return string.format('{"max":%d,"members":[%s]}', Mubia.PartyConfig.maxMembers, table.concat(rows, ","))
end

local lastPayload = {} -- id de jugador -> último texto mandado

function Mubia.sendPartyPanel(player, force)
	local payload = Mubia.buildPartyPayload(player)
	local id = player:getId()
	if not force and lastPayload[id] == payload then
		return
	end
	-- sin party y nunca tuvo: no hace falta mandar nada
	if not force and lastPayload[id] == nil and not player:getParty() then
		return
	end
	lastPayload[id] = payload
	player:sendExtendedOpcode(Mubia.PARTY_OPCODE, payload)
end

function Mubia.forgetPartyPanel(player)
	lastPayload[player:getId()] = nil
end

-- Se llama cada medio segundo desde data/scripts/mubia/party.lua
function Mubia.updatePartyPanels()
	for _, player in ipairs(Game.getPlayers()) do
		Mubia.sendPartyPanel(player)
	end
end

-- Cuando la party se llena, se cancelan las invitaciones que quedaban.
function Mubia.revokeExtraInvites(party)
	if not Mubia.isPartyFull(party) then
		return
	end
	local leader = party:getLeader()
	for _, invitee in ipairs(party:getInvitees() or {}) do
		party:removeInvite(invitee)
		Mubia.sendMessage(invitee, MESSAGE_PARTY_MANAGEMENT, string.format("La party de %s se llenó (máximo %d personas). Tu invitación se canceló.", leader and leader:getName() or "", Mubia.PartyConfig.maxMembers))
	end
end

-- Nivel máximo: devuelve la experiencia que de verdad puede ganar (0 si ya está en el tope).
local maxLevelWarned = {}

function Mubia.capExperience(player, exp)
	local maxLevel = Mubia.Config and Mubia.Config.maxLevel or 0
	if maxLevel <= 0 or not exp or exp <= 0 then
		return exp
	end
	local room = Game.getExperienceForLevel(maxLevel) - player:getExperience()
	if room > 0 then
		return math.min(exp, room)
	end
	local id = player:getId()
	local now = os.time()
	if not maxLevelWarned[id] or now - maxLevelWarned[id] >= Mubia.PartyConfig.maxLevelMessageDelay then
		maxLevelWarned[id] = now
		Mubia.sendMessage(player, MESSAGE_STATUS, string.format("Llegaste al nivel máximo (%d). Haz reset para seguir subiendo.", maxLevel))
	end
	return 0
end
