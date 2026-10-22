-- Mubia Online: Lich (Lorencia, nivel 14). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Lich")
local monster = {}

monster.outfit = {
	lookType = 99,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 14,
	health = 255,
	damage = { 41, 46 },
	defense = 14,
	speed = 190,
	corpse = 6028,
	magic = true,
})
