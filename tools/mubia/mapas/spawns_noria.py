import sys,math,random,pickle
sys.path.insert(0,'/tmp/claude-0/map')
import noria as M
info=pickle.load(open('/tmp/claude-0/gen/iteminfo.pkl','rb'))
rng=random.Random(78)
OX,OY,Z=M.OX,M.OY,M.Z
ground=M.ground
def walk(x,y):
    if not(0<=x<256 and 0<=y<256): return False
    if ground[y][x] not in ('grass','dirt'): return False
    if (x,y) in M.flags: return False
    st=M.tiles[(OX+x,OY+y,Z)][1]
    return not any(info.get(i,{}).get('unpass') for i in st)
CX,CY=M.CENTER
ZONES=[("Goblin",38,50,10),("Chain Scorpion",48,60,10),("Elite Goblin",58,70,11),("Beetle Monster",68,80,11),
       ("Hunter",78,90,11),("Forest Monster",88,100,10),("Agon",98,110,9),("Stone Golem",106,140,10)]
taken=[];out=[]
for name,dmin,dmax,blocks in ZONES:
    n=0;tries=0
    while n<blocks and tries<40000:
        tries+=1
        a=rng.random()*2*math.pi; d=rng.uniform(dmin,dmax)
        x=int(CX+math.cos(a)*d); y=int(CY+math.sin(a)*d)
        if not walk(x,y): continue
        if any(math.hypot(x-tx,y-ty)<9 for tx,ty in taken): continue
        spots=[(dx,dy) for dx in range(-3,4) for dy in range(-3,4) if walk(x+dx,y+dy)]
        if len(spots)<8: continue
        rng.shuffle(spots); taken.append((x,y)); n+=1
        mons=''.join(f'\t\t<monster name="{name}" x="{dx}" y="{dy}" z="{Z}" spawntime="60" />\n' for dx,dy in spots[:3])
        out.append(f'\t<monster centerx="{OX+x}" centery="{OY+y}" centerz="{Z}" radius="3">\n{mons}\t</monster>\n')
    print(name,n,file=sys.stderr)
open('/tmp/claude-0/map/spawns_noria.xml','w').write('\t<!-- Noria (MU) -->\n'+''.join(out))
