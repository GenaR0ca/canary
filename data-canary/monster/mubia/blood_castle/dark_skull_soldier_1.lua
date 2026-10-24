-- Mubia Online: Dark Skull Soldier 1 (Blood Castle 1, nivel 41). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Dark Skull Soldier 1")
local monster = {}

monster.outfit = {
	lookType = 37,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 41,
	health = 1700,
	damage = { 120, 140 },
	defense = 75,
	attackRate = 230,
	defenseRate = 61,
	attackSpeed = 2000,
	speed = 220,
	corpse = 5962,
})
