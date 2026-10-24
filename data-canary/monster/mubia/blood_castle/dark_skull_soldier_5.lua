-- Mubia Online: Dark Skull Soldier 5 (Blood Castle 5, nivel 80). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Dark Skull Soldier 5")
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
	level = 80,
	health = 19000,
	damage = { 280, 340 },
	defense = 220,
	attackRate = 470,
	defenseRate = 175,
	attackSpeed = 2000,
	speed = 220,
	corpse = 5962,
})
