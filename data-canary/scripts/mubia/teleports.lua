-- Mubia Online: teleports del templo de Strongarm a la zona de NPCs (Nahag Village)
-- a la zona de entrenamiento (Montag), a Lorencia, a Noria y a Devias. Todos menos Devias tienen teleport de vuelta
-- (desde Devias se vuelve con el menú de ciudades, tecla M). También el vórtice de Atlans a Tarkan, el de Tarkan a Atlans 3
-- y el de Icarus a Lost Tower 7 (la entrada a Icarus, que pide alas, está en icarus.lua).
-- Se crean al arrancar el servidor (no se guardan en el mapa). Va en data-canary porque usa el mapa canary.otbm.

local TEMPLE = Position(1943, 1345, 7)

Mubia.Teleports = {
	{ position = Position(1943, 1349, 7), destination = Position(4804, 5088, 7), description = "Teleport a la zona de NPCs." },
	{ position = Position(1945, 1349, 7), destination = Position(5008, 5004, 7), description = "Teleport a la zona de entrenamiento." },
	{ position = Position(1944, 1349, 7), destination = Position(927, 654, 7), description = "Teleport a Lorencia." },
	{ position = Position(1946, 1349, 7), destination = Position(1257, 720, 7), description = "Teleport a Noria." },
	{ position = Position(1942, 1349, 7), destination = Position(1587, 739, 7), description = "Teleport a Devias." },
	{ position = Position(4804, 5086, 7), destination = TEMPLE, description = "Teleport de vuelta al templo." },
	{ position = Position(924, 653, 7), destination = TEMPLE, description = "Teleport de vuelta al templo de Strongarm." },
	{ position = Position(1253, 722, 7), destination = TEMPLE, description = "Teleport de vuelta al templo de Strongarm." },
	{ position = Position(5006, 5003, 7), destination = TEMPLE, description = "Teleport de vuelta al templo." },
	{ position = Position(947, 628, 8), destination = Position(927, 654, 7), description = "Salida de Dungeon a Lorencia." },
	{ position = Position(1529, 1057, 7), destination = Position(1634, 1205, 7), description = "Vórtice a Tarkan.", replaces = 9158 },
	{ position = Position(1612, 1254, 7), destination = Position(1462, 1107, 7), description = "Teleport a Atlans 3." },
	{ position = Position(2223, 1259, 7), destination = Position(1032, 1665, 8), description = "Teleport de vuelta a Lost Tower 7." },
}

local TELEPORT_ITEM = 1949 -- magic forcefield

local createTeleports = GlobalEvent("MubiaTeleports")

function createTeleports.onStartup()
	for _, config in ipairs(Mubia.Teleports) do
		if config.replaces then
			-- quita la decoración que marcaba el lugar (por ejemplo el vórtice de Atlans), porque no se puede pisar
			local tile = Tile(config.position)
			local old = tile and tile:getItemById(config.replaces)
			if old then
				old:remove()
			end
		end
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
