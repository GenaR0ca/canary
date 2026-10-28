-- Mubia Online: armado común de monstruos y NPCs. Cada criatura tiene su propio archivo
-- (con Game.createMonsterType("Nombre") y monster.outfit) para que el editor de mapas la reconozca.

-- Monstruo salvaje de MU (Lorencia, Noria, etc.). cfg: speed, corpse, magic (ataca con magia a distancia)
-- o ranged (dispara flechas a distancia). Nivel, vida, daño y defensa salen del Monster.txt de MU
-- (Mubia.MonsterStats); los de cfg (level, health, damage = {min, max}, defense) solo se usan si el
-- monstruo no está en Monster.txt o si pones custom = true.
function Mubia.registerWildMonster(mType, monster, cfg)
	local mu = Mubia.getMonsterMuStats(mType:name(), cfg)
	Mubia.WildMonsters[mType:name()] = mu

	monster.description = monster.description or ("a " .. mType:name():lower())
	monster.experience = Mubia.getMonsterBaseExp(mu.level)
	monster.health = mu.hp
	monster.maxHealth = mu.hp
	monster.race = "blood"
	monster.corpse = cfg.corpse
	monster.speed = cfg.speed
	monster.manaCost = 0

	monster.changeTarget = {
		interval = 4000,
		chance = 10,
	}

	monster.strategiesTarget = {
		nearest = 100,
	}

	monster.flags = {
		summonable = false,
		attackable = true,
		hostile = true,
		convinceable = false,
		pushable = false,
		rewardBoss = false,
		illusionable = false,
		canPushItems = true,
		canPushCreatures = false,
		staticAttackChance = 90,
		targetDistance = (cfg.magic or cfg.ranged) and 4 or 1,
		runHealth = 0,
		healthHidden = false,
		isBlockable = false,
		canWalkOnEnergy = false,
		canWalkOnFire = false,
		canWalkOnPoison = false,
	}

	monster.light = {
		level = 0,
		color = 0,
	}

	-- zen (gold coin) como en MU
	monster.loot = {
		{ id = 3031, chance = 60000, maxCount = mu.level * 5 },
	}

	if cfg.magic then
		monster.attacks = {
			{ name = "combat", interval = mu.attackSpeed, chance = 100, type = COMBAT_ENERGYDAMAGE, minDamage = -mu.minDamage, maxDamage = -mu.maxDamage, range = 5, shootEffect = CONST_ANI_ENERGY, effect = CONST_ME_ENERGYHIT, target = true },
		}
	elseif cfg.ranged then
		monster.attacks = {
			{ name = "combat", interval = mu.attackSpeed, chance = 100, type = COMBAT_PHYSICALDAMAGE, minDamage = -mu.minDamage, maxDamage = -mu.maxDamage, range = 5, shootEffect = CONST_ANI_ARROW, target = true },
		}
	else
		monster.attacks = {
			{ name = "melee", interval = mu.attackSpeed, chance = 100, minDamage = -mu.minDamage, maxDamage = -mu.maxDamage },
		}
	end

	-- la defensa y el bloqueo de MU se aplican en Mubia.modifyDamage (mubia_monsters.lua), no los de Tibia
	monster.defenses = {
		defense = 0,
		armor = 0,
	}

	monster.elements = {}
	monster.immunities = {}

	mType:register(monster)
end

-- Invocación de la Fairy Elf: no da experiencia ni loot. cfg: health, damage = {min, max}, defense, speed
function Mubia.registerSummon(mType, monster, cfg)
	monster.description = "a " .. mType:name():lower()
	monster.experience = 0
	monster.health = cfg.health
	monster.maxHealth = cfg.health
	monster.race = "blood"
	monster.corpse = 0
	monster.speed = cfg.speed
	monster.manaCost = 0

	monster.changeTarget = {
		interval = 4000,
		chance = 0,
	}

	monster.strategiesTarget = {
		nearest = 100,
	}

	monster.flags = {
		summonable = true,
		attackable = true,
		hostile = true,
		convinceable = false,
		pushable = false,
		rewardBoss = false,
		illusionable = false,
		canPushItems = true,
		canPushCreatures = false,
		staticAttackChance = 90,
		targetDistance = 1,
		runHealth = 0,
		healthHidden = false,
		isBlockable = false,
		canWalkOnEnergy = true,
		canWalkOnFire = true,
		canWalkOnPoison = true,
	}

	monster.light = {
		level = 0,
		color = 0,
	}

	monster.loot = {}

	monster.attacks = {
		{ name = "melee", interval = 2000, chance = 100, minDamage = -cfg.damage[1], maxDamage = -cfg.damage[2] },
	}

	monster.defenses = {
		defense = cfg.defense,
		armor = cfg.defense,
	}

	monster.elements = {}
	monster.immunities = {}

	mType:register(monster)
end

-- Mascota de MU que sigue a su dueño (Guardian Angel, Imp, Dark Raven...). Es un "familiar":
-- entra a las zonas seguras, se teletransporta con el dueño y nadie la puede atacar.
-- cfg: damage = {min, max} solo si ataca al objetivo del dueño (Dark Raven)
function Mubia.registerPet(mType, monster, cfg)
	monster.description = "una mascota"
	monster.experience = 0
	monster.health = 1000
	monster.maxHealth = 1000
	monster.race = "undead"
	monster.corpse = 0
	monster.speed = 400
	monster.manaCost = 0

	monster.changeTarget = {
		interval = 4000,
		chance = 0,
	}

	monster.strategiesTarget = {
		nearest = 100,
	}

	monster.flags = {
		summonable = false,
		attackable = false,
		hostile = cfg.damage ~= nil,
		convinceable = false,
		pushable = false,
		familiar = true,
		rewardBoss = false,
		illusionable = false,
		canPushItems = false,
		canPushCreatures = false,
		staticAttackChance = 90,
		targetDistance = 1,
		runHealth = 0,
		healthHidden = true,
		isBlockable = false,
		canWalkOnEnergy = true,
		canWalkOnFire = true,
		canWalkOnPoison = true,
	}

	monster.light = {
		level = 0,
		color = 0,
	}

	monster.loot = {}
	monster.attacks = {}
	if cfg.damage then
		monster.attacks[1] = { name = "melee", interval = 1500, chance = 100, minDamage = -cfg.damage[1], maxDamage = -cfg.damage[2] }
	end

	monster.defenses = {
		defense = 0,
		armor = 0,
	}

	monster.elements = {}
	monster.immunities = {}

	mType:register(monster)
end

-- Training Monk inmortal: recibe el daño (se ven los números) y se cura enseguida.
-- cfg: speed, leash (opcional: casillas máximas que se aleja de donde apareció)
function Mubia.registerTrainingMonk(mType, monster, cfg)
	monster.description = "a training monk"
	monster.experience = 0
	monster.health = 10000000
	monster.maxHealth = monster.health
	monster.race = "blood"
	monster.corpse = 0
	monster.speed = cfg.speed
	monster.manaCost = 0

	monster.changeTarget = {
		interval = 4000,
		chance = 0,
	}

	monster.strategiesTarget = {
		nearest = 100,
	}

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
		staticAttackChance = 90,
		targetDistance = 1,
		runHealth = 0,
		healthHidden = false,
		isBlockable = false,
		canWalkOnEnergy = true,
		canWalkOnFire = true,
		canWalkOnPoison = true,
	}

	monster.light = {
		level = 0,
		color = 0,
	}

	monster.loot = {}
	monster.attacks = {}
	monster.defenses = {
		defense = 0,
		armor = 0,
	}
	monster.elements = {}
	monster.immunities = {}

	local homes = {}

	mType.onThink = function(creature, interval)
		-- inmortal: vuelve a vida completa
		local missing = creature:getMaxHealth() - creature:getHealth()
		if missing > 0 then
			creature:addHealth(missing)
		end
		-- el que camina no se aleja más de "leash" casillas de donde apareció
		if cfg.leash then
			local id = creature:getId()
			homes[id] = homes[id] or creature:getPosition()
			if creature:getPosition():getDistance(homes[id]) > cfg.leash then
				creature:teleportTo(homes[id], true)
			end
		end
	end

	mType:register(monster)
end

-- NPC de la zona de NPCs: vende gratis los scrolls de su clase (classId) o lo que diga shop.
-- Opcionales: greeting y voice (textos propios del NPC).
-- Di "magias" para recibir todos los scrolls de la clase de una vez.
Mubia.NpcPotions = {
	{ itemName = "health potion", clientId = 266, buy = 0 },
	{ itemName = "strong health potion", clientId = 236, buy = 0 },
	{ itemName = "great health potion", clientId = 239, buy = 0 },
	{ itemName = "mana potion", clientId = 268, buy = 0 },
	{ itemName = "strong mana potion", clientId = 237, buy = 0 },
	{ itemName = "great mana potion", clientId = 238, buy = 0 },
}

function Mubia.registerShopNpc(npcType, npcConfig, config)
	npcConfig.name = npcType:name()
	npcConfig.description = npcConfig.name
	npcConfig.health = 100
	npcConfig.maxHealth = npcConfig.health
	npcConfig.walkInterval = 0
	npcConfig.walkRadius = 0
	npcConfig.flags = { floorchange = false }

	local spells = config.classId and Mubia.getClassSpells(config.classId) or {}
	local className = config.classId and Mubia.Classes[config.classId].name

	npcConfig.shop = config.shop or {}
	for _, def in ipairs(spells) do
		table.insert(npcConfig.shop, { itemName = def.scrollName, clientId = def.scrollId, buy = 0 })
	end
	-- sets, armas y escudos de MU de la clase (gratis para probar)
	if config.classId then
		local gearIds = {}
		for itemId, gear in pairs(Mubia.Gear) do
			if table.contains(gear.classes, config.classId) then
				gearIds[#gearIds + 1] = itemId
			end
		end
		table.sort(gearIds)
		for _, itemId in ipairs(gearIds) do
			table.insert(npcConfig.shop, { itemName = Mubia.Gear[itemId].name:lower(), clientId = itemId, buy = 0 })
		end
	end

	local voice = config.voice
	if not voice then
		voice = className and string.format("¡Scrolls de magias y equipo de %s gratis! Di {trade}.", className) or "¡Pociones de vida y de mana gratis! Di {trade}."
	end
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

	npcType.onBuyItem = function(npc, player, itemId, subType, amount, ignore, inBackpacks, totalCost)
		npc:sellItem(player, itemId, amount, subType, 0, ignore, inBackpacks)
	end

	npcType.onSellItem = function(npc, player, itemId, subtype, amount, ignore, name, totalCost) end

	npcType.onCheckItem = function(npc, player, clientId, subType) end

	-- Di "magias" para recibir todos los scrolls de la clase de una vez
	local function giveScrolls(npc, player)
		local names = {}
		for _, def in ipairs(spells) do
			if not player:addItem(def.scrollId, 1) then
				npcHandler:say(Mubia.toLatin1("No tienes espacio o capacidad para más items."), npc, player)
				break
			end
			names[#names + 1] = def.name
		end
		if #names > 0 then
			player:getPosition():sendMagicEffect(CONST_ME_GIFT_WRAPS)
			npcHandler:say(Mubia.toLatin1("Aquí tienes los scrolls de: " .. table.concat(names, ", ") .. "."), npc, player)
		end
	end

	local greeting = config.greeting
	if not greeting and className then
		greeting = string.format("¡Hola |PLAYERNAME|! Enseño las magias de %s. Di {trade} para elegir scrolls gratis o {magias} para llevarte todos.", className)
	elseif not greeting then
		greeting = "¡Hola |PLAYERNAME|! Di {trade} para llevarte pociones de vida y de mana gratis."
	end

	npcHandler:setCallback(CALLBACK_GREET, function(npc, player)
		npcHandler:setMessage(MESSAGE_GREET, Mubia.toLatin1(greeting))
		if config.onGreet then
			config.onGreet(npc, player)
		end
		return true
	end)

	npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, function(npc, player, type, msg)
		if not npcHandler:checkInteraction(npc, player) then
			return false
		end
		if className and (MsgContains(msg, "magias") or MsgContains(msg, "scrolls")) then
			giveScrolls(npc, player)
		end
		-- palabras propias del NPC (ej. "chaos" en el Chaos Goblin)
		for keyword, callback in pairs(config.keywords or {}) do
			if MsgContains(msg, keyword) then
				callback(npc, player)
				break
			end
		end
		return true
	end)

	npcHandler:setMessage(MESSAGE_FAREWELL, Mubia.toLatin1("¡Suerte en tu aventura!"))
	npcHandler:setMessage(MESSAGE_WALKAWAY, Mubia.toLatin1("¡Vuelve cuando quieras!"))
	npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

	npcType:register(npcConfig)
end
