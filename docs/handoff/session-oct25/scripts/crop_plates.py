import sys,os
from PIL import Image
Image.MAX_IMAGE_PIXELS=None
raw,out=sys.argv[1],sys.argv[2]
SET=[('kloofendal_43d_clear_puresky','clear-day'),('kloofendal_48d_partly_cloudy_puresky','broken-day'),('kloofendal_overcast_puresky','overcast-day'),
 ('qwantani_dusk_2_puresky','clear-dusk'),('belfast_sunset_puresky','broken-dusk'),('kloppenheim_07_puresky','clear-night'),('kloofendal_misty_morning_puresky','fog-day')]
os.makedirs(out,exist_ok=True)
for slug,name in SET:
    src=os.path.join(raw,slug+'.jpg')
    if not os.path.exists(src):print('missing',slug);continue
    im=Image.open(src).convert('RGB');W,H=im.size
    # the sun: brightest column in the upper sky
    small=im.resize((512,256));px=small.load();best,bx=-1,256
    for x in range(512):
        s=sum(sum(px[x,y]) for y in range(0,110))
        if s>best:best,bx=s,x
    cx=int(bx/512*W)
    top=int(0.05*H);bot=int(0.52*H);h=bot-top;w=int(h*0.461*1.6)
    # wrap around the panorama horizontally
    strip=Image.new('RGB',(w,h))
    x0=cx-w//2
    for part in range(2):
        xs=(x0+part*w)%W if False else None
    # simple wrap: paste two pieces
    left=x0%W
    if left+w<=W:strip=im.crop((left,top,left+w,bot))
    else:
        a=im.crop((left,top,W,bot));b=im.crop((0,top,w-(W-left),bot));strip.paste(a,(0,0));strip.paste(b,(W-left,0))
    strip=strip.resize((int(w*1600/h),1600),Image.LANCZOS)
    strip.save(os.path.join(out,name+'.jpg'),quality=82,optimize=True,progressive=True)
    print(name,slug,W,H,'sun at',cx,'->',strip.size,os.path.getsize(os.path.join(out,name+'.jpg'))//1024,'KB')
