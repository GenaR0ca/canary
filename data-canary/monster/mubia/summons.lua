-- Mubia Online: invocaciones de la Fairy Elf (magias Summon ...). No dan experiencia ni loot.

local SUMMONS = {
	{ name = "Summoned Goblin", lookType = 61, health = 80, defense = 3, damage = { 15, 20 }, speed = 180 },
	{ name = "Summoned Stone Golem", lookType = 67, health = 300, defense = 10, damage = { 40, 50 }, speed = 160 },
	{ name = "Summoned Assassin", lookType = 152, look = { 95, 95, 95, 95 }, health = 450, defense = 15, damage = { 60, 75 }, speed = 220 },
	{ name = "Summoned Elite Yeti", lookType = 110, health = 700, defense = 22, damage = { 80, 95 }, speed = 200 },
	{ name = "Summoned Dark Knight", lookType = 131, look = { 95, 114, 114, 95 }, health = 1200, defense = 30, damage = { 120, 140 }, speed = 220 },
	{ name = "Summoned Bali", lookType = 55, health = 3000, defense = 45, damage = { 170, 190 }, speed = 200 },
	{ name = "Summoned Soldier", lookType = 71, health = 4500, defense = 60, damage = { 220, 250 }, speed = 220 },
}

for _, config in ipairs(SUMMONS) do
	local mType = Game.createMonsterType(config.name)
	local monster = {}
	local look = config.look or { 0, 0, 0, 0 }

	monster.description = "a " .. config.name:lower()
	monster.experience = 0
	monster.outfit = {
		lookType = config.lookType,
		lookHead = look[1],
		lookBody = look[2],
		lookLegs = look[3],
		lookFeet = look[4],
		lookAddons = 0,
		lookMount = 0,
	}

	monster.health = config.health
	monster.maxHealth = config.health
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
		{ name = "melee", interval = 2000, chance = 100, minDamage = -config.damage[1], maxDamage = -config.damage[2] },
	}

	monster.defenses = {
		defense = config.defense,
		armor = config.defense,
	}

	monster.elements = {}
	monster.immunities = {}

	mType:register(monster)
end
