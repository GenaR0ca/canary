-- Mubia Online: Training Monk de la zona de entrenamiento, quieto en su lugar. Inmortal.

local mType = Game.createMonsterType("Training Monk")
local monster = {}

monster.outfit = {
	lookType = 1825,
	lookHead = 0,
	lookBody = 94,
	lookLegs = 94,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerTrainingMonk(mType, monster, {
	speed = 0,
})
