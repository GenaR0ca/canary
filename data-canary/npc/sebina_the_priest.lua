-- Mubia Online: Sebina the Priest (Devias). Da la misión de la segunda evolución desde nivel 150
-- (Blade Knight, Soul Master, Muse Elf). Al hacerle clic se abre su ventana (data/scripts/mubia/sebina.lua).

local npcType = Game.createNpcType("Sebina the Priest")
local npcConfig = {}

npcConfig.outfit = {
	lookType = 138, -- túnica azul con capucha y detalles dorados, como Sebina en MU
	lookHead = 88,
	lookBody = 88,
	lookLegs = 79,
	lookFeet = 79,
	lookAddons = 1,
	lookMount = 0,
}

Mubia.registerShopNpc(npcType, npcConfig, {
	shop = {},
	greeting = "Bienvenido, |PLAYERNAME|. Hazme clic y te contaré cómo despertar tu verdadero poder.",
	voice = "Los guerreros de nivel 150 pueden despertar su verdadero poder...",
})
