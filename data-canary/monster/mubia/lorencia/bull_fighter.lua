-- Mubia Online: Bull Fighter (Lorencia, nivel 6). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Bull Fighter")
local monster = {}

monster.outfit = {
	lookType = 25,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 6,
	health = 100,
	damage = { 16, 20 },
	defense = 6,
	speed = 190,
	corpse = 5969,
})
