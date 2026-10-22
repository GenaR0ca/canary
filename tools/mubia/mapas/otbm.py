import sys
NODE_START,NODE_END,ESC=0xFE,0xFF,0xFD
def parse_file(path):
    data=open(path,'rb').read()
    sys.setrecursionlimit(1000000)
    def parse(pos):
        assert data[pos]==NODE_START
        pos+=1; t=data[pos]; pos+=1
        props=bytearray(); children=[]
        while True:
            b=data[pos]
            if b==ESC: props.append(data[pos+1]); pos+=2
            elif b==NODE_START:
                c,pos=parse(pos); children.append(c)
            elif b==NODE_END: return [t,bytes(props),children],pos+1
            else: props.append(b); pos+=1
    root,_=parse(4)
    return data[:4],root
def esc(b):
    out=bytearray()
    for x in b:
        if x in (NODE_START,NODE_END,ESC): out.append(ESC)
        out.append(x)
    return out
def serialize(header,root):
    out=bytearray(header)
    def w(n):
        out.append(NODE_START); out.append(n[0]); out.extend(esc(n[1]))
        for c in n[2]: w(c)
        out.append(NODE_END)
    w(root)
    return bytes(out)
