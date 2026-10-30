# PLAN: Sala del GOD (zona pequeña solo para GOD, vía comando)

## Goal / acceptance
1. Existe una zona de 11x11 tiles (interior 9x9) en el mapa `data-canary/world/canary.otbm`, z=7, esquina NW en (3095,3095), centro (3100,3100). Ahora mismo esa región no tiene ningún tile (verificado: sin tiles en x 3093..3107, y 3093..3107, z=7).
2. Un GOD (group type god) escribe `/godzone` y es llevado a (3100,3100,7). Un no-GOD no puede ejecutarlo (talkaction con `groupType("god")` + comprobación del grupo del personaje en onSay).
3. Si el GOD ya está dentro de la zona y escribe `/godzone`, vuelve a la posición guardada (o al templo (1943,1345,7) si no hay posición guardada, p. ej. tras reinicio).
4. Nada en el mapa apunta a la zona: no se añade a `warp.lua` (menú M) ni a `teleports.lua`.
5. Zona de protección (flag PZ = 1 en cada tile), para que nadie combata dentro.
6. El resto del OTBM queda byte-idéntico fuera de los tiles nuevos (salvo la reserialización del árbol, que se verifica round-trip).

## Approach
- `tools/mubia/mapas/godzone.py` (nuevo): lector/escritor OTBM mínimo (parse a árbol de nodos con escapes 0xFD/0xFE/0xFF; write inverso). Se valida que `write(parse(f)) == f` sobre el mapa actual (ya comprobado: True).
- Añade un nodo TILE_AREA (tipo 4, props `x:u16,y:u16,z:u8` = 3095,3095,7) con 121 nodos TILE (tipo 5, props `dx:u8,dy:u8` + atributo 3 TILE_FLAGS u32=1 + atributo 9 ITEM ground u16). Mismo formato que los tiles del templo (p. ej. `03 01000000 09 c601` = flags PZ + suelo 454 "wooden floor").
- Suelo: item 454 en los 121 tiles. Borde (40 tiles del anillo exterior): además un nodo hijo ITEM (tipo 6, `id:u16`) con pared "stone wall" (ids 1294..1304 de items.xml; norte/sur una variante, este/oeste otra, esquinas otra) para cerrar la sala. Centro (3100,3100): suelo 596 como marca visual (igual que el centro del templo).
- El editor inserta el área en `data[2]` justo después del último nodo tipo 4 y antes de los nodos 12/15 (towns/waypoints), preservando el orden del resto. Escribe a archivo temporal y reemplaza solo si pasa las verificaciones.
- `data-canary/scripts/mubia/godzone.lua` (nuevo): `TalkAction("/godzone")`, `groupType("god")`. Mantiene `Mubia.GodZone = { center = Position(3100,3100,7), min=Position(3095,3095,7), max=Position(3105,3105,7), returns = {} }`. onSay: si la posición del jugador está dentro de min..max -> teleporta a `returns[guid]` o al templo y borra la entrada; si no -> guarda posición actual, teleporta al centro. Autorización (GZ-001): `groupType("god")` lo valida el dispatcher contra el tipo de CUENTA; además `onSay` exige el GRUPO del personaje (`player:getGroup():getId() >= GROUP_TYPE_GOD`, si no, `sendCancelMessage` y return false). Así hacen falta ambos: cuenta god y personaje god.
Estado (GZ-002): `teleportTo` se llama primero; solo si devuelve true se borra/guarda `returns[guid]` y se emite `CONST_ME_TELEPORT`. Si falla, se conserva la posición guardada y se avisa al jugador con `sendCancelMessage`. Devuelve true.
- Spawns/NPC/monstruos: ninguno. Sin town nueva.

## Non-goals
Menú M, NPCs, monstruos, nueva town, protección contra otros teletransportes (no hay ninguno que apunte allí; un GOD puede usar `/goto` igualmente), cliente.

## Assumptions (sources)
- Datapack cargado: `config.lua` -> `dataPackDirectory="data-canary"`, `mapName="canary"`; scripts de `data-canary/scripts/mubia/*.lua` se cargan (teleports.lua, warp.lua existentes).
- Formato de tile/área: inspección del OTBM real (scripts en scratchpad), tile (1943,1345,7) = `97 41 | 03 01000000 | 09 5402`.
- Ids 454/596 de suelo existen (items.xml l.902, l.999). Ids de pared 1294-1304: "stone wall" (items.xml l.3281). Orientación exacta por id (horizontal/vertical/esquina) a confirmar visualmente en RME por el usuario.
- Riesgo: las ids de pared son las de Tibia 7.x/8.x; el cliente Mubia (otclient) podría mostrarlas distinto. El usuario lo ajusta en RME si hace falta.
- Riesgo: el servidor carga el mapa completo; añadir 121 tiles no afecta rendimiento.

## Verification
1. `python tools/mubia/mapas/godzone.py --check --base <otbm original>` (mapa ya con sala; ademas `--check <otbm original>` hace dry-run sobre el original; `--apply` solo funciona sobre un mapa sin sala): lee el otbm, aplica o verifica, reparsea el resultado y comprueba: (a) round-trip original idéntico, (b) exactamente 121 tiles nuevos en el rectángulo y ninguno modificado/perdido fuera de él (compara el conjunto de tiles (x,y,z)->(props,hijos) antes/después), (c) cada tile nuevo tiene flags=1 y suelo.
2. Arrancar el servidor desde `C:\Mubia\canary` con el mapa nuevo (copia de trabajo en una carpeta de pruebas, no sobre el mapa vivo) y confirmar en consola que carga el mapa sin errores y que `godzone.lua` carga (`Mubia.GodZone`).
3. Prueba manual del usuario en el juego: `/godzone` como GOD llega a la sala; de nuevo vuelve; con un personaje no-GOD el comando no existe o se rechaza (probar también personaje no-god en cuenta god).
4. `luacheck`/`stylua --check` si están disponibles en el repo para el .lua nuevo.
