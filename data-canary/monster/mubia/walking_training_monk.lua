-- Mubia Online: Walking Training Monk de la zona de entrenamiento, camina despacio cerca de donde aparece. Inmortal.

local mType = Game.createMonsterType("Walking Training Monk")
local monster = {}

monster.outfit = {
	lookType = 1825,
	lookHead = 0,
	lookBody = 86,
	lookLegs = 86,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

Mubia.registerTrainingMonk(mType, monster, {
	speed = 60,
	leash = 3,
})
