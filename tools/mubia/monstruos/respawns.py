"""Mubia: respawns como en MU. Cada grupo de monstruos de Lorencia, Noria y Devias pasa a tener
de 5 a 8 bichos (en casillas caminables dentro del radio) y reaparecen con el tiempo de Monster.txt
(10 segundos los normales). Los grupos de un solo monstruo (jefes como la Ice Queen) no se tocan.
Uso: python respawns.py canary-monster.xml caminables.pkl salida.xml"""
import os, re, sys, pickle, random

HERE = os.path.dirname(os.path.abspath(__file__))
MIN_GROUP, MAX_GROUP = 5, 8
# regiones de las ciudades MU en el mapa (x1, x2, y1, y2)
REGIONS = [(768, 1100, 500, 800), (1150, 1420, 500, 800), (1550, 1820, 500, 800)]

src, walk_path, out_path = sys.argv[1:4]
walk = pickle.load(open(walk_path, 'rb'))
rng = random.Random(2026)

regen = {}
for line in open(os.path.join(HERE, 'Monster.txt'), encoding='latin-1'):
    m = re.match(r'^\d+\s+\d+\s+"([^"]+)"\s+(.*)$', line)
    if m and m.group(1) not in regen:
        v = m.group(2).split()
        if len(v) >= 16:
            regen[m.group(1)] = int(v[15])

text = open(src, encoding='utf-8').read()
BLOCK = re.compile(r'(\t<monster centerx="(\d+)" centery="(\d+)" centerz="(\d+)" radius="(\d+)">\n)(.*?)(\t</monster>\n)', re.S)
MON = re.compile(r'<monster name="([^"]+)" x="(-?\d+)" y="(-?\d+)" z="(\d+)" spawntime="(\d+)" />')
stats = {'grupos': 0, 'antes': 0, 'despues': 0}


def fix(m):
    head, cx, cy, cz, r, body, tail = m.groups()
    cx, cy, cz, r = int(cx), int(cy), int(cz), int(r)
    if not any(x1 <= cx < x2 and y1 <= cy < y2 for x1, x2, y1, y2 in REGIONS):
        return m.group(0)
    mons = MON.findall(body)
    names = {n for n, *_ in mons}
    if len(mons) < 2 or len(names) != 1:
        return m.group(0)
    name = mons[0][0]
    want = rng.randint(MIN_GROUP, MAX_GROUP)
    spots = [(int(dx), int(dy)) for _, dx, dy, _, _ in mons]
    free = [(dx, dy) for dx in range(-r, r + 1) for dy in range(-r, r + 1)
            if (dx, dy) not in spots and (cx + dx, cy + dy, cz) in walk]
    rng.shuffle(free)
    spots = (spots + free)[:want]
    spawntime = regen.get(name, 10)
    stats['grupos'] += 1
    stats['antes'] += len(mons)
    stats['despues'] += len(spots)
    lines = ''.join(f'\t\t<monster name="{name}" x="{dx}" y="{dy}" z="{cz}" spawntime="{spawntime}" />\n' for dx, dy in spots)
    return head + lines + tail


text = BLOCK.sub(fix, text)
open(out_path, 'w', encoding='utf-8', newline='\n').write(text)
print(stats)
