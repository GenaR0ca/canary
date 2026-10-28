-- Mubia Online: Budge Dragon (Lorencia, nivel 4). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Budge Dragon")
local monster = {}

monster.outfit = {
	lookType = 271,
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
	level = 4,
	health = 60,
	damage = { 10, 15 },
	defense = 3,
	speed = 190,
	corpse = 269,
})
