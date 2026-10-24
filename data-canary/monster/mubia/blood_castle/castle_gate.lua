-- Mubia Online: Castle Gate (Blood Castle). La puerta del castillo: no camina ni ataca, solo hay que romperla.
-- La vida depende del castillo (Mubia.BloodCastle.gateHealth) y se pone al aparecer.

local mType = Game.createMonsterType("Castle Gate")
local monster = {}

monster.outfit = {
	lookTypeEx = 1632,
}

Mubia.BloodCastle.registerObject(mType, monster, { health = 2000, corpse = 0 })
