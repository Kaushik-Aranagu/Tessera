# Board 264: three makeovers of the day map, rendered static with PIL in the standard slot.
import math, sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter

S = 3; W, H = 354*S, 182*S; TAU = math.pi*2
HOUR = float(sys.argv[1]) if len(sys.argv) > 1 else 17.6
LOOK = sys.argv[2] if len(sys.argv) > 2 else 'paper'
TODAY = 2; DAYS = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat']
if LOOK == 'paper':
    P = dict(bg=(247,245,241), ink=(36,36,35), ink2=(110,106,99), ink3=(169,164,155), hair=(196,194,189),
             acc=(142,74,120), gold=(126,106,30), lamp=(236,205,120), sun=(232,184,74), sky=(120,150,190))
else:
    P = dict(bg=(0,0,0), ink=(232,227,218), ink2=(164,158,150), ink3=(107,103,95), hair=(60,58,55),
             acc=(213,154,196), gold=(217,194,122), lamp=(236,205,120), sun=(232,184,74), sky=(90,110,150))
RISE, SET = 6.3, 19.4
DAY = RISE <= HOUR <= SET

def font(sz, bold=False):
    f = '/usr/share/fonts/truetype/dejavu/DejaVuSans%s.ttf' % ('-Bold' if bold else '')
    try: return ImageFont.truetype(f, int(sz*S))
    except Exception: return ImageFont.load_default()
def mix(a, b, t): return tuple(int(x*(1-t)+y*t) for x, y in zip(a, b))
def new(): im = Image.new('RGBA', (W, H), P['bg']+(255,)); return im, ImageDraw.Draw(im)
def pt(x, y): return (x*S, y*S)
def line(d, pts, col, w=1): d.line([pt(*p) for p in pts], fill=col, width=max(1, int(w*S)), joint='curve')
def dot(d, x, y, r, fill=None, outline=None, w=1): d.ellipse([(x-r)*S, (y-r)*S, (x+r)*S, (y+r)*S], fill=fill, outline=outline, width=int(w*S))
def text(d, x, y, s, col, sz=10, anchor='la', bold=False): d.text(pt(x, y), s, fill=col, font=font(sz, bold), anchor=anchor)
def rect(d, x, y, w, h, outline=None, fill=None, lw=1): d.rectangle([x*S, y*S, (x+w)*S, (y+h)*S], outline=outline, fill=fill, width=int(lw*S))
def fmt(h):
    hh = int(h); m = round((h-hh)*60); return f"{(hh+11)%12+1}{(':%02d'%m) if m else ''}{'am' if hh<12 else 'pm'}"
def glow(im, x, y, w, h, col, alpha, blur=10):
    ov = Image.new('RGBA', im.size, (0,0,0,0)); od = ImageDraw.Draw(ov)
    od.rectangle([x*S, y*S, (x+w)*S, (y+h)*S], fill=col+(alpha,))
    ov = ov.filter(ImageFilter.GaussianBlur(blur*S/3)); return Image.alpha_composite(im, ov)
def wall(d, pts, gaps=(), col=None, w=1.2):
    """polyline wall; gaps = list of (segment index, t0, t1) door openings"""
    col = col or P['ink']
    for i in range(len(pts)-1):
        (x0, y0), (x1, y1) = pts[i], pts[i+1]; cuts = sorted([(a, b) for s, a, b in gaps if s == i])
        t = 0.0
        for a, b in cuts + [(1.0, 1.0)]:
            if a > t: line(d, [(x0+(x1-x0)*t, y0+(y1-y0)*t), (x0+(x1-x0)*a, y0+(y1-y0)*a)], col, w)
            t = b

# ---- shared: what's in each place and when you're there (Tuesday)
# where-you-are schedule: (from, to, place)
SCHED = [(0, 6.5, 'bed'), (6.5, 7, 'kitchen'), (7, 7.8, 'gym'), (7.8, 8.4, 'kitchen'), (8.4, 12.5, 'desk'), (12.5, 13.3, 'kitchen'),
         (13.3, 17.5, 'desk'), (17.5, 18, 'kitchen'), (18, 19, 'park'), (19, 22, 'sofa'), (22, 22.6, 'desk'), (22.6, 24, 'bed')]
ROUT = {'bed': [('Water', 6.5, 1)], 'kitchen': [('Lunch', 12.5, 2), ('Tidy', 17.5, 3), ('Water plants', 8, 1, 'auto')], 'gym': [('Stretch', 7, 5)],
        'desk': [('Journal', 22, 3), ('Backup', 23, 1, 'auto')], 'park': [('Walk', 18, 1)], 'sofa': [], 'pool': [('Swim', 'Thu', 1)], 'court': [('Badminton', 'Sat', 1)], 'phone': [('Call family', 'Sun', 1)]}
def where(h):
    for a, b, p in SCHED:
        if a <= h < b: return p
    return 'bed'
def state(h):
    if h == 7: return 'skipped'  # Stretch skipped today
    return 'done' if h <= HOUR else 'wait'
def tone(st): return P['gold'] if st == 'done' else P['ink3'] if st == 'skipped' else P['ink']
def due_in(place):
    return any(isinstance(h, (int, float)) and h-.3 <= HOUR < h+.5 for _, h, *_ in ROUT.get(place, []))

# ================= A. the plan: a real flat, door gaps, a window, outside beyond the wall, today's trail
A_ROOMS = {'bed': (10, 12, 92, 66, 'Bed'), 'kitchen': (102, 12, 96, 66, 'Kitchen'), 'desk': (198, 12, 78, 100, 'Desk'),
           'gym': (10, 78, 92, 70, 'Gym'), 'sofa': (102, 78, 96, 70, 'Sofa'), 'hall': (198, 112, 78, 36, '')}
A_OUT = {'park': (300, 18, 'Park'), 'pool': (300, 70, 'Pool', 'Thu'), 'court': (300, 110, 'Court', 'Sat')}
def center(place):
    if place in A_ROOMS: x, y, w, h, _ = A_ROOMS[place]; return (x+w/2, y+h/2+6)
    if place in A_OUT: x, y = A_OUT[place][:2]; return (x+16, y+10)
    return (237, 130)
def planA():
    im, d = new()
    # outside margin: the street beyond the hall door, places appear on their days
    line(d, [(288, 0), (288, 182)], P['hair'])
    for k, v in A_OUT.items():
        x, y, n = v[:3]; day = v[3] if len(v) > 3 else None; today = day is None or day == DAYS[TODAY]
        col = P['ink2'] if today else P['ink3']
        dot(d, x+16, y+10, 9, outline=col if today else P['hair'], w=1)
        if not today:
            # dashed: not today
            for a in range(0, 360, 30): d.arc([(x+7)*S, (y+1)*S, (x+25)*S, (y+19)*S], a, a+14, fill=P['ink3'], width=S)
        text(d, x+16, y+26, n+('' if today else ' '+day), col, 9, 'ma')
    # sun through the kitchen window (top wall) moving with the hour
    if DAY:
        f = (HOUR-RISE)/(SET-RISE); wx = 150; sx = wx+(f-.5)*110
        ov = Image.new('RGBA', im.size, (0,0,0,0)); od = ImageDraw.Draw(ov)
        od.polygon([pt(wx-10, 12), pt(wx+10, 12), pt(sx+36, 78), pt(sx-16, 78)], fill=P['sun']+(26 if LOOK == 'paper' else 18,))
        im = Image.alpha_composite(im, ov); d = ImageDraw.Draw(im)
    # lamp glow in due room / the room you're in at night
    here = where(HOUR)
    for k, (x, y, w, h, n) in A_ROOMS.items():
        lit = due_in(k) or (not DAY and k == here)
        if lit: im = glow(im, x+4, y+4, w-8, h-8, P['lamp'], 70 if LOOK == 'paper' else 48, 8)
    d = ImageDraw.Draw(im)
    # walls: outer, with the front door gap on the right wall of the hall
    wall(d, [(10, 12), (276, 12), (276, 148), (10, 148), (10, 12)], gaps=[(1, .78, .92)], w=1.4)
    # inner walls with door gaps
    wall(d, [(102, 12), (102, 148)], gaps=[(0, .36, .5), (0, .72, .86)])       # bed|kitchen, gym|sofa
    wall(d, [(198, 12), (198, 148)], gaps=[(0, .3, .44), (0, .82, .96)])      # kitchen|desk, sofa|hall
    wall(d, [(10, 78), (198, 78)], gaps=[(0, .2, .32), (0, .6, .72)])         # bed/gym, kitchen/sofa
    wall(d, [(198, 112), (276, 112)], gaps=[(0, .5, .66)])                     # desk/hall
    # window on the kitchen's top wall
    line(d, [(140, 12), (160, 12)], P['sky'] if DAY else P['ink3'], 2.4)
    # room names + routine hooks along the top-left of each room
    for k, (x, y, w, h, n) in A_ROOMS.items():
        lit = due_in(k) or (not DAY and k == here)
        if n: text(d, x+7, y+9, n.upper(), P['ink'] if lit else P['ink2'], 7.5, 'la', bold=False)
        hx = x+7
        for r in ROUT.get(k, []):
            nm, hh, steps = r[0], r[1], r[2]; auto = len(r) > 3; st = state(hh)
            for s in range(steps):
                if auto: dot(d, hx+s*5, y+h-9, 1.6, outline=tone(st), w=.8)
                else: dot(d, hx+s*5, y+h-9, 2 if st == 'done' else 1.6, fill=tone(st))
            hx += steps*5+6
    # today's trail: where you've been, fading, as a soft line through the doorways
    path = []
    for a, b, p in SCHED:
        if a > HOUR: break
        path.append((center(p), a))
    for i in range(1, len(path)):
        age = (HOUR-path[i][1])/HOUR if HOUR else 0
        col = mix(P['acc'], P['bg'], min(.85, .35+age*.6))
        line(d, [path[i-1][0], path[i][0]], col, 1.2)
    # you
    cx, cy = center(here)
    dot(d, cx, cy, 3.6, fill=P['acc']); dot(d, cx, cy, 8, outline=mix(P['acc'], P['bg'], .55))
    # a line of type at the bottom: next thing and where
    nxt = None
    for k, rs in ROUT.items():
        for r in rs:
            if isinstance(r[1], (int, float)) and r[1] > HOUR and len(r) == 3 and (nxt is None or r[1] < nxt[1]): nxt = (r[0], r[1], k)
    text(d, 300, 170, (f"{nxt[0]} · {A_ROOMS.get(nxt[2], (0,0,0,0,nxt[2].title()))[4] or nxt[2].title()} · {fmt(nxt[1])}") if nxt else 'Nothing more today', P['ink2'], 8, 'ra')
    return im

# ================= B. from the street: the home as a facade of windows, places along the street
B_WIN = [('bed', 'Bed'), ('kitchen', 'Kitchen'), ('desk', 'Desk'), ('sofa', 'Sofa'), ('gym', 'Gym')]
def facadeB():
    im, d = new()
    here = where(HOUR)
    # ground and sky line
    gy = 150; line(d, [(0, gy), (354, gy)], P['ink'], 1.2)
    # sun / moon in the sky, real position
    if DAY:
        f = (HOUR-RISE)/(SET-RISE); sx, sy = 20+f*314, 40-math.sin(f*math.pi)*34
        dot(d, sx, sy, 5, fill=P['sun'])
    else:
        dot(d, 318, 22, 5, outline=P['ink2'], w=1)
    # house: one storey of windows, wide
    hx, hy, hw, hh = 22, 56, 190, 94
    rect(d, hx, hy, hw, hh, outline=P['ink'], lw=1.3)
    line(d, [(hx-8, hy), (hx+hw/2, hy-26), (hx+hw+8, hy)], P['ink'], 1.3)
    # windows
    n = len(B_WIN); ww, wh = 26, 30; gap = (hw-n*ww)/(n+1)
    for i, (k, nm) in enumerate(B_WIN):
        x = hx+gap+i*(ww+gap); y = hy+22
        lit = (k == here) or due_in(k)
        if lit and not DAY: im = glow(im, x-3, y-3, ww+6, wh+6, P['lamp'], 110, 7); d = ImageDraw.Draw(im)
        if lit: rect(d, x, y, ww, wh, fill=mix(P['bg'], P['lamp'], .55 if not DAY else .25))
        rect(d, x, y, ww, wh, outline=P['ink'] if lit else P['ink2'], lw=1)
        line(d, [(x+ww/2, y), (x+ww/2, y+wh)], P['ink3'], .8); line(d, [(x, y+wh/2), (x+ww, y+wh/2)], P['ink3'], .8)
        if k == here: dot(d, x+ww/2, y+wh/2+4, 3.4, fill=P['acc'])
        text(d, x+ww/2, y+wh+10, nm.upper(), P['ink'] if lit else P['ink3'], 6.5, 'ma')
        # routine hooks under the sill
        hx2 = x
        for r in ROUT.get(k, []):
            nm2, hh2, steps = r[0], r[1], r[2]; auto = len(r) > 3; st = state(hh2)
            for s in range(steps):
                if auto: dot(d, hx2+s*4.5, y+wh+18, 1.3, outline=tone(st), w=.7)
                else: dot(d, hx2+s*4.5, y+wh+18, 1.6 if st == 'done' else 1.3, fill=tone(st))
            hx2 += steps*4.5+4
    # door
    rect(d, hx+hw-30, hy+hh-34, 16, 34, outline=P['ink'], lw=1)
    # along the street: park (today), pool (Thu), court (Sat)
    for i, (k, nm, day) in enumerate([('park', 'Park', None), ('pool', 'Pool', 'Thu'), ('court', 'Court', 'Sat')]):
        x = 240+i*38; today = day is None or day == DAYS[TODAY]; col = P['ink2'] if today else P['ink3']
        if k == 'park':
            for t in range(3): dot(d, x+t*9, gy-10-(t % 2)*6, 5, outline=col, w=1); line(d, [(x+t*9, gy-5-(t % 2)*6), (x+t*9, gy)], col, 1)
        else:
            if today: rect(d, x, gy-22, 26, 22, outline=col)
            else:
                for a in range(0, 26, 5): line(d, [(x+a, gy-22), (x+a+2, gy-22)], col, 1)
                line(d, [(x, gy-22), (x, gy)], col, .8); line(d, [(x+26, gy-22), (x+26, gy)], col, .8)
        if k == here: dot(d, x+13, gy-30, 3.4, fill=P['acc'])
        text(d, x+13, gy+6, nm.upper()+('' if today else ' '+day.upper()), col, 6.5, 'ma')
    text(d, 8, 170, f"{DAYS[TODAY]}, {fmt(HOUR)}", P['ink2'], 8, 'la')
    return im

# ================= C. the territory: home as a small plan, the places of your week around it, today's route
def territoryC():
    im, d = new(); here = where(HOUR)
    places = {'home': (70, 92), 'desk': (70, 92), 'park': (175, 60), 'pool': (250, 120), 'court': (300, 44), 'phone': (330, 150)}
    # the park loop: the walk is literally a loop
    lx, ly = 175, 60
    d.ellipse([(lx-30)*S, (ly-18)*S, (lx+30)*S, (ly+18)*S], outline=P['ink2'] if HOUR >= 18 else P['hair'], width=S)
    if 18 <= HOUR < 19:  # on the walk: progress around the loop
        f = (HOUR-18); d.arc([(lx-30)*S, (ly-18)*S, (lx+30)*S, (ly+18)*S], 180, 180+f*360, fill=P['acc'], width=int(1.6*S))
    text(d, lx, ly+28, 'PARK · WALK 6PM', P['ink2'], 6.5, 'ma')
    # home: a tiny plan
    hx, hy = 28, 60; rect(d, hx, hy, 84, 64, outline=P['ink'], lw=1.2)
    line(d, [(hx+42, hy), (hx+42, hy+64)], P['hair']); line(d, [(hx, hy+32), (hx+84, hy+32)], P['hair'])
    for (k, nm, ox, oy) in [('bed', 'BED', 0, 0), ('kitchen', 'KITCHEN', 42, 0), ('gym', 'GYM', 0, 32), ('desk', 'DESK', 42, 32)]:
        lit = (k == here) or due_in(k)
        if lit: im = glow(im, hx+ox+3, hy+oy+3, 36, 26, P['lamp'], 80 if LOOK == 'paper' else 60, 6); d = ImageDraw.Draw(im)
        text(d, hx+ox+5, hy+oy+7, nm, P['ink'] if lit else P['ink3'], 6, 'la')
        kx = hx+ox+5
        for r in ROUT.get(k, []):
            st = state(r[1]); auto = len(r) > 3
            for s in range(r[2]):
                if auto: dot(d, kx+s*4.5, hy+oy+25, 1.3, outline=tone(st), w=.7)
                else: dot(d, kx+s*4.5, hy+oy+25, 1.6 if st == 'done' else 1.3, fill=tone(st))
            kx += r[2]*4.5+4
        if k == here: dot(d, hx+ox+21, hy+oy+16, 3.2, fill=P['acc'])
    text(d, hx+42, hy+72, 'HOME', P['ink2'], 6.5, 'ma')
    # weekly places: pool Thu, court Sat, family Sun (a phone line off the edge)
    for k, nm, day, (x, y) in [('pool', 'POOL · THU', 'Thu', places['pool']), ('court', 'COURT · SAT', 'Sat', places['court'])]:
        today = day == DAYS[TODAY]; col = P['ink'] if today else P['ink3']
        if today: rect(d, x-16, y-10, 32, 20, outline=col, lw=1.1)
        else:
            for a in range(-16, 16, 5): line(d, [(x+a, y-10), (x+a+2, y-10)], col, .9); line(d, [(x+a, y+10), (x+a+2, y+10)], col, .9)
            for a in range(-10, 10, 5): line(d, [(x-16, y+a), (x-16, y+a+2)], col, .9); line(d, [(x+16, y+a), (x+16, y+a+2)], col, .9)
        text(d, x, y+16, nm, col, 6.5, 'ma')
    # family: a line leaving the slot, Sunday
    fx, fy = places['phone']; col = P['ink'] if TODAY == 0 else P['ink3']
    for a in range(0, 40, 6): line(d, [(fx-a, fy-a*.5), (fx-a-3, fy-(a+3)*.5)], col, .9)
    text(d, fx-24, fy-30, 'FAMILY · SUN', col, 6.5, 'ma')
    # the ways between: faint hairlines home→park, home→pool, home→court
    for k in ('park', 'pool', 'court'):
        x, y = places[k]; line(d, [(hx+84, hy+32), (x-(30 if k == 'park' else 16), y)], P['hair'], .8)
    # today's route so far: home→park→home drawn warm
    if HOUR >= 18: line(d, [(hx+84, hy+32), (lx-30, ly)], mix(P['acc'], P['bg'], .4), 1.4)
    if HOUR >= 19: line(d, [(lx-30, ly+2), (hx+84, hy+34)], mix(P['acc'], P['bg'], .55), 1.4)
    if here == 'park': dot(d, lx-30, ly, 3.4, fill=P['acc'])
    text(d, 8, 170, f"{DAYS[TODAY]}, {fmt(HOUR)}", P['ink2'], 8, 'la')
    return im

tiles = [('A. The plan', planA()), ('B. From the street', facadeB()), ('C. The territory', territoryC())]
pad = 14*S; cap = 26*S
sheet = Image.new('RGB', (W+pad*2, (H+cap)*3+pad*4), P['bg']); sd = ImageDraw.Draw(sheet)
for i, (name, im) in enumerate(tiles):
    x = pad; y = pad+i*(H+cap+pad)
    sd.text((x, y), name+f'   ({fmt(HOUR)}, {DAYS[TODAY]})', fill=P['ink2'], font=font(11), anchor='la')
    sheet.paste(im.convert('RGB'), (x, y+cap)); sd.rectangle([x, y+cap, x+W, y+cap+H], outline=P['hair'], width=S)
out = f'264-sheet-{LOOK}-{int(HOUR*10)}.png'; sheet.save(out); print(out, sheet.size)
