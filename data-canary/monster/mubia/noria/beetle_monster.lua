-- Mubia Online: Beetle Monster (Noria, nivel 10). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Beetle Monster")
local monster = {}

monster.outfit = {
	lookType = 45,
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
	level = 10,
	health = 165,
	damage = { 26, 31 },
	defense = 11,
	speed = 190,
	corpse = 5990,
})
