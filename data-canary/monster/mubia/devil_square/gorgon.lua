-- Mubia Online: Gorgon (Devil Square, nivel 55). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Gorgon")
local monster = {}

monster.outfit = {
	lookType = 330,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 55,
	health = 6000,
	damage = { 165, 175 },
	defense = 100,
	speed = 220,
	corpse = 6040,
})
