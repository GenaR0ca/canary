-- Mubia Online: Chain Scorpion (Noria, nivel 5). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Chain Scorpion")
local monster = {}

monster.outfit = {
	lookType = 43,
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
	level = 5,
	health = 80,
	damage = { 12, 15 },
	defense = 5,
	speed = 190,
	corpse = 5988,
})
