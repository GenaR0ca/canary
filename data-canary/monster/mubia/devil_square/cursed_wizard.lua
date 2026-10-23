-- Mubia Online: Cursed Wizard (Devil Square, nivel 54). Usa un dibujo de Tibia hasta tener sprite propio.

local mType = Game.createMonsterType("Cursed Wizard")
local monster = {}

monster.outfit = {
	lookType = 130,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerWildMonster(mType, monster, {
	level = 54,
	health = 4000,
	damage = { 160, 170 },
	defense = 95,
	speed = 220,
	corpse = 6040,
	magic = true,
})
