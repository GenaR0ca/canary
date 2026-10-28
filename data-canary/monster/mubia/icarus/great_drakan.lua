-- Mubia Online: Great Drakan (Icarus, las plataformas más lejanas, nivel 100). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Great Drakan")
local monster = {}

monster.outfit = {
	lookType = 357,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 100,
	health = 50000,
	damage = { 650, 700 },
	defense = 495,
	speed = 200,
	corpse = 5995,
})
