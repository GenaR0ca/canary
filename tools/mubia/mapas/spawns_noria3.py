"""Vuelve a ubicar los spawns de Noria sobre el mapa nuevo: toma de canary-monster.xml los bloques que hay hoy en Noria
(qué monstruo, cuántos por bloque y su spawntime), los saca y pone la misma cantidad de bloques por monstruo en el
mapa nuevo, más fuertes cuanto más lejos de la ciudad.
uso: python spawns_noria3.py iteminfo.pkl monster_origen.xml monster_destino.xml"""
import math, pickle, random, re, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import noria3 as N

INFO, SRC, DST = sys.argv[1:4]
info = pickle.load(open(INFO, 'rb'))
rng = random.Random(4242)
X0, Y0, X1, Y1 = N.OX, N.OY, N.OX + N.W - 1, N.OY + N.H - 1

xml = open(SRC, encoding='utf-8').read()
BLOCK = re.compile(r'\t<monster centerx="(\d+)" centery="(\d+)" centerz="(\d+)" radius="(\d+)">\n(.*?)\t</monster>\n', re.S)
old = []


def take(m):
    cx, cy, cz = int(m.group(1)), int(m.group(2)), int(m.group(3))
    if not (X0 <= cx <= X1 and Y0 <= cy <= Y1 and cz == N.Z):
        return m.group(0)
    mons = re.findall(r'<monster name="([^"]+)" x="-?\d+" y="-?\d+" z="\d+" spawntime="(\d+)"', m.group(5))
    old.append(mons)
    return ''


xml = BLOCK.sub(take, xml)
xml = xml.replace('\t<!-- Noria (MU) -->\n', '')
print('bloques viejos en Noria:', len(old))


def walk(x, y):
    if not (0 <= x < N.W and 0 <= y < N.H):
        return False
    if N.ground[y][x] not in ('grass', 'meadow', 'forest', 'path'):
        return False
    if (x, y) in N.flags:
        return False
    st = N.tiles[(N.OX + x, N.OY + y, N.Z)][1]
    return not any(info.get(i, {}).get('unpass') for i in st)


# zonas por distancia a la ciudad (de más débil a más fuerte), como en el MU: goblins al lado de la ciudad
ORDER = ["Goblin", "Chain Scorpion", "Elite Goblin", "Beetle Monster", "Hunter", "Forest Monster", "Agon", "Stone Golem"]
ZONES = {"Goblin": (22, 45), "Chain Scorpion": (40, 62), "Elite Goblin": (55, 80), "Beetle Monster": (70, 98),
         "Hunter": (88, 118), "Forest Monster": (105, 140), "Agon": (125, 165), "Stone Golem": (150, 240)}
groups = {}
for mons in old:
    if mons:
        groups.setdefault(mons[0][0], []).append(mons)
CX, CY = N.CITY
taken = []
out = []
for name in sorted(groups, key=lambda n: ORDER.index(n) if n in ORDER else 99):
    dmin, dmax = ZONES.get(name, (60, 200))
    placed = 0
    for mons in groups[name]:
        for tries in range(60000):
            spread = 1 + tries // 15000  # si no entra, se agranda un poco la zona
            x, y = rng.randrange(N.W), rng.randrange(N.H)
            d = math.hypot(x - CX, y - CY)
            if not (dmin / spread <= d <= dmax * spread) or not walk(x, y):
                continue
            if any(math.hypot(x - tx, y - ty) < 8 for tx, ty in taken):
                continue
            spots = [(dx, dy) for dx in range(-3, 4) for dy in range(-3, 4) if walk(x + dx, y + dy) and N.ground[y + dy][x + dx] != 'path']
            if len(spots) < len(mons) + 4:
                continue
            rng.shuffle(spots)
            taken.append((x, y))
            body = ''.join(f'\t\t<monster name="{nm}" x="{dx}" y="{dy}" z="{N.Z}" spawntime="{st}" />\n' for (nm, st), (dx, dy) in zip(mons, spots))
            out.append(f'\t<monster centerx="{N.OX + x}" centery="{N.OY + y}" centerz="{N.Z}" radius="3">\n{body}\t</monster>\n')
            placed += 1
            break
    print(name, 'bloques', placed, 'de', len(groups[name]))
pos = xml.rindex('</monsters>')
xml = xml[:pos] + '\t<!-- Noria (MU) -->\n' + ''.join(out) + xml[pos:]
open(DST, 'w', encoding='utf-8', newline='').write(xml)
print('bloques nuevos:', len(out), 'monstruos:', sum(b.count('<monster name=') for b in out))
