-- Mubia Online: Statue of Saint (Blood Castle). Guarda el arma del Archangel: al romperla, el arma queda en el altar.
-- La vida depende del castillo (Mubia.BloodCastle.statueHealth) y se pone al aparecer.

local mType = Game.createMonsterType("Statue of Saint")
local monster = {}

monster.outfit = {
	lookTypeEx = 2031,
}

Mubia.BloodCastle.registerObject(mType, monster, { health = 3000, corpse = 0 })
