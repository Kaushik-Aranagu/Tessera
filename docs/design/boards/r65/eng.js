<script>
(()=>{
const RM=matchMedia('(prefers-reduced-motion: reduce)').matches;
const POOL=[['Trip packing',9,1],['Mom’s birthday',9,6],['Tacos',8,3],['Garage',7,2],['Book ideas',8,4],['Passport',7,1],['Work notes',6,5],['Gift list',6,6],['Dreams',5,4],['Run plan',6,7],['Recipes',6,3],['Plumber',4,2],['Tess said',5,4],['Voice memo',4,5],['Wifi code',3,2],['Movies',4,4],['Sleep log',3,7],['Paint colors',4,2],['Kids’ sizes',3,6],['Coffee',3,3],['Quotes',3,4],['Bike fit',3,7],['Taxes',4,5],['Doctor',4,7],['Neighbors',2,6],['Podcasts',2,4],['Seeds',2,2],['Spices',2,3],['Shoes',2,6],['Old phone',2,2],['Jokes',2,4],['Stretch',2,7],['Wine',2,3],['Fonts',2,4],['Keys',2,2],['Hikes',2,7],['Tea',2,3],['Lamp',2,2]];
const DOORS=[['All notes',38,'t',1],['Ideas',9,'room',.7],['From Tess',4,'tess',.6],['Voice memos',5,'room',.55],['Pinned',4,'gold',.5],['Mentions',12,'t',.5],['Private',3,'slate2',.45],['Archive',61,'t2',.4]];
let F={f:'Figtree',w:900,k:-0.01,sh:1},start=0,H=220,TOP=180,SHT=432,SHH=192,state='wall',L=null,WL=POOL,DOOR=-1;
const W=354,G=3,MINFS=13;
const mt=document.getElementById('mt');
function fontCss(wt,fam){return `font-family:'${fam||F.f}',sans-serif;font-weight:${wt};letter-spacing:${F.k}em`}
const cache={};
function unit(t,wt){const key=F.f+wt+t;if(cache[key])return cache[key];mt.setAttribute('style',fontCss(wt)+';font-size:100px');mt.textContent=t.toUpperCase();return cache[key]=mt.getComputedTextLength()/100}
let C=.7;function capRatio(){const c=document.createElement('canvas').getContext('2d');c.font=`${F.w} 200px '${F.f}'`;C=c.measureText('H').actualBoundingBoxAscent/200||.7}
const sum=(a,f)=>a.reduce((s,x)=>s+f(x),0);
// Brick widths are linear in the row height h, so each row's height is solved for an exact full-width fit.
function brickW(b,h){if(b.k==='one')return b.a/C*h;if(b.k==='name')return b.amax/C*(h-G)/2;const n=b.lines.length;return (h-(n-1)*G)/(C*sum(b.lines,l=>1/l.a))}
function solveH(bs){let lo=4,hi=400;for(let i=0;i<40;i++){const m=(lo+hi)/2;if(sum(bs,b=>brickW(b,m))+G*(bs.length-1)>W)hi=m;else lo=m}return lo}
function layoutOnce(words,mult,flat){
  const s0=[...words].sort((a,b)=>b[1]-a[1]);const hi=s0.filter(x=>x[1]>3);const lo=s0.filter(x=>x[1]<=3).sort((a,b)=>b[0].length-a[0].length);
  const spare=lo.splice(0,Math.min(8,Math.max(0,lo.length-6)));
  const sc=H/300*mult,T=[64,44,56,40,60,46,50,38].map(v=>v*sc),PAT=[['B','S'],['S','B','S'],['B','B','S'],['S','B'],['B','S','B']];
  const rows=[];let y=0,r=0,hiI=0,hiE=hi.length,nameFlip=0;const wt=F.w;
  const one=x=>({k:'one',x,a:unit(x[0],wt)});
  const smallFrom=()=>lo.length?lo.pop():(hiI<hiE?hi[--hiE]:null);
  while((hiI<hiE||lo.length)&&H-y>16){
    const rem=H-y,tgt=Math.min(T[r%T.length],rem),pat=PAT[r%PAT.length],bs=[];let p=0;
    const last=rem-tgt<T[(r+1)%T.length]*.6;
    for(;;){const kind=pat[p%pat.length];p++;let b=null;
      if(kind==='B'&&hiI<hiE){const x=hi[hiI++];const sp=x[0].indexOf(' ');
        if(sp>0&&!flat.has(x[0])&&tgt>=36&&(x[0].length>10||nameFlip++%2===0)){const l1=x[0].slice(0,sp),l2=x[0].slice(sp+1);const a1=unit(l1,wt),a2=unit(l2,wt);b={k:'name',x,l:[l1,l2],a:[a1,a2],amax:Math.max(a1,a2),side:r%2}}
        else b=one(x)}
      else{let n=tgt>=56?3:2;while(n>1&&(tgt-(n-1)*G)/n<MINFS*C)n--;const Ls=[];for(let q=0;q<n;q++){const x=smallFrom();if(!x)break;Ls.push({x,a:unit(x[0],wt)})}
        if(Ls.length)b=Ls.length>1?{k:'stack',lines:Ls}:one(Ls[0].x)}
      if(!b){if(hiI>=hiE&&!lo.length)break;continue}
      bs.push(b);
      if(last){if(solveH(bs)<=rem)break}else if(sum(bs,q=>brickW(q,tgt))+G*(bs.length-1)>=W*.95)break;
      if(hiI>=hiE&&!lo.length)break}
    if(!bs.length)break;const h=solveH(bs);if(h>rem+.5)return null;// a row that can't reach both edges is never squeezed
    rows.push({bs,h});y+=h+G;r++;if(last)break}
  const used=sum(rows,q=>q.h)+G*(rows.length-1);
  if(used>H+.5)return null;
  const gap=DOOR>=0?G:(rows.length>1?G+Math.max(0,H-used)/(rows.length-1):G);// door pages never open gaps: the band shrinks instead
  const inWall=new Set();rows.forEach(({bs})=>bs.forEach(b=>{if(b.x)inWall.add(b.x[0]);(b.lines||[]).forEach(l=>inWall.add(l.x[0]))}));
  const out=[],seen={};let yy=0,ci=0,bad=null;
  const key=t=>{seen[t]=(seen[t]||0)+1;return seen[t]>1?t+'~'+seen[t]:t};
  rows.forEach(({bs,h})=>{let x=0;bs.forEach(b=>{const bw=brickW(b,h),col=(ci++*5)%12;
    if(b.k==='one')out.push({t:b.x[0],key:key(b.x[0]),x,y:yy,w:bw,h,fs:h/C,col});
    else if(b.k==='stack'){let ly=yy;b.lines.forEach((l,i)=>{const fs=bw/l.a,lh=fs*C;out.push({t:l.x[0],key:key(l.x[0]),x,y:ly,w:bw,h:lh,fs,col:(col+3*(i+1))%12});ly+=lh+G})}
    else{const lh=(h-G)/2,fs=lh/C,short=b.a[0]<b.a[1]?0:1,sw=b.a[short]*fs,d=bw-sw;
      b.l.forEach((t,i)=>{const isS=i===short;let x0=x,w=isS?sw:bw;
        if(isS&&bw/sw<=1.08)w=bw;// a few percent stretches the glyphs evenly, never the spacing
        else if(isS){// fill the notch with one to three small words stacked to its exact height; repeats are allowed
          const nw=d-G,room=lh;
          const rep=WL.filter(q=>!spare.includes(q)&&!lo.includes(q)&&q[1]<=6&&!inWall.has(q[0]));// repeats only of words not already on the wall
          const pool=spare.concat(lo,rep);
          const hgt=q=>C*nw/unit(q[0],wt);let pick=null,err=.08;
          if(nw>MINFS)for(let i1=0;i1<pool.length;i1++){const h1=hgt(pool[i1]);let e=Math.abs(h1-room)/room;if(e<err&&h1/C>=MINFS){err=e;pick=[pool[i1]]}
            for(let i2=i1+1;i2<pool.length;i2++){const h2=hgt(pool[i2]);if(h1+h2>room*1.1)continue;e=Math.abs(h1+h2+G-room)/room;if(e<err&&Math.min(h1,h2)/C>=MINFS){err=e;pick=[pool[i1],pool[i2]]}
              for(let i3=i2+1;i3<pool.length;i3++){const h3=hgt(pool[i3]);e=Math.abs(h1+h2+h3+2*G-room)/room;if(e<err&&Math.min(h1,h2,h3)/C>=MINFS){err=e;pick=[pool[i1],pool[i2],pool[i3]]}}}}
          let pair=null;if(!pick&&lh/C>=MINFS){let e2=.08;const nat=q=>unit(q[0],wt)*fs;// or two small words side by side at the name's own size
            for(let i1=0;i1<pool.length;i1++)for(let i2=i1+1;i2<pool.length;i2++){const e=Math.abs(nat(pool[i1])+nat(pool[i2])+G-nw)/nw;if(e<e2){e2=e;pair=[pool[i1],pool[i2]]}}}
          if(!pick&&!pair){bad=b.x[0];return}
          const take=fx=>{inWall.add(fx[0]);const si=spare.indexOf(fx);if(si>=0)spare.splice(si,1);else{const li=lo.indexOf(fx);if(li>=0)lo.splice(li,1)}};
          if(pair){const k=(nw-G)/(unit(pair[0][0],wt)*fs+unit(pair[1][0],wt)*fs);let fx0=b.side?x:x+sw+G;x0=b.side?x+d:x;
            pair.forEach((fx,j)=>{take(fx);const fw=unit(fx[0],wt)*fs*k;out.push({t:fx[0],key:key(fx[0]),x:fx0,y:yy+i*(lh+G),w:fw,h:lh,fs,col:(col+6+j*3)%12});fx0+=fw+G})}
          else{
          const tot=sum(pick,hgt),k=(room-(pick.length-1)*G)/tot;let fy=yy+i*(lh+G);const fillX=b.side?x:x+sw+G;x0=b.side?x+d:x;
          pick.forEach((fx,j)=>{take(fx);const fh=hgt(fx)*k;out.push({t:fx[0],key:key(fx[0]),x:fillX,y:fy,w:nw,h:fh,fs:fh/C,col:(col+6+j*3)%12});fy+=fh+G})}}
        out.push({t,key:b.x[0]+'#'+i,x:x0,y:yy+i*(lh+G),w,h:lh,fs,col})})}
    x+=bw+G});yy+=h+gap});
  return bad?{bad}:{out,left:H-used}}
// Pack at 21 row-height scales and keep the one that meets the band's bottom edge closest; a stacked name whose notch
// can't be filled within 5% goes on one line and the wall is packed again.
function layout(words){const flat=new Set();for(let tries=0;tries<8;tries++){let best=null,badName=null;
  for(let m=.7;m<=1.4;m+=.02){const r=layoutOnce(words,m,flat);if(!r)continue;if(r.bad){badName=badName||r.bad;continue}if(r.left<8&&(!best||best.left>=8||m>best.m))best=Object.assign(r,{m});else if(!best||(best.left>=8&&r.left<best.left))best=Object.assign(r,{m})}
  if(best&&best.left<8)return best.out;if(badName)flat.add(badName);else if(best)return best.out}
  return (layoutOnce(words,1,new Set(WL.map(p=>p[0])))||{}).out||[]}
function rnd(seed){return()=>{seed=(seed*1664525+1013904223)>>>0;return seed/4294967296}}
function obb(cx,cy,w,h,t){const c=Math.cos(t),s=Math.sin(t),hw=w/2+1.5,hh=h/2+1.5;const ax=[[c,s],[-s,c]];const pts=[[-hw,-hh],[hw,-hh],[hw,hh],[-hw,hh]].map(([u,v])=>[cx+u*c-v*s,cy+u*s+v*c]);return{pts,ax,cx,cy,r:Math.hypot(hw,hh)}}
function hit(A,B){if(Math.hypot(A.cx-B.cx,A.cy-B.cy)>A.r+B.r)return false;for(const ax of A.ax.concat(B.ax)){let a0=1e9,a1=-1e9,b0=1e9,b1=-1e9;for(const p of A.pts){const d=p[0]*ax[0]+p[1]*ax[1];a0=Math.min(a0,d);a1=Math.max(a1,d)}for(const p of B.pts){const d=p[0]*ax[0]+p[1]*ax[1];b0=Math.min(b0,d);b1=Math.max(b1,d)}if(a1<=b0||b1<=a0)return false}return true}
const ANG=[0,0,-.12,.12,-.32,.32,-.6,.6,Math.PI/2,-Math.PI/2];
// The pile: words drop biggest first, each tries tilts and spots, falls until it touches, keeps the lowest rest; never overlapping.
function pile(items,seed){
  for(let s=1;s>.3;s-=.03){const R=rnd(seed),placed=[],res=[];let ok=true;
    const order=items.map((o,i)=>i).sort((a,b)=>items[b].w*items[b].h-items[a].w*items[a].h);
    for(const i of order){const o=items[i],w=o.w*s,h=o.h*s;let best=null;
      const tries=ANG.filter(()=>R()<.6);if(!tries.length)tries.push(0);
      for(const t of tries){const ex=(w*Math.abs(Math.cos(t))+h*Math.abs(Math.sin(t)))/2,ey=(w*Math.abs(Math.sin(t))+h*Math.abs(Math.cos(t)))/2;if(ex*2>W||ey*2>H)continue;
        for(let cx=ex;cx<=W-ex;cx+=5){let cy=ey;if(placed.some(P=>hit(obb(cx,cy,w,h,t),P)))continue;
          while(cy+3<=H-ey&&!placed.some(P=>hit(obb(cx,cy+3,w,h,t),P)))cy+=3;
          const sc=cy+R()*2;if(!best||sc>best.sc)best={cx,cy,t,sc}}}
      if(!best){ok=false;break}placed.push(obb(best.cx,best.cy,w,h,best.t));res[i]={cx:best.cx,cy:best.cy,t:best.t,s}}
    if(ok)return res}
  return items.map(o=>({cx:o.x+o.w/2,cy:o.y+o.h/2,t:0,s:1}))}
let fid=0;
function svg(o){const id="dz"+(fid++),c=o.col<0?"var(--t2)":`var(--c${o.col})`,sh=F.sh?` stroke="${c}" stroke-width="${(o.fs*.035).toFixed(2)}" stroke-linejoin="miter" stroke-miterlimit="10" paint-order="stroke"`:'';
  return `<svg width="${o.w}" height="${o.h}" viewBox="0 0 ${o.w} ${o.h}"><filter id="${id}" x="-30%" y="-60%" width="160%" height="220%"><feTurbulence type="fractalNoise" baseFrequency="${(2.4/Math.max(10,o.h)).toFixed(3)}" numOctaves="2" seed="${fid%50}"/><feDisplacementMap in="SourceGraphic" scale="0" xChannelSelector="R" yChannelSelector="G"/></filter><text x="0" y="${o.h}" textLength="${o.w}" lengthAdjust="spacingAndGlyphs" fill="${c}"${sh} style="${fontCss(F.w)};font-size:${o.fs}px">${o.t.toUpperCase()}</text></svg>`}
