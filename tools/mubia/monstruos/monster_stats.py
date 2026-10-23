# Mubia Online: genera data/libs/systems/mubia_monster_stats.lua a partir del Monster.txt de MU
# (servidor MuEmu Season 6, https://github.com/minhloc0304/mu-server-ex Compiled/Data/Local/Monster.txt).
# Uso (desde la carpeta canary): python tools/mubia/monstruos/monster_stats.py
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "Monster.txt")
OUT = os.path.join(HERE, "..", "..", "..", "data", "libs", "systems", "mubia_monster_stats.lua")

ROW = re.compile(r'^(\d+)\s+\d+\s+"([^"]+)"\s+(.*)$')

monsters = []
seen = set()
section = ""
with open(SRC, encoding="latin-1") as f:
    for line in f:
        line = line.rstrip("\n")
        if line.startswith("//") and not line.startswith("//=") and not line.startswith("//Numb") and not line.startswith("//\t"):
            section = line[2:].strip()
            continue
        m = ROW.match(line)
        if not m:
            continue
        index, name, rest = int(m.group(1)), m.group(2), m.group(3).split()
        if name in seen or "%" in name or len(rest) < 25:
            continue
        v = [int(x) for x in rest[:25]]
        level, life, _mana, dmin, dmax, defense, mdef, atk, dsr, _move, atype, arange, view, _mspeed, aspeed, regen, _attr, item, money, maxitem, rwind, rpoison, rice, rwater, rfire = v
        if life <= 10 and level <= 2:  # NPCs y objetos de eventos
            continue
        seen.add(name)
        monsters.append((section, index, name, level, life, min(dmin, dmax), max(dmin, dmax), defense, mdef, atk, dsr, atype, arange, view, aspeed, regen, item, money, maxitem))

out = []
out.append("-- Mubia Online: stats de los monstruos de MU (Season 6), sacados del Monster.txt del servidor MU.")
out.append("-- ARCHIVO GENERADO por tools/mubia/monstruos/monster_stats.py: no lo edites a mano, cambia el generador.")
out.append("-- Para cambiar un monstruo en particular pon custom = true en su archivo de data-canary/monster/mubia.")
out.append("-- level, hp, minDamage, maxDamage, defense, magicDefense,")
out.append("-- attackRate (precisión, contra la defensa de bloqueo del jugador), defenseRate (bloqueo, contra la precisión del jugador),")
out.append("-- attackType y attackRange (1 = cuerpo a cuerpo), viewRange, attackSpeed (ms entre golpes), regenTime (segundos para reaparecer),")
out.append("-- itemRate, moneyRate y maxItemLevel (para los drops).")
out.append("")
out.append("Mubia.MonsterStats = {")
last = None
for (section, index, name, level, life, dmin, dmax, defense, mdef, atk, dsr, atype, arange, view, aspeed, regen, item, money, maxitem) in monsters:
    if section != last:
        out.append("\t-- " + section)
        last = section
    out.append('\t["%s"] = { index = %d, level = %d, hp = %d, minDamage = %d, maxDamage = %d, defense = %d, magicDefense = %d, attackRate = %d, defenseRate = %d, attackType = %d, attackRange = %d, viewRange = %d, attackSpeed = %d, regenTime = %d, itemRate = %d, moneyRate = %d, maxItemLevel = %d },'
               % (name.replace('"', '\\"'), index, level, life, dmin, dmax, defense, mdef, atk, dsr, atype, arange, view, aspeed, regen, item, money, maxitem))
out.append("}")
with open(OUT, "w", encoding="utf-8", newline="\n") as f:
    f.write("\n".join(out) + "\n")
print(len(monsters), "monstruos ->", os.path.normpath(OUT))
