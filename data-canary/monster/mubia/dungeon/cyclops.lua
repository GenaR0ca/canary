-- Mubia Online: Cyclops (Dungeon, nivel 28). Usa el dibujo del cíclope de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Cyclops")
local monster = {}

monster.outfit = {
	lookType = 22,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 28,
	health = 850,
	damage = { 100, 105 },
	defense = 35,
	speed = 200,
	corpse = 5962,
})
