-- Mubia Online: Skeleton Warrior (Lorencia, nivel 19). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Skeleton Warrior")
local monster = {}

monster.outfit = {
	lookType = 298,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 19,
	health = 525,
	damage = { 68, 74 },
	defense = 22,
	speed = 200,
	corpse = 5972,
})
