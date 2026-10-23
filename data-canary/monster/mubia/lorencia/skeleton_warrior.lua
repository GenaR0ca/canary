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

-- Nivel, vida, daño y defensa reales salen del Monster.txt de MU (data/libs/systems/mubia_monster_stats.lua).
-- Los números de abajo solo se usan si pones custom = true.
Mubia.registerWildMonster(mType, monster, {
	level = 19,
	health = 525,
	damage = { 68, 74 },
	defense = 22,
	speed = 200,
	corpse = 5972,
})
