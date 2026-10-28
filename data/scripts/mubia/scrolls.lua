-- Mubia Online: scrolls que enseñan las magias MU. Cada clase solo puede usar los suyos.

local scrollAction = Action()

function scrollAction.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local spell = Mubia.SpellByScroll[item:getId()]
	if not spell then
		return false
	end

	local class = Mubia.getClass(player)
	local spellClass = Mubia.Classes[spell.classId]
	if not class or class ~= spellClass then
		Mubia.sendMessage(player, MESSAGE_FAILURE, string.format("Solo un %s puede aprender %s.", spellClass.name, spell.name))
		player:getPosition():sendMagicEffect(CONST_ME_POFF)
		return true
	end

	if spell.evolution and not Mubia.isEvolved(player) then
		Mubia.sendMessage(player, MESSAGE_FAILURE, string.format("%s es una magia de la segunda evolución (%s). Habla con Sebina the Priest en Devias.", spell.name, Mubia.getEvolutionName(player)))
		player:getPosition():sendMagicEffect(CONST_ME_POFF)
		return true
	end

	if player:getLevel() < spell.level then
		Mubia.sendMessage(player, MESSAGE_FAILURE, string.format("Necesitas nivel %d para aprender %s.", spell.level, spell.name))
		player:getPosition():sendMagicEffect(CONST_ME_POFF)
		return true
	end

	if player:hasLearnedSpell(spell.name) then
		Mubia.sendMessage(player, MESSAGE_FAILURE, string.format("Ya conoces la magia %s.", spell.name))
		return true
	end

	player:learnSpell(spell.name)
	item:remove(1)
	player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
	Mubia.sendMessage(player, MESSAGE_EVENT_ADVANCE, string.format("Has aprendido %s. Para usarla escribe: %s", spell.name, spell.words))
	return true
end

for _, def in ipairs(Mubia.SpellList) do
	scrollAction:id(def.scrollId)
end
scrollAction:register()

-- Los personajes de prueba llevan el nombre de su clase MU (para bases de datos ya creadas)
local renameSamples = GlobalEvent("MubiaRenameSamples")

function renameSamples.onStartup()
	local names = {
		["Knight Sample"] = "Dark Knight Sample",
		["Sorcerer Sample"] = "Dark Wizard Sample",
		["Paladin Sample"] = "Fairy Elf Sample",
	}
	for oldName, newName in pairs(names) do
		db.query(string.format("UPDATE `players` SET `name` = %s WHERE `name` = %s AND NOT EXISTS (SELECT 1 FROM (SELECT `id` FROM `players` WHERE `name` = %s) AS taken)", db.escapeString(newName), db.escapeString(oldName), db.escapeString(newName)))
	end
	return true
end

renameSamples:register()
