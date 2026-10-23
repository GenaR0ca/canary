-- Mubia Online: Hound (Lorencia, nivel 9). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Hound")
local monster = {}

monster.outfit = {
	lookType = 3,
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
	level = 9,
	health = 140,
	damage = { 22, 27 },
	defense = 9,
	speed = 220,
	corpse = 6009,
})
