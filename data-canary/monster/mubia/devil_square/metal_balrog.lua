-- Mubia Online: Metal Balrog (Devil Square, nivel 77). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Metal Balrog")
local monster = {}

monster.outfit = {
	lookType = 244,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 77,
	health = 26000,
	damage = { 300, 360 },
	defense = 220,
	speed = 220,
	corpse = 6040,
})
