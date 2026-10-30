# PLAN: Rage Fighter, fase 1 (vocación, stats y creación de personaje)

## Objetivo y criterios de aceptación
Agregar la clase Rage Fighter (RF) siguiendo el modelo de Dark Lord y Summoner, solo en servidor, datos y script de cuentas.

1. Existe la vocación id 15, baseid 15, clientid 10, nombre "Rage Fighter", sin promoción (`fromvoc="15"`).
2. `Mubia.getClass(player)` devuelve la clase RF: `Mubia.CLASS_RF = 15`, 7 puntos por nivel, `noEvolution = true`, sin Command (`cmd = 0`).
3. Valores de la clase:
   - Base: STR 32, AGI 27, VIT 25, ENE 20, CMD 0.
   - Vida: base 100, +1.3 por nivel, +2 por VIT.
   - Maná: base 40, +1 por nivel, +1.3 por ENE.
   - Daño físico: min `floor(STR/7 + VIT/15)`, max `floor(STR/5 + VIT/12)`.
   - Defensa: `floor(AGI/4)`. Divisores de velocidad: ataque 15, magia 20.
   - AG: `{ str = 0.15, agi = 0.2, vit = 0.3, ene = 1.0 }` (igual que DK).
4. Con los stats base se obtiene: daño 6-8, defensa 6, velocidad de ataque 1865 ms, de magia 1423 ms, AG 37. Vida: 100 a nivel 1 y 618 a nivel 400. Maná: 40 a nivel 1 y 439 a nivel 400.
5. Existe `Rage Fighter Sample` (id 11, cuenta 1, vocación 15, town 9) en `schema.sql` y en la base `mubia`, y `crear-cuenta.ps1` ofrece la opción 7 = Rage Fighter y copia ese Sample.
6. El RF no tiene equipo: `Mubia.StarterGear` no tiene entrada para él, no recibe el aviso "Recibiste el set inicial" y no se marca `starterGear`, de modo que recibirá su set cuando este se agregue. Las clases existentes conservan su comportamiento exacto.
7. `data-canary/world/canary.otbm` queda byte-idéntico (SHA256 `b6e6576de3c0256ec4fa5357a04f15374d90c59b6b51aee13149faefc36da8db`).
8. El servidor arranca sin errores nuevos con los cambios.

## Enfoque (archivos)
- `data/XML/vocations.xml`: vocación 15 tras la 14. Valores de DL (`gaincap="20"`, `gainhpticks="6000"`, `gainmanaticks="3000"`, `manamultiplier="1.4"`, mitigación y skills de DL, `avatarlooktype="1593"`).
- `data/libs/systems/mubia.lua`: `Mubia.CLASS_RF = 15` y su entrada en `Mubia.Classes`. Sin `magic` ni `skillMultiplier` (no tiene magias).
- `data/libs/systems/mubia_sdag.lua`: fila de `agFormula`.
- `data/libs/systems/mubia_items.lua`, `giveStarterGear`: buscar primero la lista de la clase. Si no hay, devolver `false` sin marcar `starterGear`. Sin esto, `creaturescripts.lua:28` avisaría de un set inexistente y el RF perdería el set futuro. Para las clases con lista, el orden y resultado no cambian.
- `schema.sql`: fila del Sample (`level` 1, `vocation` 15, `town_id` 9, mismos valores que `Summoner Sample`).
- `../online/scripts/crear-cuenta.ps1` (fuera del repo git de `canary`): opción 7 en `$clases` y en el texto de la pregunta. Conservar el BOM UTF-8.
- Base de datos en vivo: `INSERT ... SELECT ... WHERE NOT EXISTS` con los valores de la fila de `schema.sql`. Reversible con `DELETE FROM players WHERE name = 'Rage Fighter Sample'`.
- Copia previa de los archivos tocados y de la fila/estado en `C:\Mubia\backup-antes-de-rage-fighter`.

Decisiones: el usuario pidió 7 puntos, fórmulas MU con balance Mubia (defensa AGI/4, divisores 15/20) y combate a puños. Fist Master queda fuera "de momento": al agregarla habrá que quitar `noEvolution`.

## No incluye
Magias, scrolls y su venta (`ScrollFirstId`, `ScrollSprites`, `ClassVocations`), set y armas, alas, Fist Master y misión de Sebina, compra de casas (C++), cambios de cliente, cambios de mapa o RME. No se toca el trabajo ajeno sin commitear: `canary.otbm`, `PLAN.md`, `data-canary/scripts/mubia/godzone.lua`, `tools/mubia/`.

## Supuestos y fuentes
- Puntos por nivel se aplican por `Mubia.getPointsPerLevel` (`mubia.lua:157,222,252`, `creaturescripts.lua:48`).
- `getPlayerVocationEnum` (`src/creatures/players/player.cpp:13030`) devuelve NONE para clientid 10: no puja casas, igual que MG/DL/Summoner. No se recompila.
- `checkGearRequirements` (`mubia_items.lua:283`) impide equipar equipo MU sin la clase en `gear.classes`, lo que da el "solo puños". `Mubia.Classes` se consulta por baseid, y `S.classItems` sin entrada deja a Sebina sin misión para RF (`mubia_sebina.lua:329`).
- `Data MU oficial` no tiene datos de clase; los valores de MU vienen de memoria de MU S6, sin verificar, y el usuario los aprobó.

## Riesgos conocidos
- Cliente sin cambios: la Cyclopedia muestra "Unknown Vocation" (`otclient/modules/gamelib/player.lua:717`). La ventana de stats muestra el nombre correcto, enviado por el servidor (`mubia.lua:570`).
- Golpe a puños: `Weapon::useFist` (`src/items/weapons/weapons.cpp:245`) tira `normal_random(0, max)` y `Mubia.modifyDamage` solo reemplaza el daño cuando es mayor que 0 (`mubia.lua:436`), así que una tirada de 0 es un golpe fallido aunque suban STR y VIT. Con `max = round(0.085 * factor * 7 * fist + level / 5)` y fist 10, la probabilidad calculada es 2,6 % (ataque), 4,6 % (balanceado) y 7,2 % (defensa) a nivel 1, y 0,1 % a 0,2 % a nivel 400. Las tiradas mayores que 0 reciben el daño completo de STR/VIT. Contra monstruos no hay bloqueo de Tibia (`mubia_creatures.lua:75`, defensa y armadura 0). Contra jugadores el bloqueo de Tibia es el mismo que sufren las armas, cuyo piso `level / 5` también es 0 de nivel 1 a 4 (`weapons.cpp:211`). **Se acepta para la fase 1**: no se recompila ni se añade otro camino de ataque; la fase del arma propia lo elimina, pues pasa por el camino de armas. Se documenta como límite y se prueba en el juego.
- Sin equipo, el RF queda por debajo de las demás clases hasta la fase del set.
- La inspección basada en git no ve `crear-cuenta.ps1` ni la base: se revisan aparte.

## Verificación
1. Mapa: `sha256sum data-canary/world/canary.otbm` antes y después (criterio 7).
2. Alcance: `git status --short` y `git diff --stat` solo muestran los archivos del plan más los cambios ajenos ya existentes.
3. Sintaxis: `python -c "import xml.etree.ElementTree as E; E.parse('data/XML/vocations.xml')"` y `[System.Management.Automation.Language.Parser]::ParseFile` sobre `crear-cuenta.ps1`, sin errores.
4. Valores con el motor real: un archivo temporal `data/scripts/mubia/zz_rf_check.lua` compara al arrancar el servidor los valores del criterio 4, `Vocation(15)` (nombre, baseId 15, clientId 10, sin promoción) y `Mubia.getPointsPerLevel` = 7, e imprime PASS/FAIL. Se borra después, y se confirma con `git status`.
5. Arranque: con `canary.exe`, sin proceso previo del servidor, hasta que anuncie que está online; comparar con la consola sin errores de la vocación o de Lua; cerrar.
6. Creación: ejecutar el SQL de `crear-cuenta.ps1` para el Sample dentro de una transacción con `ROLLBACK`, y comprobar que antes de `ROLLBACK` hay un personaje con vocación 15, town 9 y que después no queda.
7. Base: `SELECT` del Sample muestra un solo registro, con vocación 15, town 9.
8. Manual, en el juego (lo hace el usuario):
   - Entrar con `Rage Fighter Sample` en la cuenta god; aparece en Lorencia.
   - `/stats` y la ventana muestran "Rage Fighter", base 32/27/25/20, 2793 puntos tras la subida de prueba a nivel 400, sin fila de Command.
   - No hay aviso de set inicial ni equipo MU recibido; intentar equipar un objeto de otra clase da rechazo.
   - `/addstr 10` sube STR y el daño de `/stats`; 20 golpes a un monstruo, en modo ataque, causan daño dentro del rango de `/stats` menos la defensa del monstruo, con fallos ocasionales. Repetir subiendo también VIT (`/addvit 30`), que debe subir el rango.
   - Sebina responde que el RF no necesita segunda evolución.
   - `3-crear-cuenta-amigo.bat` con opción 7 crea un personaje que entra como RF.
