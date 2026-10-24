-- Mubia Online: Dark Skull Soldier 8 (Blood Castle 8, nivel 101). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Dark Skull Soldier 8")
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
	level = 101,
	health = 81700,
	damage = { 580, 640 },
	defense = 475,
	attackRate = 730,
	defenseRate = 321,
	attackSpeed = 2000,
	speed = 220,
	corpse = 5962,
})
