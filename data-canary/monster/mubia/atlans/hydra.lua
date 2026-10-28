-- Mubia Online: Hydra (Atlans 3, nivel 74). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Hydra")
local monster = {}

monster.outfit = {
	lookType = 121,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 74,
	health = 19000,
	damage = { 250, 310 },
	defense = 200,
	speed = 200,
	corpse = 6048,
	magic = true,
})
