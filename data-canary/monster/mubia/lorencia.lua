-- Mubia Online: monstruos de Lorencia (MU Season 6). Usan dibujos de Tibia hasta tener sprites propios.

local MONSTERS = {
	{ name = "Spider", corpse = 5961, level = 2, lookType = 30, health = 30, damage = { 4, 7 }, defense = 1, speed = 180 },
	{ name = "Budge Dragon", corpse = 269, level = 4, lookType = 271, health = 60, damage = { 10, 15 }, defense = 3, speed = 190 },
	{ name = "Bull Fighter", corpse = 5969, level = 6, lookType = 25, health = 100, damage = { 16, 20 }, defense = 6, speed = 190 },
	{ name = "Hound", corpse = 6009, level = 9, lookType = 3, health = 140, damage = { 22, 27 }, defense = 9, speed = 220 },
	{ name = "Elite Bull Fighter", corpse = 5983, level = 12, lookType = 29, health = 190, damage = { 31, 36 }, defense = 12, speed = 200 },
	{ name = "Lich", corpse = 6028, level = 14, lookType = 99, health = 255, damage = { 41, 46 }, defense = 14, speed = 190, magic = true },
	{ name = "Giant", corpse = 5962, level = 17, lookType = 22, health = 400, damage = { 57, 62 }, defense = 18, speed = 180 },
	{ name = "Skeleton Warrior", corpse = 5972, level = 19, lookType = 298, health = 525, damage = { 68, 74 }, defense = 22, speed = 200 },
}

for _, config in ipairs(MONSTERS) do
	local mType = Game.createMonsterType(config.name)
	local monster = {}

	monster.description = "a " .. config.name:lower()
	monster.experience = config.level * 3
	monster.outfit = {
		lookType = config.lookType,
		lookHead = 0,
		lookBody = 0,
		lookLegs = 0,
		lookFeet = 0,
		lookAddons = 0,
		lookMount = 0,
	}

	monster.health = config.health
	monster.maxHealth = config.health
	monster.race = "blood"
	monster.corpse = config.corpse
	monster.speed = config.speed
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
		targetDistance = config.magic and 4 or 1,
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
		{ id = 3031, chance = 60000, maxCount = config.level * 5 },
	}

	if config.magic then
		monster.attacks = {
			{ name = "combat", interval = 2000, chance = 100, type = COMBAT_ENERGYDAMAGE, minDamage = -config.damage[1], maxDamage = -config.damage[2], range = 5, shootEffect = CONST_ANI_ENERGY, effect = CONST_ME_ENERGYHIT, target = true },
		}
	else
		monster.attacks = {
			{ name = "melee", interval = 2000, chance = 100, minDamage = -config.damage[1], maxDamage = -config.damage[2] },
		}
	end

	monster.defenses = {
		defense = config.defense,
		armor = config.defense,
	}

	monster.elements = {}
	monster.immunities = {}

	mType:register(monster)
end
