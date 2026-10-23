-- Mubia Online: Balram (Trainee) (Devil Square, nivel 117). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Balram (Trainee)")
local monster = {}

monster.outfit = {
	lookType = 246,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 117,
	health = 37000,
	damage = { 560, 600 },
	defense = 460,
	speed = 220,
	corpse = 6040,
})
