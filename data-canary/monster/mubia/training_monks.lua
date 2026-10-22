-- Mubia Online: Training Monks de la zona de entrenamiento (Montag). Son inmortales:
-- reciben el daño (se ven los números) y se curan enseguida. Aparecen en canary-monster.xml.

local MONKS = {
	-- quieto en su lugar
	{ name = "Training Monk", speed = 0, lookHead = 0, lookBody = 94, lookLegs = 94, lookFeet = 0 },
	-- camina despacio cerca de donde aparece
	{ name = "Walking Training Monk", speed = 60, lookHead = 0, lookBody = 86, lookLegs = 86, lookFeet = 0, leash = 3 },
}

for _, config in ipairs(MONKS) do
	local mType = Game.createMonsterType(config.name)
	local monster = {}

	monster.description = "a training monk"
	monster.experience = 0
	monster.outfit = {
		lookType = 1825,
		lookHead = config.lookHead,
		lookBody = config.lookBody,
		lookLegs = config.lookLegs,
		lookFeet = config.lookFeet,
		lookAddons = 0,
		lookMount = 0,
	}

	monster.health = 10000000
	monster.maxHealth = monster.health
	monster.race = "blood"
	monster.corpse = 0
	monster.speed = config.speed
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
		if config.leash then
			local id = creature:getId()
			homes[id] = homes[id] or creature:getPosition()
			if creature:getPosition():getDistance(homes[id]) > config.leash then
				creature:teleportTo(homes[id], true)
			end
		end
	end

	mType:register(monster)
end
