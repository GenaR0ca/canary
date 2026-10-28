-- Mubia Online: Dark Skull Soldier 6 (Blood Castle 6, nivel 86). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Dark Skull Soldier 6")
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
	level = 86,
	health = 25000,
	damage = { 390, 420 },
	defense = 360,
	attackRate = 580,
	defenseRate = 195,
	attackSpeed = 2000,
	speed = 220,
	corpse = 5962,
})
