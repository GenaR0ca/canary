-- Mubia Online: Elite Bull Fighter (Lorencia, nivel 12). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Elite Bull Fighter")
local monster = {}

monster.outfit = {
	lookType = 29,
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
	level = 12,
	health = 190,
	damage = { 31, 36 },
	defense = 12,
	speed = 200,
	corpse = 5983,
})
