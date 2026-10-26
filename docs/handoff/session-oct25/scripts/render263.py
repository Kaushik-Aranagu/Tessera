# Static renders of board 263's four keystones (PIL), same geometry as the canvas code, at a chosen hour.
import math, sys
from PIL import Image, ImageDraw, ImageFont

S = 3                        # 354x182 pt slot at 3x
W, H = 354 * S, 182 * S
TAU = math.pi * 2
HOUR = float(sys.argv[1]) if len(sys.argv) > 1 else 17.6
LOOK = sys.argv[2] if len(sys.argv) > 2 else 'paper'
TODAY = 2
DAYS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
if LOOK == 'paper':
    P = dict(bg=(247, 245, 241), ink=(36, 36, 35), ink2=(110, 106, 99), ink3=(169, 164, 155), hair=(200, 198, 194),
             acc=(142, 74, 120), gold=(126, 106, 30), sun=(232, 184, 74))
else:
    P = dict(bg=(0, 0, 0), ink=(232, 227, 218), ink2=(164, 158, 150), ink3=(107, 103, 95), hair=(52, 50, 48),
             acc=(213, 154, 196), gold=(217, 194, 122), sun=(232, 184, 74))

DAILY = [dict(n='Water', h=6.5, steps=1), dict(n='Stretch', h=7, steps=5), dict(n='Water plants', h=8, steps=1, auto=True),
         dict(n='Lunch', h=12.5, steps=2), dict(n='Tidy', h=17.5, steps=3), dict(n='Walk', h=18, steps=1),
         dict(n='Journal', h=22, steps=3), dict(n='Backup', h=23, steps=1, auto=True)]
WEEKLY = [dict(n='Call family', wd=0, h=19), dict(n='Swim', wd=4, h=18), dict(n='Badminton', wd=6, h=10)]
SKIPPED = {'Stretch'}

def font(sz, bold=False):
    for f in (['/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'] if bold else ['/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf']):
        try: return ImageFont.truetype(f, int(sz * S))
        except Exception: pass
    return ImageFont.load_default()

def state(r):
    if r['n'] in SKIPPED and r['h'] < HOUR: return 'skipped'
    return 'done' if r['h'] <= HOUR else 'wait'
def tone(st): return P['gold'] if st == 'done' else P['ink3'] if st == 'skipped' else P['ink']
def new():
    im = Image.new('RGB', (W, H), P['bg']); return im, ImageDraw.Draw(im)
def dot(d, x, y, r, fill=None, outline=None, w=1):
    d.ellipse([x*S-r*S, y*S-r*S, x*S+r*S, y*S+r*S], fill=fill, outline=outline, width=int(w*S))
def circle(d, cx, cy, r, col, w=1):
    d.ellipse([(cx-r)*S, (cy-r)*S, (cx+r)*S, (cy+r)*S], outline=col, width=max(1, int(w*S)))
def line(d, pts, col, w=1):
    d.line([(x*S, y*S) for x, y in pts], fill=col, width=max(1, int(w*S)), joint='curve')
def text(d, x, y, s, col, sz=10, anchor='la', bold=False):
    d.text((x*S, y*S), s, fill=col, font=font(sz, bold), anchor=anchor)
def fmt(h):
    hh = int(h); m = round((h-hh)*60)
    return f"{(hh+11)%12+1}{(':%02d' % m) if m else ''}{'am' if hh < 12 else 'pm'}"

# ---- 1 record player
def record():
    im, d = new()
    wx, wy, wr = 262, 98, 78
    circle(d, wx, wy, wr, P['hair'])
    wrot = -TAU*((TODAY+HOUR/24)/7)
    for i, r in enumerate(WEEKLY):
        rr = wr-14-i*14; circle(d, wx, wy, rr, P['hair'])
        a = wrot+TAU*((r['wd']+r['h']/24)/7)-math.pi/2
        past = (r['wd']+r['h']/24) < (TODAY+HOUR/24)
        dot(d, wx+math.cos(a)*rr, wy+math.sin(a)*rr, 2.6, fill=P['gold'] if past else P['ink'])
    text(d, wx, wy, DAYS[TODAY], P['ink2'], 10, 'mm')
    line(d, [(wx, wy-wr-10), (wx, wy-wr+22)], P['ink2'])
    cx, cy, R = 112, 96, 86
    rot = -TAU*(HOUR/24)-math.pi/2
    d.ellipse([(cx-R)*S, (cy-R)*S, (cx+R)*S, (cy+R)*S], fill=tuple(int(a*.93+b*.07) for a, b in zip(P['bg'], P['ink'])), outline=P['ink'], width=int(1.2*S))
    for i, r in enumerate(DAILY):
        rr = R-9-i*8.6; circle(d, cx, cy, rr, P['hair']); st = state(r)
        if st == 'done':
            a0 = math.degrees(rot+TAU*(r['h']/24)-math.pi/2); a1 = math.degrees(rot-math.pi/2)
            d.arc([(cx-rr)*S, (cy-rr)*S, (cx+rr)*S, (cy+rr)*S], a0, a1, fill=tuple(int(a*.55+b*.45) for a, b in zip(P['bg'], P['gold'])), width=int(2*S))
        for s in range(r['steps']):
            a = rot+TAU*((r['h']+s*.25)/24)-math.pi/2
            x, y = cx+math.cos(a)*rr, cy+math.sin(a)*rr
            if r.get('auto'): dot(d, x, y, 2.4, outline=tone(st), w=1)
            else: dot(d, x, y, 2.8 if st == 'done' else 2.2, fill=tone(st))
    dot(d, cx, cy, 16, fill=P['bg'], outline=P['hair']); dot(d, cx, cy, 1.6, fill=P['ink'])
    text(d, cx, cy+22, 'side A' if HOUR < 12 else 'side B', P['ink2'], 9, 'mm')
    played = [r for r in DAILY if r['h'] <= HOUR]
    nr = R-9-min(len(DAILY)-1, max(0, len(played)-.5))*8.6
    px, py = cx+R+40, cy-R-6; nx, ny = cx, cy-nr
    line(d, [(px, py), (nx+8, ny-4), (nx, ny)], P['ink'], 1.4); dot(d, px, py, 3, fill=P['ink'])
    nxt = [r for r in DAILY if r['h'] > HOUR]; cur = played[-1] if played else None
    text(d, 8, 176, (cur['n']+' played' if cur else '')+((' · ' if cur else '')+'next '+nxt[0]['n'] if nxt else ''), P['ink2'], 12, 'ls')
    return im

# ---- 2 day map
ROOMS = [dict(n='Bed', x=8, y=10, w=84, h=62, at=[22, 23, 6.5]), dict(n='Kitchen', x=98, y=10, w=100, h=62, at=[8, 12.5, 17.5]),
         dict(n='Desk', x=204, y=10, w=84, h=92, at=[]), dict(n='Gym', x=8, y=78, w=84, h=70, at=[7]),
         dict(n='Door', x=98, y=78, w=100, h=40, at=[18]), dict(n='Pool', x=204, y=108, w=84, h=40, at=[], wd=4)]
def room_for(h):
    if h < 6.5 or h >= 22.5: return ROOMS[0]
    if h < 7: return ROOMS[1]
    if h < 8: return ROOMS[3]
    if h < 8.5: return ROOMS[1]
    if h < 12.5: return ROOMS[2]
    if h < 13.2: return ROOMS[1]
    if h < 17.5: return ROOMS[2]
    if h < 18: return ROOMS[1]
    if h < 19: return ROOMS[4]
    if h < 22: return ROOMS[2]
    return ROOMS[0]
def daymap():
    im, d = new(); day = 6 < HOUR < 19.5
    if day:
        sx = 20+(HOUR-6)/13.5*300; ov = Image.new('RGBA', (W, H), (0, 0, 0, 0)); od = ImageDraw.Draw(ov)
        for i in range(-50, 50):
            al = int((1-abs(i)/50)*(20 if LOOK == 'paper' else 14))
            od.line([((sx+i)*S, 0), ((sx+i)*S, 160*S)], fill=P['sun']+(al,), width=S)
        im = Image.alpha_composite(im.convert('RGBA'), ov).convert('RGB'); d = ImageDraw.Draw(im)
    now = room_for(HOUR)
    for r in ROOMS:
        box = [r['x']*S, r['y']*S, (r['x']+r['w'])*S, (r['y']+r['h'])*S]
        if r.get('wd') is not None and r['wd'] != TODAY:
            for k in range(0, r['w'], 6): d.line([((r['x']+k)*S, r['y']*S), ((r['x']+min(k+2, r['w']))*S, r['y']*S)], fill=P['hair'], width=S); d.line([((r['x']+k)*S, (r['y']+r['h'])*S), ((r['x']+min(k+2, r['w']))*S, (r['y']+r['h'])*S)], fill=P['hair'], width=S)
            for k in range(0, r['h'], 6): d.line([(r['x']*S, (r['y']+k)*S), (r['x']*S, (r['y']+min(k+2, r['h']))*S)], fill=P['hair'], width=S); d.line([((r['x']+r['w'])*S, (r['y']+k)*S), ((r['x']+r['w'])*S, (r['y']+min(k+2, r['h']))*S)], fill=P['hair'], width=S)
            text(d, r['x']+8, r['y']+16, 'Pool, Thu', P['ink3'], 10, 'ls'); continue
        due = any(h-.35 <= HOUR < h+.35 for h in r['at']); lit = due or (not day and r is now)
        if lit: d.rectangle(box, fill=tuple(int(a*.9+b*.1) for a, b in zip(P['bg'], P['gold'])))
        d.rectangle(box, outline=P['gold'] if lit else P['hair'], width=int((1.4 if lit else 1)*S))
        text(d, r['x']+8, r['y']+16, r['n'], P['ink'] if lit else P['ink2'], 11, 'ls', bold=lit)
        for i, h in enumerate(r['at']): dot(d, r['x']+r['w']-10-i*8, r['y']+r['h']-10, 1.8, fill=P['gold'] if h <= HOUR else P['ink3'])
    tx, ty = now['x']+now['w']/2, now['y']+now['h']/2+8
    dot(d, tx, ty, 4, fill=P['acc']); dot(d, tx, ty, 9, outline=tuple(int(a*.65+b*.35) for a, b in zip(P['bg'], P['acc'])))
    nxt = [r for r in DAILY if r['h'] > HOUR and not r.get('auto')]
    text(d, 348, 176, (nxt[0]['n']+' at '+fmt(nxt[0]['h'])) if nxt else 'Nothing more today', P['ink2'], 12, 'rs')
    return im

# ---- 3 polyrhythm
def pendula():
    im, d = new(); top = 6; baseY = 160
    allr = [dict(n=r['n'], per=1, phase=r['h']/24, done=state(r)) for r in DAILY if not r.get('auto')]
    allr += [dict(n=r['n'], per=7, phase=(r['wd']+r['h']/24)/7, done='done' if (r['wd']+r['h']/24) < (TODAY+HOUR/24) else 'wait') for r in WEEKLY]
    n = len(allr); gap = 330/(n-1); x0 = 12; t = TODAY+HOUR/24
    line(d, [(0, top), (354, top)], P['hair'])
    for i, r in enumerate(allr):
        x = x0+i*gap; L = 92 if r['per'] == 1 else 150
        ph = ((t/r['per'])-r['phase'])*TAU; ang = math.sin(ph)*.55
        bx, by = x+math.sin(ang)*L, top+math.cos(ang)*L
        near = abs(math.sin(ph)) < .08 and math.cos(ph) > 0
        line(d, [(x, top), (bx, by)], P['hair'])
        col = P['gold'] if r['done'] == 'done' else P['ink3'] if r['done'] == 'skipped' else (P['acc'] if near else P['ink'])
        dot(d, bx, by, 4 if r['per'] == 1 else 5.5, fill=col)
        if near: dot(d, bx, by, 10, outline=tuple(int(a*.6+b*.4) for a, b in zip(P['bg'], P['acc'])))
        if r['per'] == 7 or near: text(d, x, baseY+18, r['n'], P['ink2'], 9, 'ms')
    for yy in (top+92, top+150):
        for k in range(0, 354, 4): d.line([(k*S, yy*S), ((k+1)*S, yy*S)], fill=P['ink3'], width=S)
    return im

# ---- 4 sundial
def sundial():
    im, d = new(); cx, cy, rx, ry = 177, 120, 160, 58; rise, sset = 6.3, 19.4
    day = rise <= HOUR <= sset
    def ell(k, col, w=1): d.ellipse([(cx-rx+k)*S, (cy-ry+k*.36)*S, (cx+rx-k)*S, (cy+ry-k*.36)*S], outline=col, width=max(1, int(w*S)))
    ell(0, P['hair']); ell(26, P['hair'])
    def ang(h): return math.pi+(h-rise)/(sset-rise)*math.pi
    def nang(h): return TAU-((h+24 if h < rise else h)-sset)/(24-(sset-rise))*math.pi
    def pos(h, k):
        a = ang(h) if rise <= h <= sset else nang(h); return cx+math.cos(a)*(rx-k), cy+math.sin(a)*(ry-k*.36)
    for r in DAILY:
        x, y = pos(r['h'], 26); st = state(r)
        if r.get('auto'): dot(d, x, y, 2.6, outline=tone(st))
        else: dot(d, x, y, 3 if st == 'done' else 2.4, fill=tone(st))
        text(d, x, y+(-7 if y < cy else 13), r['n'], P['ink2'], 9, 'ms' if y < cy else 'ma')
    for r in WEEKLY:
        a = math.pi+((r['wd']+r['h']/24)/7)*TAU; x, y = cx+math.cos(a)*(rx-8), cy+math.sin(a)*(ry-3)
        past = (r['wd']+r['h']/24) < (TODAY+HOUR/24); dot(d, x, y, 2.6, fill=P['gold'] if past else P['ink'])
        text(d, x, y+(-6 if y < cy else 12), r['n']+' '+DAYS[r['wd']], P['ink3'], 9, 'ms' if y < cy else 'ma')
    line(d, [(cx, cy), (cx, cy-44)], P['ink'], 1.4)
    sa = (ang(HOUR) if day else nang(HOUR))+math.pi
    ln = (26+70*abs(math.cos(ang(HOUR)))) if day else 60
    sh = tuple(int(a*.45+b*.55) for a, b in zip(P['bg'], P['ink'])) if day else P['ink3']
    line(d, [(cx, cy), (cx+math.cos(sa)*ln, cy+math.sin(sa)*ln*.36)], sh, 3 if day else 1.2)
    text(d, 8, 176, 'Sun up' if day else 'Moon shadow', P['ink2'], 12, 'ls')
    return im

tiles = [('1. Record player', record()), ('2. Day map', daymap()), ('3. Polyrhythm', pendula()), ('4. Sundial', sundial())]
pad = 14*S; cap = 26*S
sheet = Image.new('RGB', (W*2+pad*3, (H+cap)*2+pad*3), P['bg']); sd = ImageDraw.Draw(sheet)
for i, (name, im) in enumerate(tiles):
    x = pad+(i % 2)*(W+pad); y = pad+(i//2)*(H+cap+pad)
    sd.text((x, y), name+f'   ({fmt(HOUR)}, {DAYS[TODAY]})', fill=P['ink2'], font=font(11), anchor='la')
    sheet.paste(im, (x, y+cap)); sd.rectangle([x, y+cap, x+W, y+cap+H], outline=P['hair'], width=S)
    im.save(f'263-{i+1}-{LOOK}-{int(HOUR*10)}.png')
out = f'263-sheet-{LOOK}-{int(HOUR*10)}.png'; sheet.save(out); print(out, sheet.size)
