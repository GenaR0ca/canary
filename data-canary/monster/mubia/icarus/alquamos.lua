-- Mubia Online: Alquamos (Icarus, cerca de la zona segura, nivel 75). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Alquamos")
local monster = {}

monster.outfit = {
	lookType = 95,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 75,
	health = 11500,
	damage = { 255, 290 },
	defense = 195,
	speed = 200,
	corpse = 5995,
})
