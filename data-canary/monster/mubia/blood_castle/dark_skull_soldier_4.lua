-- Mubia Online: Dark Skull Soldier 4 (Blood Castle 4, nivel 75). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Dark Skull Soldier 4")
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
	level = 75,
	health = 12000,
	damage = { 220, 260 },
	defense = 190,
	attackRate = 440,
	defenseRate = 130,
	attackSpeed = 2000,
	speed = 220,
	corpse = 5962,
})
