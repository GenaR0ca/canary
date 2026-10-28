-- Mubia Online: Forest Orc (Aida 1, nivel 64). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Forest Orc")
local monster = {}

monster.outfit = {
	lookType = 8,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 64,
	health = 6500,
	damage = { 230, 250 },
	defense = 150,
	speed = 200,
	corpse = 5980,
})
