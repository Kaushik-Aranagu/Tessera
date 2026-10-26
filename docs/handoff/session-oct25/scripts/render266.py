# Board 266: the garden, two directions on real material. A: windowsill (real sky plate + real pots). B: woodland (real grove).
import math, sys, os
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageEnhance, ImageOps

S = 3; W, H = 354*S, 182*S
HOUR = float(sys.argv[1]) if len(sys.argv) > 1 else 17.6
LOOK = sys.argv[2] if len(sys.argv) > 2 else 'paper'
DL = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'plates-dl')
SKY = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'Tessera/docs/handoff/design-sheets/weather-plates')
NIGHT = HOUR < 6.3 or HOUR > 19.4
DUSK = 17.5 <= HOUR <= 19.4
if LOOK == 'paper': P = dict(bg=(247,245,241), ink=(36,36,35), ink2=(110,106,99), ink3=(169,164,155), hair=(196,194,189), acc=(142,74,120), gold=(126,106,30))
else: P = dict(bg=(0,0,0), ink=(232,227,218), ink2=(164,158,150), ink3=(107,103,95), hair=(60,58,55), acc=(213,154,196), gold=(217,194,122))

def font(sz, bold=False):
    try: return ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans%s.ttf' % ('-Bold' if bold else ''), int(sz*S))
    except Exception: return ImageFont.load_default()
def text(d, x, y, s, col, sz=10, anchor='la', bold=False): d.text((x*S, y*S), s, fill=col, font=font(sz, bold), anchor=anchor)
def dot(d, x, y, r, fill=None, outline=None, w=1): d.ellipse([(x-r)*S, (y-r)*S, (x+r)*S, (y+r)*S], fill=fill, outline=outline, width=int(w*S))
def line(d, pts, col, w=1): d.line([(x*S, y*S) for x, y in pts], fill=col, width=max(1, int(w*S)))

def keyout(path, lo=170, hi=228):
    """white background to alpha, soft ramp; also pull white fringe toward the object color"""
    im = Image.open(path).convert('RGB'); g = ImageOps.grayscale(im)
    # alpha from min channel (white = all channels high)
    r, gch, b = im.split(); mn = Image.eval(Image.merge('RGB', (r, gch, b)).convert('L'), lambda v: v)
    px = im.load(); a = Image.new('L', im.size); ap = a.load(); W_, H_ = im.size
    for y in range(H_):
        for x in range(W_):
            m = min(px[x, y]); ap[x, y] = 255 if m < lo else 0 if m > hi else int(255*(hi-m)/(hi-lo))
    a = a.filter(ImageFilter.MinFilter(5)).filter(ImageFilter.GaussianBlur(0.8))
    # decontaminate the white fringe: un-premultiply against white
    out = im.copy(); op = out.load(); ap2 = a.load()
    for y in range(H_):
        for x in range(W_):
            al = ap2[x, y]
            if 0 < al < 255:
                f = al/255.0; r_, g_, b_ = op[x, y]
                op[x, y] = tuple(max(0, min(255, int((c-(1-f)*255)/f))) for c in (r_, g_, b_))
    out.putalpha(a)
    return out.crop(a.getbbox())

def sky_plate():
    name = 'clear-night-1.jpg' if NIGHT else 'clear-dusk-1.jpg' if DUSK else 'broken-day-1.jpg'
    return Image.open(os.path.join(SKY, name)).convert('RGB')

def shadow(base, box, alpha=90, blur=6):
    ov = Image.new('RGBA', base.size, (0,0,0,0)); od = ImageDraw.Draw(ov)
    od.ellipse(box, fill=(20, 14, 8, alpha)); ov = ov.filter(ImageFilter.GaussianBlur(blur*S/3)); return Image.alpha_composite(base, ov)

# ============ A. the windowsill
PLANTS = [  # (file, routine, period, state, scale) state: tended | thirsty | wilting | weekly-wait | weekly-done
    ('pot-oregano.jpg', 'Water', 'daily', 'tended', 1.0),
    ('pot-ivy.jpg', 'Journal', 'daily', 'wilting', 1.0),          # three days dry
    ('pot-succulent.jpg', 'Swim', 'Thu', 'weekly', .95),
    ('pots-mini.jpg', 'New', 'daily', 'empty', .5),              # an empty pot: a routine not planted yet
]
def windowsill():
    im = Image.new('RGBA', (W, H), P['bg']+(255,))
    # the window: the sky plate fills the upper part; a sill of real wood across the bottom
    sky = sky_plate(); sw, sh = sky.size; sill_y = 134
    # crop a 354 x sill_y region from the plate, centred, upper-middle
    ar = W/(sill_y*S); cw = sw; ch = int(cw/ar)
    if ch > sh: ch = sh; cw = int(ch*ar)
    cx0 = (sw-cw)//2; cy0 = int((sh-ch)*0.35)
    glass = sky.crop((cx0, cy0, cx0+cw, cy0+ch)).resize((W, sill_y*S), Image.LANCZOS)
    if LOOK == 'black' and not NIGHT: glass = ImageEnhance.Brightness(glass).enhance(.85)
    im.paste(glass, (0, 0))
    # window frame: the glass is simply the slot; one thin mullion, the approved soft edge rather than a drawn frame
    d = ImageDraw.Draw(im)
    # the sill: wood texture, perspective-less, with a front edge
    wood = Image.open(os.path.join(DL, 'wood.jpg')).convert('RGB').resize((W, (H-sill_y*S)+40))
    wood = ImageEnhance.Brightness(wood).enhance(.55 if NIGHT else 1.0)
    im.paste(wood, (0, sill_y*S))
    d = ImageDraw.Draw(im)
    # sill top highlight and front edge
    line(d, [(0, sill_y), (354, sill_y)], (255, 240, 210) if not NIGHT else (120, 100, 80), .8)
    line(d, [(0, sill_y+14), (354, sill_y+14)], (40, 22, 10), 1)
    # pots across the sill, sitting on it (bottoms at sill_y+10)
    n = len(PLANTS); slots = [52, 148, 236, 316]
    for (f, name, per, st, sc), px in zip(PLANTS, slots):
        pl = keyout(os.path.join(DL, f))
        if f == 'pots-mini.jpg': pl = pl.crop((0, 0, int(pl.width*0.46), pl.height)); pl = pl.crop(pl.split()[3].getbbox())
        target_h = int(78*S*sc); pl = pl.resize((int(pl.width*target_h/pl.height), target_h), Image.LANCZOS)
        if st == 'thirsty': pl = pl.rotate(-4, resample=Image.BICUBIC, expand=True); pl = ImageEnhance.Color(pl).enhance(.85)
        if st == 'wilting':
            pl = pl.rotate(-9, resample=Image.BICUBIC, expand=True)
            rgb = ImageEnhance.Color(pl.convert('RGB')).enhance(.45); rgb = Image.blend(rgb, Image.new('RGB', rgb.size, (150, 120, 70)), .22)
            a = pl.split()[3]; pl = rgb.convert('RGBA'); pl.putalpha(a)
        if NIGHT: pl = Image.composite(ImageEnhance.Brightness(pl).enhance(.5), pl, pl.split()[3]);
        x = px*S-pl.width//2; y = (sill_y+10)*S-pl.height
        im = shadow(im, [x+pl.width*.15, (sill_y+2)*S, x+pl.width*.85, (sill_y+16)*S], 110 if not NIGHT else 60)
        im.alpha_composite(pl, (x, y))
    d = ImageDraw.Draw(im)
    # the gold mark: a watered pot today gets a small mark at its base, on the sill; weekly shows its day
    for (f, name, per, st, sc), px in zip(PLANTS, slots):
        if st == 'tended': dot(d, px, sill_y+21, 2.2, fill=P['gold'])
        label = name if per == 'daily' else f"{name} · {per}"
        col = (235, 225, 205) if LOOK == 'black' or NIGHT else (250, 240, 220)
        text(d, px, sill_y+32, label.upper(), col if st != 'wilting' else (210, 180, 150), 6.5, 'ma')
    # Tess's one line, on the glass, lower left
    msg = 'The ivy has been dry since Saturday.' if not NIGHT else 'Journal is the last pot. Then lights out.'
    ov = Image.new('RGBA', im.size, (0,0,0,0)); od = ImageDraw.Draw(ov)
    od.text((10*S, 22*S), msg, fill=(255,255,255,235) if (NIGHT or DUSK) else (30,30,30,210), font=font(9), anchor='ls')
    im = Image.alpha_composite(im, ov)
    return im

# ============ B. the woodland, on a real grove
TREES = [  # x (pt) at the base line in the crop, routine, state
    (62, 'Water', 'tended'), (118, 'Stretch', 'skipped'), (176, 'Lunch', 'tended'), (236, 'Walk', 'next'), (296, 'Journal', 'wilting'),
]
WEEKLY = [(90, 'Swim · Thu'), (210, 'Badminton · Sat'), (330, 'Family · Sun')]
def woodland():
    src = Image.open(os.path.join(DL, 'hdri-misty_pines.jpg')).convert('RGB'); sw, sh = src.size
    # crop around the horizon: a 2:1 window, ~100 degrees wide, horizon at ~62% down the slot
    cw = int(sw*0.28); ch = int(cw*H/W); cx0 = int(sw*0.36); cy0 = int(sh*0.5 - ch*0.62)
    im = src.crop((cx0, cy0, cx0+cw, cy0+ch)).resize((W, H), Image.LANCZOS).convert('RGBA')
    if NIGHT: im = ImageEnhance.Brightness(im).enhance(.35).convert('RGBA'); im = Image.blend(im, Image.new('RGBA', im.size, (20, 30, 50, 255)), .25)
    elif DUSK: im = Image.blend(im, Image.new('RGBA', im.size, (230, 160, 90, 255)), .14)
    # wilting: a local desaturation + browning around that tree (a soft mask), not a drawn tree
    for x, name, st in TREES:
        if st == 'wilting':
            mask = Image.new('L', im.size, 0); md = ImageDraw.Draw(mask)
            md.ellipse([(x-34)*S, 10*S, (x+34)*S, 140*S], fill=255); mask = mask.filter(ImageFilter.GaussianBlur(14*S/3))
            dry = ImageEnhance.Color(im.convert('RGB')).enhance(.3); dry = Image.blend(dry, Image.new('RGB', dry.size, (140, 110, 70)), .3)
            im = Image.composite(dry.convert('RGBA'), im, mask)
    d = ImageDraw.Draw(im)
    base = 118  # ground line where the trees stand, in pt
    for x, name, st in TREES:
        col = P['gold'] if st == 'tended' else (200, 200, 200) if st == 'skipped' else (255, 255, 255)
        if st == 'tended': dot(d, x, base, 2.6, fill=(217, 194, 122))
        elif st == 'skipped': dot(d, x, base, 2.2, outline=(220, 220, 220), w=.8)
        elif st == 'next': dot(d, x, base, 2.6, fill=(213, 154, 196)); dot(d, x, base, 7, outline=(213, 154, 196, 160), w=.8)
        else: dot(d, x, base, 2.2, outline=(200, 170, 130), w=.8)
        # a hairline from the base down to the name, written on the ground
        line(d, [(x, base+4), (x, base+16)], (255, 255, 255), .6)
        text(d, x, base+26, name.upper(), (245, 245, 240) if st != 'wilting' else (220, 190, 150), 6.5, 'ma')
    # weekly ones stand further back, in the mist: smaller names higher up on the ground
    wk = (235, 235, 235) if NIGHT else (70, 70, 70)
    for x, name in WEEKLY: dot(d, x, base-22, 1.6, fill=wk); text(d, x, base-28, name.upper(), wk, 5.5, 'ma')
    # Tess
    ov = Image.new('RGBA', im.size, (0,0,0,0)); od = ImageDraw.Draw(ov)
    od.text((10*S, 20*S), 'Journal has gone grey. Three evenings.', fill=(40, 40, 40, 230) if not NIGHT else (240, 240, 240, 230), font=font(9), anchor='ls')
    im = Image.alpha_composite(im, ov)
    return im

tiles = [('A. The windowsill', windowsill()), ('B. The woodland', woodland())]
pad = 14*S; cap = 26*S
sheet = Image.new('RGB', (W+pad*2, (H+cap)*2+pad*3), P['bg']); sd = ImageDraw.Draw(sheet)
def fmt(h):
    hh = int(h); m = round((h-hh)*60); return f"{(hh+11)%12+1}{(':%02d'%m) if m else ''}{'am' if hh<12 else 'pm'}"
for i, (name, im) in enumerate(tiles):
    x = pad; y = pad+i*(H+cap+pad)
    sd.text((x, y), f"{name}   ({fmt(HOUR)}, Tue)", fill=P['ink2'], font=font(11), anchor='la')
    sheet.paste(im.convert('RGB'), (x, y+cap)); sd.rectangle([x, y+cap, x+W, y+cap+H], outline=P['hair'], width=S)
    im.convert('RGB').save(f"266-{'A' if i == 0 else 'B'}-{LOOK}-{int(HOUR*10)}.png")
out = f'266-sheet-{LOOK}-{int(HOUR*10)}.png'; sheet.save(out); print(out, sheet.size)
