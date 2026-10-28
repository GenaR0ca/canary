-- Mubia Online: Dark Skull Soldier 7 (Blood Castle 7, nivel 90). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Dark Skull Soldier 7")
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
	level = 90,
	health = 32000,
	damage = { 430, 480 },
	defense = 400,
	attackRate = 660,
	defenseRate = 230,
	attackSpeed = 2000,
	speed = 220,
	corpse = 5962,
})
