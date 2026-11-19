#!/usr/bin/env python3
"""Erzeugt die Alpe-Logos (SVG) – Zeichen nach dem Alpe-Wallpaper: Granitnadeln im
Alpenglühen über dem Nebelmeer. Schrift: Inter Display (SIL OFL), als Pfade.

    python3 assets/logo/erzeugen.py      braucht fontTools und Inter Display

PNG daraus: rsvg-convert -w 512 alpe-avatar.svg -o alpe-avatar.png
"""
import math, os
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.pens.boundsPen import BoundsPen

INTER="/usr/share/fonts/opentype/inter/InterDisplay-SemiBold.otf"
INTERM="/usr/share/fonts/opentype/inter/InterDisplay-Medium.otf"
OUT=os.path.dirname(os.path.abspath(__file__)); os.makedirs(OUT, exist_ok=True)

# Farben aus dem Wallpaper
NACHT="#13212C"; TIEF="#1B394D"; STAHL="#5B7287"; HIMMEL="#8FA6C2"; NEBEL="#E9EEF4"

# ---------------------------------------------------------------- Zeichen
def squircle(cx, cy, r, n=5, steps=240):
    pts=[]
    for i in range(steps):
        t=2*math.pi*i/steps; c,s=math.cos(t),math.sin(t)
        pts.append(f"{cx+r*math.copysign(abs(c)**(2/n),c):.1f} {cy+r*math.copysign(abs(s)**(2/n),s):.1f}")
    return "M"+" L".join(pts)+" Z"

def poly(pts, fill): return f'<path d="M{" L".join(f"{x:.1f} {y:.1f}" for x,y in pts)} Z" fill="{fill}"/>'

# Silhouette des Massivs (Koordinaten vor der Skalierung, Fuss bei y=410)
SIL=[(0,410),(0,372),(36,352),(70,336),(98,318),(112,300),(122,304),(132,264),(140,250),(146,256),(152,298),
     (166,290),(174,214),(181,198),(188,204),(194,248),(206,258),
     (214,246),(220,128),(228,100),(236,78),(244,68),(252,72),(258,92),(264,124),(270,182),(280,194),
     (287,184),(292,144),(298,128),(305,132),(311,168),(318,212),
     (326,204),(333,172),(341,160),(348,168),(355,226),
     (368,236),(379,212),(387,206),(394,220),(404,262),(430,284),(462,294),(492,318),(512,330),(512,410)]
# Westwände im Alpenglühen
LICHT=[[(122,304),(132,264),(140,250),(143,282),(140,304)],
       [(166,290),(174,214),(181,198),(185,248),(182,292)],
       [(214,246),(220,128),(228,100),(236,78),(244,68),(243,120),(238,190),(232,250),(226,300)],
       [(287,184),(292,144),(298,128),(300,180),(296,240)],
       [(326,204),(333,172),(341,160),(342,210),(337,256)],
       [(368,236),(379,212),(387,206),(388,250),(383,284)]]
# Grate, vom Himmel kühl angestrahlt
GRAT=[[(244,68),(252,72),(258,92),(250,150),(243,120)],[(298,128),(305,132),(303,170),(300,180)],
      [(181,198),(188,204),(186,236),(185,248)],[(341,160),(348,168),(345,196),(342,210)],
      [(387,206),(394,220),(390,240),(388,250)]]
RINNE=[[(254,206),(260,212),(257,256),(251,250)],[(303,236),(309,232),(310,276),(303,282)],
       [(347,236),(352,234),(352,268),(347,272)]]
SCHNEE=[[(150,298),(166,290),(163,296),(152,304)],[(196,250),(212,248),(209,255),(199,258)],
        [(272,184),(285,188),(282,194),(273,192)],[(229,262),(236,250),(240,256),(232,292),(227,300)],
        [(320,212),(325,206),(323,222),(318,232)],[(357,228),(366,236),(362,242),(355,236)]]
KLUFT=[((263,140),(266,220)),((309,172),(311,228)),((191,232),(192,266))]

def nebel(y, amp, period, phase, fill):
    """Weiche, unregelmässige Oberkante des Nebelmeers."""
    pts=[]; x=-30
    while x<=545:
        pts.append((x, y-amp*(0.6*math.sin(x/period*2*math.pi+phase)+0.4*abs(math.sin(x/(period*0.45)+phase*1.7)))))
        x+=12
    d=f"M-30 600 L{pts[0][0]} {pts[0][1]:.1f}"
    for (x0,y0),(x1,y1) in zip(pts, pts[1:]):
        d+=f" Q{x0+6:.1f} {y0:.1f} {(x0+x1)/2:.1f} {(y0+y1)/2:.1f}"
    return f'<path d="{d} L545 600 Z" fill="{fill}"/>'

def zeichen(cid, kachel=True):
    """Kachel 512×512 (Squircle) mit der ganzen Szene; cid hält die IDs eindeutig."""
    defs=(f'<linearGradient id="{cid}h" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8EA5C1"/>'
          f'<stop offset=".4" stop-color="#C3CEDC"/><stop offset=".64" stop-color="#E2D2CF"/><stop offset="1" stop-color="#EAD6CF"/></linearGradient>'
          f'<linearGradient id="{cid}r" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2B4A62"/><stop offset="1" stop-color="#17303F"/></linearGradient>'
          f'<linearGradient id="{cid}l" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F3DFD8"/><stop offset="1" stop-color="#D9BDB8"/></linearGradient>'
          f'<linearGradient id="{cid}w" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#F8F6F6" stop-opacity="0"/>'
          f'<stop offset=".3" stop-color="#F8F6F6" stop-opacity=".9"/><stop offset="1" stop-color="#F8F6F6" stop-opacity="0"/></linearGradient>'
          f'<linearGradient id="{cid}m" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F8F9FB"/><stop offset="1" stop-color="#D8E0EA"/></linearGradient>'
          f'<clipPath id="{cid}c"><path d="{squircle(256,256,240) if kachel else "M0 0 H512 V512 H0 Z"}"/></clipPath>')
    fern=(poly([(0,316),(40,296),(64,304),(96,270),(120,286),(150,262),(176,288),(220,280),(300,292),(340,266),(372,282),
                (410,248),(440,262),(470,240),(512,262),(512,512),(0,512)], "#B4C1D3")
          +poly([(400,262),(410,248),(418,272),(430,268),(440,262),(452,280),(470,240),(486,268),(512,262),(512,300),(400,300)], "#A4B3C8"))
    berg=(poly(SIL+[(512,512),(0,512)], f"url(#{cid}r)")
          +"".join(poly(p, f"url(#{cid}l)") for p in LICHT)
          +"".join(poly(p, "#6F86A0") for p in GRAT)
          +"".join(f'<path d="M{a[0]} {a[1]} L{b[0]} {b[1]}" stroke="#3E5A72" stroke-width="2" stroke-linecap="round"/>' for a,b in KLUFT)
          +"".join(poly(p, "#F7EEEB") for p in SCHNEE)
          +"".join(poly(p, "#5D7894") for p in RINNE)
          +f'<path d="M150 232 C200 226 250 228 300 222 C350 216 400 218 452 210 C410 222 360 230 300 234 C250 238 200 238 150 232 Z" fill="url(#{cid}w)"/>'
          +f'<path d="M86 300 C140 296 180 298 230 294 C200 304 140 306 86 300 Z" fill="url(#{cid}w)" opacity=".7"/>')
    meer=(nebel(352,14,150,0.3,"#C3CEDD")+nebel(372,12,120,1.6,"#D8E0EA")
          +nebel(398,10,140,2.8,"#E7ECF3")+nebel(432,8,160,4.1,f"url(#{cid}m)"))
    return (f'<defs>{defs}</defs><g clip-path="url(#{cid}c)"><rect width="512" height="512" fill="url(#{cid}h)"/>'
            f'{fern}<g transform="translate(-74,-48) scale(1.3)">{berg}</g>{meer}</g>'
            +(f'<path d="{squircle(256,256,240)}" fill="none" stroke="#0E1A24" stroke-opacity=".14" stroke-width="2"/>' if kachel else ''))

def platz(body, x, y, s): return f'<g transform="translate({x},{y}) scale({s})">{body}</g>'

# ---------------------------------------------------------------- Schrift
def glyphs(txt, font, size, x, y, tracking):
    f=TTFont(font); gs=f.getGlyphSet(); cmap=f.getBestCmap(); s=size/f["head"].unitsPerEm
    out=[]; cx=x
    for ch in txt:
        g=cmap[ord(ch)]; pen=SVGPathPen(gs); gs[g].draw(TransformPen(pen,(s,0,0,-s,cx,y)))
        bp=BoundsPen(gs); gs[g].draw(TransformPen(bp,(s,0,0,-s,cx,y)))
        out.append((ch, pen.getCommands(), bp.bounds)); cx+=gs[g].width*s+tracking*size
    return out, cx-tracking*size

def wort(c, x, y, size, cid):
    """«alpe»; das l mit schrägem Kopf wie eine Felsnadel."""
    gl,end=glyphs("alpe", INTER, size, x, y, -0.03); out=[]
    for ch, d, (x0,y0,x1,y1) in gl:
        if ch=="l":
            cut=(x1-x0)*0.62
            out.append(f'<clipPath id="{cid}"><path d="M{x0-2:.1f} {y0-1:.1f} L{x1+2:.1f} {y0+cut:.1f} L{x1+2:.1f} {y1+2:.1f} L{x0-2:.1f} {y1+2:.1f} Z"/></clipPath>'
                       f'<path d="{d}" fill="{c}" clip-path="url(#{cid})"/>')
        else: out.append(f'<path d="{d}" fill="{c}"/>')
    return "".join(out), end

def zeile(txt, c, x, y, size, track=0.34):
    gl,end=glyphs(txt, INTERM, size, x, y, track)
    return f'<path d="{" ".join(p for _,p,_ in gl)}" fill="{c}"/>', end

def svg(w,h,body,bg=None,title="Alpe"):
    b=bg if (bg or "").startswith("<") else (f'<rect width="{w}" height="{h}" fill="{bg}"/>' if bg else '')
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}" role="img" '
            f'aria-label="{title}"><title>{title}</title>{b}{body}</svg>\n')

def schreibe(name, inhalt): open(f"{OUT}/{name}.svg","w").write(inhalt)

if __name__=="__main__":
    # 1) Zeichen (Kachel, transparent um die Rundung) – App-Icon, Favicon, Avatar
    schreibe("alpe-zeichen", svg(512,512, zeichen("z")))
    # 2) Logo quer für das README (<picture>): Schrift hell bzw. dunkel
    for name, c, g in (("alpe-logo-dunkel", NEBEL, HIMMEL), ("alpe-logo-hell", TIEF, STAHL)):
        w,_=wort(c, 500, 302, 210, "l"+name)
        s,_=zeile("ZUGERBERG", g, 508, 420, 26)
        schreibe(name, svg(1220,500, platz(zeichen("k"+name[-4:]), 30, 30, 0.86)+w+s))
    # 3) Avatar (GitHub schneidet selbst zu: Szene randlos, quadratisch)
    schreibe("alpe-avatar", svg(512,512, zeichen("a", kachel=False)))
    # 4) Social Preview 1280×640
    hg=('<defs><linearGradient id="sg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#1B394D"/>'
        '<stop offset="1" stop-color="#101C25"/></linearGradient></defs><rect width="1280" height="640" fill="url(#sg)"/>')
    w,_=wort(NEBEL, 590, 330, 190, "lsp")
    s1,_=zeile("DESKTOP-SHELL FÜR DIE SCHWEIZ", HIMMEL, 598, 430, 24, 0.22)
    s2,_=zeile("KDE PLASMA  ·  HYPRLAND  ·  ASAHI", "#6F86A0", 598, 472, 24, 0.22)
    schreibe("alpe-social", svg(1280,640, platz(zeichen("s"),96,124,0.766)+w+s1+s2, hg))
