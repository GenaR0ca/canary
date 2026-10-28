-- Mubia Online: Soram (Trainee) (Devil Square, nivel 119). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Soram (Trainee)")
local monster = {}

monster.outfit = {
	lookType = 237,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 119,
	health = 40000,
	damage = { 610, 650 },
	defense = 510,
	speed = 220,
	corpse = 6040,
	magic = true,
})
