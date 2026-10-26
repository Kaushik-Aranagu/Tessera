# Board 265: more ideas in the day-map register: literal, everyday, simple; expressive through real state.
import math, sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter
sys.argv = sys.argv[:1] + sys.argv[1:]
import importlib.util
spec = importlib.util.spec_from_file_location('r264', __file__.replace('render265', 'render264'))
# reuse helpers by exec-ing the helper half of render264 (everything before the tiles are built)
src = open(__file__.replace('render265', 'render264')).read().split('tiles = [')[0]
exec(src)

# ---- 1. the routine clock: an ordinary wall clock with your routines written at their hours
def clockface():
    im, d = new(); cx, cy, R = 100, 91, 74
    dot(d, cx, cy, R, outline=P['ink'], w=1.3)
    for h in range(12):
        a = -math.pi/2 + h*TAU/12; r0 = R-5 if h % 3 else R-8
        line(d, [(cx+math.cos(a)*r0, cy+math.sin(a)*r0), (cx+math.cos(a)*(R-1), cy+math.sin(a)*(R-1))], P['ink2'], 1 if h % 3 else 1.6)
    pm = HOUR >= 12
    # routines of this half-day written around the face at their hour, like notes stuck on a kitchen clock
    half = [(nm, hh, len(r) > 3) for k, rs in ROUT.items() for r in rs for nm, hh in [(r[0], r[1])] if isinstance(hh, (int, float)) and (hh >= 12) == pm]
    for nm, hh, auto in half:
        a = -math.pi/2 + ((hh % 12)/12)*TAU; st = state(hh)
        x, y = cx+math.cos(a)*(R+14), cy+math.sin(a)*(R+10)
        anchor = 'lm' if math.cos(a) > .3 else 'rm' if math.cos(a) < -.3 else ('mb' if math.sin(a) < 0 else 'mt')
        text(d, x, y, nm, tone(st) if st != 'wait' else P['ink'], 8, anchor)
        dot(d, cx+math.cos(a)*(R-12), cy+math.sin(a)*(R-12), 2.2 if st == 'done' else 1.8, fill=None if auto else tone(st), outline=tone(st) if auto else None, w=.8)
    # hands: real time
    ha = -math.pi/2 + ((HOUR % 12)/12)*TAU; ma = -math.pi/2 + (HOUR % 1)*TAU
    line(d, [(cx, cy), (cx+math.cos(ha)*(R*.55), cy+math.sin(ha)*(R*.55))], P['ink'], 2.2)
    line(d, [(cx, cy), (cx+math.cos(ma)*(R*.8), cy+math.sin(ma)*(R*.8))], P['ink'], 1.2)
    dot(d, cx, cy, 2.2, fill=P['ink'])
    # the other half of the day, small, at the right: what the clock said this morning / will say tonight
    text(d, 236, 40, ('This morning' if pm else 'Tonight').upper(), P['ink3'], 6.5, 'la')
    other = [(nm, hh, len(r) > 3) for k, rs in ROUT.items() for r in rs for nm, hh in [(r[0], r[1])] if isinstance(hh, (int, float)) and (hh >= 12) != pm]
    for i, (nm, hh, auto) in enumerate(sorted(other, key=lambda t: t[1])):
        st = state(hh); text(d, 236, 54+i*14, f"{fmt(hh):>7}  {nm}", tone(st) if st != 'wait' else P['ink2'], 8, 'la')
    text(d, 236, 150, 'Swim Thu · Badminton Sat · Family Sun', P['ink3'], 6.5, 'la')
    return im

# ---- 2. the day as a sentence of places: type only
def sentence():
    im, d = new()
    here = where(HOUR); words = []
    seen = []
    for a, b, p in SCHED:
        words.append((p, a, b))
    x, y = 10, 60; lineh = 30; maxw = 340
    for i, (p, a, b) in enumerate(words):
        nm = {'bed': 'Bed', 'kitchen': 'Kitchen', 'gym': 'Gym', 'desk': 'Desk', 'park': 'Park', 'sofa': 'Sofa'}[p]
        now = a <= HOUR < b; past = b <= HOUR
        col = P['ink'] if now else (P['gold'] if past else P['ink2'])
        f = font(16 if now else 13, bold=now)
        w = d.textlength(nm, font=f)/S
        if x + w > maxw: x = 10; y += lineh
        d.text(pt(x, y), nm, fill=col, font=f, anchor='ls')
        # routine marks under the word
        rs = [r for r in ROUT.get(p, []) if isinstance(r[1], (int, float)) and a <= r[1] < b]
        mx = x
        for r in rs:
            st = state(r[1]); auto = len(r) > 3
            for s in range(r[2]):
                if auto: dot(d, mx+1.5+s*4.5, y+6, 1.3, outline=tone(st), w=.7)
                else: dot(d, mx+1.5+s*4.5, y+6, 1.6 if st == 'done' else 1.3, fill=tone(st))
            mx += r[2]*4.5+4
        if now: dot(d, x+w+8, y-5, 3.2, fill=P['acc'])
        x += w + (22 if now else 16)
        if i < len(words)-1:
            d.text(pt(x-9 if now else x-8, y-1), '·', fill=P['ink3'], font=font(12), anchor='mm')
    text(d, 10, 170, f"{DAYS[TODAY]}. Then Thursday has the pool in it.", P['ink3'], 8, 'ls')
    return im

# ---- 3. the hooks by the door: the things your routines need; a hook is empty while you're out doing it
HOOKS = [('Bottle', 'kitchen', 6.5), ('Mat', 'gym', 7), ('Can', 'kitchen', 8), ('Bowl', 'kitchen', 12.5), ('Cloth', 'kitchen', 17.5), ('Shoes', 'park', 18), ('Pen', 'desk', 22),
         ('Towel', 'pool', 'Thu'), ('Racket', 'court', 'Sat')]
def hooks():
    im, d = new(); here = where(HOUR)
    ry = 46; line(d, [(14, ry), (340, ry)], P['ink'], 1.3)
    n = len(HOOKS); gap = 326/n
    for i, (nm, place, hh) in enumerate(HOOKS):
        x = 14+gap/2+i*gap
        weekly = isinstance(hh, str); today = (not weekly) or hh == DAYS[TODAY]
        line(d, [(x, ry), (x, ry+8)], P['ink'] if today else P['ink3'], 1.2); dot(d, x, ry+9, 1.6, fill=P['ink'] if today else P['ink3'])
        out = (not weekly) and (place == here) and (hh-.2 <= HOUR < hh+1.2)   # in use right now: hook empty
        st = 'wait' if weekly else state(hh)
        if out:
            # the empty hook, and a note of where the thing is
            text(d, x, ry+44, nm.upper(), P['ink3'], 6.5, 'ma')
            text(d, x, ry+56, f"with you,\n{place}", P['acc'], 6, 'ma')
        else:
            # the thing: its name hanging, as a tag; done today = gold tag
            col = tone(st) if today else P['ink3']
            w = d.textlength(nm.upper(), font=font(7))/S+10
            line(d, [(x, ry+10), (x, ry+22)], P['hair'], .8)
            rect(d, x-w/2, ry+22, w, 16, outline=col, lw=1 if today else .8)
            text(d, x, ry+30, nm.upper(), col, 7, 'mm')
            if weekly: text(d, x, ry+44, hh.upper(), P['ink3'], 6, 'ma')
    text(d, 14, 170, 'Shoes are out: you are on the walk. Cloth is back, gold: Tidy done.' if 18 <= HOUR < 19.2 else f"{DAYS[TODAY]}, {fmt(HOUR)}. Everything on its hook.", P['ink3'], 8, 'ls')
    return im

# ---- 4. the week of plans: seven tiny day maps, today's live and larger; the weekly loop shows itself
def week():
    im, d = new()
    cell = 36; x0 = 10; yb = 60
    for wd in range(7):
        is_t = wd == TODAY; sc = 1.9 if is_t else 1
        w = cell*sc; h = 26*sc
        x = x0 + sum((cell*1.9 if k == TODAY else cell)+8 for k in range(wd)); y = yb+(0 if is_t else (h*0.9/2))
        col = P['ink'] if is_t else P['ink2'] if wd < TODAY else P['ink3']
        rect(d, x, y, w, h, outline=col, lw=1.2 if is_t else .9)
        line(d, [(x+w/2, y), (x+w/2, y+h)], P['hair'], .8); line(d, [(x, y+h/2), (x+w, y+h/2)], P['hair'], .8)
        # pool on Thursday, court on Saturday, family on Sunday: the week has different rooms
        extra = {4: 'POOL', 6: 'COURT', 0: 'FAMILY'}.get(wd)
        if extra:
            ex = x+w+3 if not is_t else x+w+4
            rect(d, x+w*.62, y+h+4, w*.38, 7*sc, outline=col, lw=.8)
            if is_t: text(d, x+w*.81, y+h+4+3.5*sc, extra, col, 5.5, 'mm')
        if is_t:
            here = where(HOUR)
            for (k, nm, ox, oy) in [('bed', 'BED', 0, 0), ('kitchen', 'KITCHEN', w/2, 0), ('gym', 'GYM', 0, h/2), ('desk', 'DESK', w/2, h/2)]:
                lit = (k == here) or due_in(k)
                if lit: im = glow(im, x+ox+2, y+oy+2, w/2-4, h/2-4, P['lamp'], 90 if LOOK == 'paper' else 60, 5); d = ImageDraw.Draw(im)
                text(d, x+ox+4, y+oy+6, nm, P['ink'] if lit else P['ink3'], 5.5, 'la')
                kx = x+ox+4
                for r in ROUT.get(k, []):
                    st = state(r[1]); auto = len(r) > 3
                    for s in range(r[2]):
                        if auto: dot(d, kx+s*3.6, y+oy+h/2-5, 1.1, outline=tone(st), w=.6)
                        else: dot(d, kx+s*3.6, y+oy+h/2-5, 1.3 if st == 'done' else 1.1, fill=tone(st))
                    kx += r[2]*3.6+3
                if k == here: dot(d, x+ox+w/4, y+oy+h/4+3, 2.6, fill=P['acc'])
            if here == 'park': dot(d, x+w+10, y+6, 2.6, fill=P['acc']); text(d, x+w+16, y+8, 'PARK', P['ink2'], 5.5, 'lm')
        else:
            # past days: which rooms got their routines (gold dots), future: grey
            for (k, ox, oy) in [('bed', 0, 0), ('kitchen', w/2, 0), ('gym', 0, h/2), ('desk', w/2, h/2)]:
                rs = [r for r in ROUT.get(k, []) if isinstance(r[1], (int, float))]
                for j, r in enumerate(rs):
                    done = wd < TODAY and not (wd == 1 and r[0] == 'Journal')  # Monday's journal missed
                    dot(d, x+ox+4+j*4, y+oy+h/2-4, 1.1, fill=P['gold'] if done else P['ink3'] if wd < TODAY else None, outline=None if wd < TODAY else P['ink3'], w=.6)
        text(d, x+w/2, y+h+(16 if is_t else 12)+(7*sc+2 if extra else 0), DAYS[wd].upper(), col, 6.5 if is_t else 6, 'ma')
    text(d, 10, 170, 'Monday missed Journal. Thursday has the pool. Today is the big one.', P['ink3'], 8, 'ls')
    return im

tiles = [('1. The clock on the wall', clockface()), ('2. The day as a sentence', sentence()), ('3. The hooks by the door', hooks()), ('4. The week of plans', week())]
pad = 14*S; cap = 26*S
sheet = Image.new('RGB', (W+pad*2, (H+cap)*4+pad*5), P['bg']); sd = ImageDraw.Draw(sheet)
for i, (name, im) in enumerate(tiles):
    x = pad; y = pad+i*(H+cap+pad)
    sd.text((x, y), name+f'   ({fmt(HOUR)}, {DAYS[TODAY]})', fill=P['ink2'], font=font(11), anchor='la')
    sheet.paste(im.convert('RGB'), (x, y+cap)); sd.rectangle([x, y+cap, x+W, y+cap+H], outline=P['hair'], width=S)
out = f'265-sheet-{LOOK}-{int(HOUR*10)}.png'; sheet.save(out); print(out, sheet.size)
