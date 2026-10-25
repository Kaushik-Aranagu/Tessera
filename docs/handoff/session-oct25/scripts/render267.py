# Board 267: the windowsill as function. Frame strips: watering (the check-off), neglect and the sweep.
import math, sys, os, random
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageEnhance, ImageOps
sys.argv = [sys.argv[0], sys.argv[1] if len(sys.argv) > 1 else '22.6', sys.argv[2] if len(sys.argv) > 2 else 'black']
src = open(__file__.replace('render267', 'render266')).read().split('tiles = [')[0]
exec(src)
random.seed(3)

CAN = None
def can_plate():
    global CAN
    if CAN is None:
        c = keyout(os.path.join(DL, 'can-silver.jpg'), lo=150, hi=226)
        CAN = ImageOps.mirror(c)  # spout to the left
    return CAN

def plant_plate(f, sc, rot=0.0, sat=1.0, brown=0.0, night=False):
    pl = keyout(os.path.join(DL, f))
    if f == 'pots-mini.jpg': pl = pl.crop((0, 0, int(pl.width*0.46), pl.height)); pl = pl.crop(pl.split()[3].getbbox())
    th = int(78*S*sc); pl = pl.resize((int(pl.width*th/pl.height), th), Image.LANCZOS)
    if rot: pl = pl.rotate(rot, resample=Image.BICUBIC, expand=True)
    if sat != 1.0 or brown:
        rgb = ImageEnhance.Color(pl.convert('RGB')).enhance(sat)
        if brown: rgb = Image.blend(rgb, Image.new('RGB', rgb.size, (150, 120, 70)), brown)
        a = pl.split()[3]; pl = rgb.convert('RGBA'); pl.putalpha(a)
    if night: pl = Image.composite(ImageEnhance.Brightness(pl).enhance(.5), pl, pl.split()[3])
    return pl

def sill_frame(plants, tess='', touch=None, can=None, water=0.0, leaves=(), gold=(), lamp=None):
    """plants: list of (file, label, slot_x, sc, rot, sat, brown). can: (x, y, tilt). water 0..1 pours from spout to touch pot."""
    im = Image.new('RGBA', (W, H), P['bg']+(255,))
    sky = sky_plate(); sw, sh = sky.size; sill_y = 134
    ar = W/(sill_y*S); cw = sw; ch = int(cw/ar)
    if ch > sh: ch = sh; cw = int(ch*ar)
    cx0 = (sw-cw)//2; cy0 = int((sh-ch)*0.35)
    glass = sky.crop((cx0, cy0, cx0+cw, cy0+ch)).resize((W, sill_y*S), Image.LANCZOS)
    im.paste(glass, (0, 0))
    wood = Image.open(os.path.join(DL, 'wood.jpg')).convert('RGB').resize((W, (H-sill_y*S)+40))
    wood = ImageEnhance.Brightness(wood).enhance(.55 if NIGHT else 1.0); im.paste(wood, (0, sill_y*S))
    # lamp: at night one warm pool of light on the sill where the work is
    if lamp is not None:
        ov = Image.new('RGBA', im.size, (0,0,0,0)); od = ImageDraw.Draw(ov)
        od.ellipse([(lamp-70)*S, (sill_y-80)*S, (lamp+70)*S, (sill_y+40)*S], fill=(255, 200, 120, 70)); ov = ov.filter(ImageFilter.GaussianBlur(26*S/3))
        im = Image.alpha_composite(im, ov)
    d = ImageDraw.Draw(im)
    line(d, [(0, sill_y), (354, sill_y)], (255, 240, 210) if not NIGHT else (120, 100, 80), .8)
    line(d, [(0, sill_y+14), (354, sill_y+14)], (40, 22, 10), 1)
    # fallen leaves on the sill
    for (lx, ly, la, lc) in leaves:
        ov = Image.new('RGBA', im.size, (0,0,0,0)); od = ImageDraw.Draw(ov)
        leaf = Image.new('RGBA', (16*S, 9*S), (0,0,0,0)); ld = ImageDraw.Draw(leaf); ld.ellipse([0, 0, 16*S-1, 9*S-1], fill=lc+(230,))
        leaf = leaf.rotate(la, expand=True); ov.alpha_composite(leaf, (int(lx*S), int(ly*S))); im = Image.alpha_composite(im, ov)
    # plants
    for (f, label, px, sc, rot, sat, brown) in plants:
        pl = plant_plate(f, sc, rot, sat, brown, night=NIGHT and lamp is None or (NIGHT and abs(px-(lamp or -999)) > 90))
        x = px*S-pl.width//2; y = (sill_y+10)*S-pl.height
        im = shadow(im, [x+pl.width*.15, (sill_y+2)*S, x+pl.width*.85, (sill_y+16)*S], 110 if not NIGHT else 60)
        im.alpha_composite(pl, (x, y))
    d = ImageDraw.Draw(im)
    for (f, label, px, sc, rot, sat, brown) in plants:
        if label in gold: dot(d, px, sill_y+21, 2.2, fill=P['gold'])
        col = (235, 225, 205); text(d, px, sill_y+32, label.upper(), col if brown < .1 else (210, 180, 150), 6.5, 'ma')
    # the touch: a soft ring where the finger holds the pot
    if touch is not None:
        ov = Image.new('RGBA', im.size, (0,0,0,0)); od = ImageDraw.Draw(ov)
        tx, ty = touch; od.ellipse([(tx-16)*S, (ty-16)*S, (tx+16)*S, (ty+16)*S], fill=(255, 255, 255, 60)); od.ellipse([(tx-16)*S, (ty-16)*S, (tx+16)*S, (ty+16)*S], outline=(255, 255, 255, 170), width=S)
        im = Image.alpha_composite(im, ov)
    # the can, tipped, and the water
    if can is not None:
        cx, cy, tilt = can; c = can_plate(); th = int(70*S); c = c.resize((int(c.width*th/c.height), th), Image.LANCZOS).rotate(tilt, resample=Image.BICUBIC, expand=True)
        if NIGHT: c = Image.composite(ImageEnhance.Brightness(c).enhance(.7), c, c.split()[3])
        im.alpha_composite(c, (int(cx*S-c.width/2), int(cy*S-c.height/2)))
        if water > 0 and touch is not None:
            ov = Image.new('RGBA', im.size, (0,0,0,0)); od = ImageDraw.Draw(ov)
            sx, sy = cx-c.width/(2*S)+10, cy+4   # spout tip, roughly, lower-left of the can
            ex, ey = touch[0], sill_y-6
            for k in range(7):
                jitter = (k-3)*1.2
                pts = [(sx+jitter*.3, sy), ((sx+ex)/2+jitter, sy+(ey-sy)*.55*water), (ex+jitter*1.6, sy+(ey-sy)*water)]
                od.line([(x*S, y*S) for x, y in pts], fill=(220, 240, 255, 150-abs(k-3)*25), width=max(1, int(1.1*S)))
            if water > .8:
                for k in range(14):
                    a = random.random()*math.pi; r = 6+random.random()*16
                    od.ellipse([(ex+math.cos(a)*r-1)*S, (ey+8-math.sin(a)*r*.3-1)*S, (ex+math.cos(a)*r+1)*S, (ey+8-math.sin(a)*r*.3+1)*S], fill=(230, 245, 255, 170))
            ov = ov.filter(ImageFilter.GaussianBlur(0.8)); im = Image.alpha_composite(im, ov)
    if tess:
        ov = Image.new('RGBA', im.size, (0,0,0,0)); od = ImageDraw.Draw(ov)
        od.text((10*S, 22*S), tess, fill=(255,255,255,235) if (NIGHT or DUSK) else (30,30,30,210), font=font(9), anchor='ls')
        im = Image.alpha_composite(im, ov)
    return im

# ---- the cast (file, label, x, scale, rot, sat, brown)
THYME = ('pot-oregano.jpg', 'Water', 52, 1.0, 0, 1, 0)
IVY_DRY = ('pot-ivy.jpg', 'Journal', 148, 1.0, -9, .45, .22)
IVY_MID = ('pot-ivy.jpg', 'Journal', 148, 1.0, -4, .75, .08)
IVY_OK = ('pot-ivy.jpg', 'Journal', 148, 1.0, 0, 1, 0)
SUCC = ('pot-succulent.jpg', 'Swim · Thu', 236, .95, 0, 1, 0)
EMPTY = ('pots-mini.jpg', 'New', 316, .5, 0, 1, 0)

def strip(frames, name):
    pad = 10*S; cap = 22*S
    sheet = Image.new('RGB', (W*2+pad*3, (H+cap)*2+pad*3), P['bg']); sd = ImageDraw.Draw(sheet)
    for i, (label, im) in enumerate(frames):
        x = pad+(i % 2)*(W+pad); y = pad+(i//2)*(H+cap+pad)
        sd.text((x, y+2*S), label, fill=P['ink2'], font=font(9), anchor='la')
        sheet.paste(im.convert('RGB'), (x, y+cap)); sd.rectangle([x, y+cap, x+W, y+cap+H], outline=P['hair'], width=S)
    sheet.save(name); print(name, sheet.size)

if __name__ == '__main__':
    which = sys.argv[3] if len(sys.argv) > 3 else 'water'
    if which == 'water':
        pot = (148, 118)
        f1 = sill_frame([THYME, IVY_DRY, SUCC, EMPTY], tess='You water this one at ten, usually. It is 10:40.', gold=('Water',), lamp=148)
        f2 = sill_frame([THYME, IVY_DRY, SUCC, EMPTY], tess='', touch=pot, can=(196, 52, 28), water=.35, gold=('Water',), lamp=148)
        f3 = sill_frame([THYME, IVY_MID, SUCC, EMPTY], tess='', touch=pot, can=(196, 52, 36), water=1.0, gold=('Water',), lamp=148)
        f4 = sill_frame([THYME, IVY_OK, SUCC, EMPTY], tess='There.', gold=('Water', 'Journal'), lamp=148)
        strip([('1  10:40 pm. Journal (the ivy) has been dry since Saturday. One lamp on the sill.', f1),
               ('2  Hold the pot. The can tips in from the right and starts to pour. No button.', f2),
               ('3  Keep holding: about two seconds of water. The ivy lifts and its green comes back.', f3),
               ('4  Let go. Gold mark on the sill, Tess says one word. Journal is done; the lamp can go out.', f4)], f'267-water-{LOOK}.png')
    else:
        leaves = [(30, 140, 20, (120, 110, 60)), (74, 146, -30, (140, 120, 70)), (96, 141, 60, (110, 100, 55)), (58, 149, 10, (130, 115, 60))]
        g1 = sill_frame([('pot-oregano.jpg', 'Water', 52, 1.0, -5, .8, .05), IVY_OK, SUCC, EMPTY], tess='Water: two mornings missed. Leaves on the sill.', leaves=leaves)
        g2 = sill_frame([('pot-oregano.jpg', 'Water', 52, 1.0, -5, .8, .05), IVY_OK, SUCC, EMPTY], tess='', leaves=[(l[0]+70, l[1]-2, l[2]+40, l[3]) for l in leaves], touch=(120, 144))
        g3 = sill_frame([('pot-oregano.jpg', 'Water', 52, 1.0, -5, .8, .05), IVY_OK, SUCC, EMPTY], tess='Swept. It will stand up when you water it.', leaves=())
        g4 = sill_frame([('pot-oregano.jpg', 'Water', 52, 1.0, 0, 1, 0), IVY_OK, ('pot-succulent.jpg', 'Swim · Thu', 236, .95, 0, .9, 0), EMPTY], tess='Thursday. The succulent is the one to water today.', gold=('Water',))
        strip([('1  Two mornings without Water: the thyme droops and drops leaves onto the sill. No counter, no red.', g1),
               ('2  Swipe along the sill to sweep them off. That is the "I know".', g2),
               ('3  Clean sill. The plant stays drooped until it is watered, and that is all the pressure there is.', g3),
               ('4  Thursday. The weekly plant comes due: it is the one Tess points at, nothing else changes.', g4)], f'267-neglect-{LOOK}.png')
