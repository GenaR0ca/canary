-- Mubia Online: Hunter (Noria, nivel 13). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Hunter")
local monster = {}

monster.outfit = {
	lookType = 129,
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
	level = 13,
	health = 220,
	damage = { 36, 41 },
	defense = 15,
	speed = 200,
	corpse = 18138,
	ranged = true,
})
