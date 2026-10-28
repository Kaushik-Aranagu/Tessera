# reads a png and two rgb colors and a background; prints, for the top and bottom thirds of the glyph pixels, the share nearer c1
import sys,json
from PIL import Image
im=Image.open(sys.argv[1]).convert('RGB');c0=json.loads(sys.argv[2]);c1=json.loads(sys.argv[3])
w,h=im.size;px=im.load();rows=[]
from collections import Counter
bg=Counter(im.getdata()).most_common(1)[0][0]
d=lambda a,b:sum((a[i]-b[i])**2 for i in range(3))
for y in range(h):
  n=m=0
  for x in range(w):
    p=px[x,y]
    if d(p,bg)<d(p,c0)*0.35 and d(p,bg)<d(p,c1)*0.35:continue  # background
    if min(d(p,c0),d(p,c1))>d(p,bg):continue
    n+=1;m+=d(p,c1)<d(p,c0)
  if n:rows.append((y,n,m))
if not rows:print(json.dumps({'err':'no glyph'}));sys.exit()
ys=[r[0] for r in rows];y0,y1=min(ys),max(ys);t=(y1-y0)/3
def share(a,b):
  N=sum(r[1] for r in rows if a<=r[0]<b);M=sum(r[2] for r in rows if a<=r[0]<b);return round(M/N,2) if N else None
print(json.dumps({'top':share(y0,y0+t),'mid':share(y0+t,y0+2*t),'bot':share(y0+2*t,y1+1)}))
