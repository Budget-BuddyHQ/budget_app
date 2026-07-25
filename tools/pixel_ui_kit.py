"""Pixel-art UI kit for Budget Buddy — renders PNGs sized to the 32x32 sprite world.
Palette is the app's emerald/aqua/gold, kept dark so sprites read on top."""
import zlib, struct, os, sys

C = {
 'ink':(0x0E,0x1F,0x18,255),   # outline / darkest
 'p1' :(0x14,0x35,0x28,255),   # panel fill dark
 'p2' :(0x1B,0x47,0x35,255),   # panel fill
 'p3' :(0x27,0x5E,0x47,255),   # panel highlight
 'gold':(0xFF,0xD4,0x5C,255),
 'gold2':(0xE8,0xB5,0x3A,255),
 'em' :(0x34,0xD3,0x99,255),
 'em2':(0x10,0x98,0x6E,255),
 'aq' :(0x22,0xD3,0xEE,255),
 'red':(0xF8,0x71,0x71,255),
 'red2':(0xB4,0x45,0x45,255),
 'w'  :(0xFF,0xFF,0xFF,255),
 'gy' :(0x7F,0xA6,0x97,255),
 'clr':(0,0,0,0),
}

def blank(w,h): return [[C['clr'] for _ in range(w)] for _ in range(h)]
def rect(img,x,y,w,h,c):
    for yy in range(y,y+h):
        for xx in range(x,x+w):
            if 0<=yy<len(img) and 0<=xx<len(img[0]): img[yy][xx]=c
def px(img,x,y,c):
    if 0<=y<len(img) and 0<=x<len(img[0]): img[y][x]=c

def panel(w,h):
    """9-slice-able panel: 3px chunky border, inner highlight."""
    img=blank(w,h)
    rect(img,1,1,w-2,h-2,C['p2'])
    rect(img,0,1,1,h-2,C['ink']); rect(img,w-1,1,1,h-2,C['ink'])
    rect(img,1,0,w-2,1,C['ink']); rect(img,1,h-1,w-2,1,C['ink'])
    for (x,y) in [(0,0),(w-1,0),(0,h-1),(w-1,h-1)]: px(img,x,y,C['clr'])
    for (x,y) in [(1,1),(w-2,1),(1,h-2),(w-2,h-2)]: px(img,x,y,C['ink'])
    rect(img,2,1,w-4,1,C['p3'])            # top highlight
    rect(img,1,2,1,h-4,C['p3'])
    rect(img,2,h-2,w-4,1,C['p1'])          # bottom shade
    rect(img,w-2,2,1,h-4,C['p1'])
    rect(img,3,3,w-6,1,C['gold'])          # gold accent rule under the title area
    return img

def button(w,h,tone='em',pressed=False):
    img=blank(w,h)
    base = C[tone]; dark = C[tone+'2'] if tone+'2' in C else C['ink']
    off = 1 if pressed else 0
    rect(img,1,1+off,w-2,h-2-off,base)
    rect(img,0,2+off,1,h-4-off,C['ink']); rect(img,w-1,2+off,1,h-4-off,C['ink'])
    rect(img,2,0+off,w-4,1,C['ink']);     rect(img,2,h-1,w-4,1,C['ink'])
    px(img,1,1+off,C['ink']); px(img,w-2,1+off,C['ink'])
    px(img,1,h-2,C['ink']);   px(img,w-2,h-2,C['ink'])
    if not pressed:
        rect(img,3,1,w-6,1,C['w'])         # top gloss
        rect(img,2,h-3,w-4,2,dark)         # bottom lip
    else:
        rect(img,2,h-3,w-4,1,dark)
    return img

def bar(w,h,fill,tone='gold'):
    img=blank(w,h)
    rect(img,1,0,w-2,h,C['ink']); rect(img,0,1,w,h-2,C['ink'])
    rect(img,2,2,w-4,h-4,C['p1'])
    fw=int((w-4)*fill)
    if fw>0:
        rect(img,2,2,fw,h-4,C[tone])
        rect(img,2,2,fw,1,C['w'])
    return img

def icon_coin():
    g,o,i,w=C['gold'],C['gold2'],C['ink'],C['w']
    A=[
    "..iiii..",
    ".iggggi.",
    "igwggogi",
    "igwggogi",
    "igoggogi",
    "igooooti",
    ".iooooi.",
    "..iiii..",]
    m={'i':i,'g':g,'o':o,'w':w,'t':o,'.':C['clr']}
    return [[m[c] for c in row] for row in A]

def icon_star():
    g,o,i=C['gold'],C['gold2'],C['ink']
    A=[
    "...ii...",
    "..iggi..",
    ".iggggi.",
    "iggggggi",
    "iggooogi",
    ".igoooi.",
    "..iooi..",
    "...ii...",]
    m={'i':i,'g':g,'o':o,'.':C['clr']}
    return [[m[c] for c in row] for row in A]

def icon_heart():
    r,d,i,w=C['red'],C['red2'],C['ink'],C['w']
    A=[
    ".ii..ii.",
    "irriirri",
    "irwrrrri",
    "irrrrrri",
    ".irrrrdi",
    "..irrdi.",
    "...iri..",
    "....i...",]
    m={'i':i,'r':r,'d':d,'w':w,'.':C['clr']}
    return [[m[c] for c in row] for row in A]

def icon_bag():
    e,d,i,g=C['em'],C['em2'],C['ink'],C['gold']
    A=[
    "..i..i..",
    "..iggi..",
    ".iiiiii.",
    "ieeeeeei",
    "ieegggei",
    "ieegggei",
    "ieeeeeei",
    ".iiiiii.",]
    m={'i':i,'e':e,'d':d,'g':g,'.':C['clr']}
    return [[m[c] for c in row] for row in A]

def paste(dst,src,x,y):
    for j,row in enumerate(src):
        for k,c in enumerate(row):
            if c[3]: px(dst,x+k,y+j,c)

def png(w,h,pix):
    def chunk(t,d):
        c=t+d; return struct.pack('>I',len(d))+c+struct.pack('>I',zlib.crc32(c)&0xffffffff)
    raw=bytearray()
    for y in range(h):
        raw.append(0)
        for x in range(w): raw+=bytes(pix[y][x])
    return b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',w,h,8,6,0,0,0))+chunk(b'IDAT',zlib.compress(bytes(raw),9))+chunk(b'IEND',b'')

def save(img,path):
    open(path,'wb').write(png(len(img[0]),len(img),img)); print('wrote',path,len(img[0]),'x',len(img))

def scale(img,s):
    return [[img[y//s][x//s] for x in range(len(img[0])*s)] for y in range(len(img)*s)]

out=sys.argv[1]
os.makedirs(out,exist_ok=True)
save(panel(48,32),  out+'/panel_dialog.png')
save(panel(32,32),  out+'/panel_square.png')
save(button(28,12,'em'),          out+'/btn_primary.png')
save(button(28,12,'em',True),     out+'/btn_primary_pressed.png')
save(button(28,12,'gold'),        out+'/btn_gold.png')
save(bar(40,8,1.0,'gold'),        out+'/bar_gold_full.png')
save(bar(40,8,0.55,'em'),         out+'/bar_xp.png')
save(bar(40,8,0.3,'red'),         out+'/bar_health.png')
save(icon_coin(),  out+'/icon_coin.png')
save(icon_star(),  out+'/icon_star.png')
save(icon_heart(), out+'/icon_heart.png')
save(icon_bag(),   out+'/icon_bag.png')

# one combined sheet (scaled x4) for preview / reference
sheet=blank(220,120)
rect(sheet,0,0,220,120,(0x0A,0x19,0x12,255))
paste(sheet,panel(48,32),6,6)
paste(sheet,panel(32,32),60,6)
paste(sheet,button(28,12,'em'),100,10)
paste(sheet,button(28,12,'em',True),100,26)
paste(sheet,button(28,12,'gold'),134,10)
paste(sheet,bar(40,8,1.0,'gold'),134,28)
paste(sheet,bar(40,8,0.55,'em'),134,40)
paste(sheet,bar(40,8,0.3,'red'),134,52)
paste(sheet,icon_coin(),8,46)
paste(sheet,icon_star(),20,46)
paste(sheet,icon_heart(),32,46)
paste(sheet,icon_bag(),44,46)
save(scale(sheet,4), out+'/_uikit_preview.png')
