"""Genera los spawns de Devias (canary-monster.xml) según las zonas del boceto."""
import sys, math, random, pickle, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import devias as M

info = pickle.load(open(sys.argv[1], 'rb'))  # iteminfo.pkl (flags de appearances.dat)
OUT = sys.argv[2]
rng = random.Random(91)
OX, OY, Z = M.OX, M.OY, M.Z


def walk(x, y):
    if not (0 <= x < 256 and 0 <= y < 256):
        return False
    if M.ground[y][x] not in ('snow', 'road', 'ice', 'pave'):
        return False
    if (x, y) in M.flags:
        return False
    st = M.tiles[(OX + x, OY + y, Z)][1]
    return not any(info.get(i, {}).get('unpass') for i in st)


cells = {}
for y in range(256):
    for x in range(256):
        if walk(x, y):
            cells.setdefault(M.zone(x, y), []).append((x, y))

PLAN = [('Worm', 'Worm', 16), ('Ice Monster', 'Ice Monster', 14), ('Hommerd', 'Hommerd', 16), ('Assassin', 'Assassin', 16),
        ('Yeti', 'Yeti', 30), ('Elite Yeti', 'Elite Yeti', 18), ('Elite Yeti S', 'Elite Yeti', 14), ('Ice Queen', 'Elite Yeti', 3)]
taken = []
out = []


def block(x, y, names, spawntime=60):
    spots = [(dx, dy) for dx in range(-3, 4) for dy in range(-3, 4) if walk(x + dx, y + dy)]
    rng.shuffle(spots)
    spots.sort(key=lambda p: (p != (0, 0)))
    mons = ''.join(f'\t\t<monster name="{n}" x="{dx}" y="{dy}" z="{Z}" spawntime="{spawntime}" />\n' for n, (dx, dy) in zip(names, spots))
    out.append(f'\t<monster centerx="{OX + x}" centery="{OY + y}" centerz="{Z}" radius="3">\n{mons}\t</monster>\n')


# la Ice Queen en el patio de la fortaleza del sureste, con dos Elite Yeti de guardia
QX, QY = 222, 238
assert walk(QX, QY), 'casilla de la Ice Queen bloqueada'
block(QX, QY, ['Ice Queen'], spawntime=600)
taken.append((QX, QY))
for zone, name, blocks in PLAN:
    pool = cells.get(zone, [])
    n = tries = 0
    while n < blocks and tries < 20000 and pool:
        tries += 1
        x, y = rng.choice(pool)
        if any(math.hypot(x - tx, y - ty) < 9 for tx, ty in taken):
            continue
        if sum(1 for dx in range(-3, 4) for dy in range(-3, 4) if walk(x + dx, y + dy)) < 10:
            continue
        taken.append((x, y))
        n += 1
        block(x, y, [name] * 3)
    print(zone, n, file=sys.stderr)
open(OUT, 'w').write('\t<!-- Devias (MU) -->\n' + ''.join(out))
