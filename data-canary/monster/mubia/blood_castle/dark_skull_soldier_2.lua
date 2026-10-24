-- Mubia Online: Dark Skull Soldier 2 (Blood Castle 2, nivel 56). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Dark Skull Soldier 2")
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
	level = 56,
	health = 5000,
	damage = { 160, 190 },
	defense = 115,
	attackRate = 300,
	defenseRate = 88,
	attackSpeed = 2000,
	speed = 220,
	corpse = 5962,
})
