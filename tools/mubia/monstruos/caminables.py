"""Mubia: casillas caminables del mapa (sin casas ni zona protegida). Uso: python caminables.py appearances.dat canary.otbm salida.pkl"""
import os, sys, pickle, struct
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'mapas'))
import otbm

def varint(b, p):
    r = s = 0
    while True:
        c = b[p]; p += 1; r |= (c & 0x7f) << s; s += 7
        if c < 0x80: return r, p

def fields(b):
    p = 0
    while p < len(b):
        k, p = varint(b, p); f, t = k >> 3, k & 7
        if t == 0: v, p = varint(b, p)
        elif t == 2:
            l, p = varint(b, p); v = b[p:p+l]; p += l
        elif t == 5: v = b[p:p+4]; p += 4
        elif t == 1: v = b[p:p+8]; p += 8
        else: raise Exception(t)
        yield f, t, v

def iteminfo(path):
    data = open(path, 'rb').read(); info = {}
    for f, t, v in fields(data):
        if f != 1: continue
        iid = None; fl = {}
        for f2, t2, v2 in fields(v):
            if f2 == 1: iid = v2
            elif f2 == 3:
                for f3, t3, v3 in fields(v2):
                    if f3 == 1: fl['bank'] = True
                    elif f3 == 13 and v3: fl['unpass'] = True
                    elif f3 == 16 and v3: fl['avoid'] = True
                    elif f3 == 14 and v3: fl['unmove'] = True
        info[iid] = fl
    return info

def tiles(path):
    header, root = otbm.parse_file(path)
    md = root[2][0]
    out = {}
    for area in md[2]:
        if area[0] != 4: continue
        ax, ay, az = struct.unpack('<HHB', area[1][:5])
        for tile in area[2]:
            if tile[0] not in (5, 14): continue
            pr = tile[1]; x, y = pr[0], pr[1]; p = 2
            house = tile[0] == 14
            if house: p += 4
            flags = 0; items = []
            while p < len(pr):
                a = pr[p]; p += 1
                if a == 3: flags = struct.unpack('<I', pr[p:p+4])[0]; p += 4
                elif a == 9: items.append(struct.unpack('<H', pr[p:p+2])[0]); p += 2
                else: break
            for it in tile[2]:
                if it[0] == 6: items.append(struct.unpack('<H', it[1][:2])[0])
            out[(ax + x, ay + y, az)] = (flags, house, items)
    return out

info = iteminfo(sys.argv[1]); t = tiles(sys.argv[2])
walk = set()
for pos, (flags, house, items) in t.items():
    if house or flags & 1 or not items: continue  # casas y zona protegida no
    if not info.get(items[0], {}).get('bank'): continue
    if any(info.get(i, {}).get('unpass') or info.get(i, {}).get('avoid') for i in items): continue
    walk.add(pos)
pickle.dump(walk, open(sys.argv[3], 'wb'))
print(len(info), 'items', len(t), 'tiles', len(walk), 'caminables')
