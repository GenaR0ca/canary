-- Mubia Online: Thunder Lich (Devil Square, nivel 44). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Thunder Lich")
local monster = {}

monster.outfit = {
	lookType = 99,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 44,
	health = 2000,
	damage = { 140, 145 },
	defense = 70,
	speed = 220,
	corpse = 6040,
	magic = true,
})
