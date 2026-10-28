-- Mubia Online: Witch Queen (Aida 2, nivel 84). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Witch Queen")
local monster = {}

monster.outfit = {
	lookType = 54,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 84,
	health = 22500,
	damage = { 380, 410 },
	defense = 275,
	speed = 200,
	corpse = 18254,
	magic = true,
})
