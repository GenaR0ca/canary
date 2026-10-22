-- Mubia Online: teleports del templo de Strongarm a la zona de NPCs (Nahag Village)
-- y a la zona de entrenamiento (Montag), cada uno con su teleport de vuelta.
-- Se crean al arrancar el servidor (no se guardan en el mapa).

local TEMPLE = Position(1943, 1345, 7)

Mubia.Teleports = {
	{ position = Position(1943, 1349, 7), destination = Position(4804, 5088, 7), description = "Teleport a la zona de NPCs." },
	{ position = Position(1945, 1349, 7), destination = Position(5008, 5004, 7), description = "Teleport a la zona de entrenamiento." },
	{ position = Position(4804, 5086, 7), destination = TEMPLE, description = "Teleport de vuelta al templo." },
	{ position = Position(5006, 5003, 7), destination = TEMPLE, description = "Teleport de vuelta al templo." },
}

local TELEPORT_ITEM = 1949 -- magic forcefield

local createTeleports = GlobalEvent("MubiaTeleports")

function createTeleports.onStartup()
	for _, config in ipairs(Mubia.Teleports) do
		local item = Game.createItem(TELEPORT_ITEM, 1, config.position)
		if item and item:isTeleport() then
			item:setDestination(config.destination)
			item:setAttribute(ITEM_ATTRIBUTE_DESCRIPTION, config.description)
		else
			logger.error("[MubiaTeleports] No se pudo crear el teleport en {}", config.position:toString())
		end
	end
	return true
end

createTeleports:register()
