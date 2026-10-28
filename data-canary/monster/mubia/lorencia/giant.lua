-- Mubia Online: Giant (Lorencia, nivel 17). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Giant")
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

-- Nivel, vida, daño y defensa reales salen del Monster.txt de MU (data/libs/systems/mubia_monster_stats.lua).
-- Los números de abajo solo se usan si pones custom = true.
Mubia.registerWildMonster(mType, monster, {
	level = 17,
	health = 400,
	damage = { 57, 62 },
	defense = 18,
	speed = 180,
	corpse = 5962,
})
