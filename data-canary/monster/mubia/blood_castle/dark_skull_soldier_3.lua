-- Mubia Online: Dark Skull Soldier 3 (Blood Castle 3, nivel 66). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Dark Skull Soldier 3")
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
	level = 66,
	health = 8000,
	damage = { 190, 220 },
	defense = 150,
	attackRate = 360,
	defenseRate = 98,
	attackSpeed = 2000,
	speed = 220,
	corpse = 5962,
})
