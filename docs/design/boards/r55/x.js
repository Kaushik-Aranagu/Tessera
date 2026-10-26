(()=>{
const RM=matchMedia('(prefers-reduced-motion: reduce)').matches;
const $=id=>document.getElementById(id);
const anim=(dur,fn,done)=>{if(RM){fn(1,1);done&&done();return}const s=performance.now();(function f(n){const u=Math.min(1,(n-s)/(dur*1000)),e=1-Math.pow(1-u,3);fn(e,u);if(u<1)requestAnimationFrame(f);else done&&done()})(s)};
const spring=u=>1-Math.exp(-7*u)*Math.cos(9*u);
const haptic=k=>{try{navigator.vibrate&&navigator.vibrate(k==='commit'?14:5)}catch(_){}};
let CC={};const css=v=>CC[v]??(CC[v]=getComputedStyle($('ph')).getPropertyValue(v).trim());
const hex=h=>{h=h.replace('#','');return [0,2,4].map(i=>parseInt(h.slice(i,i+2),16))};
const mix=(a,b,t)=>a.map((x,i)=>Math.round(x+(b[i]-x)*t));
const rgb=c=>`rgb(${c[0]},${c[1]},${c[2]})`;

// ---------- fit phones to narrow screens
function fit(){document.querySelectorAll('.fit').forEach(f=>{const p=f.firstElementChild,s=Math.min(1,f.clientWidth/402);p.style.transform=`scale(${s})`;f.style.height=(874*s)+'px'})}
addEventListener('resize',fit);

// ---------- board rows
const ROWS=[`<span class="hl sky">Friday</span>, October 23`,`<span class="hl" style="color:var(--training)">Bench</span>, 185 for 5 again.`,`<span class="hl" style="color:var(--lists)">Packing</span>, 6 of 14.`];
const WX={rain:`<span class="hl wx" data-wx="rain" data-c="var(--rain)" style="color:var(--rain);--c:var(--rain)">Rain</span> from 4 PM.`};
const ALT=[WX.rain,`<span class="hl" style="color:var(--kitchen)">Rice</span> goes out today.`];
function board(el,small){el.innerHTML=ROWS.map((r,i)=>`<div class="rowl" style="${i===0?'font-weight:600':''}">${r}</div>`).join('')}
board($('board'));let alt=0;setInterval(()=>{if(RM)return;const r=$('board').children[1+(alt%2)];r.style.transform='scaleY(.08)';setTimeout(()=>{r.innerHTML=alt%4<2?ALT[alt%2]:ROWS[1+alt%2];announce(r.textContent);r.style.transition='transform 90ms';r.style.transform='';setTimeout(()=>r.style.transition='',100)},70);alt++},7000);

// ---------- the mosaic: whole 4 pt tiles, a soft stepped edge, faces you swipe
const MR=40,FW=[88,88,84,72];let MC=62,MCf=62,face=0;const FACES=['Now','Gallery','Weather','Workout'];
// faces (his 10:55 PM): Now plays whatever the board just announced, the flap and the mosaic turning together;
// Gallery cycles pixel scenes picked by time of day, place and weather; then the apps (Weather, Workout, more later)
let ann='bench',annP='bench',annT=-1e9;
function announce(txt){const k=/Rain/.test(txt)?'rain':/Rice/.test(txt)?'rice':/Bench/.test(txt)?'bench':/Packing/.test(txt)?'packing':null;if(!k||k===ann)return;annP=ann;ann=k;annT=performance.now()}
const ANN={bench:['bar','--training'],rice:['bag','--kitchen'],packing:['case','--lists']};
function annCol(a,c,r,t,at){const pg=hex(css('--phone')),dark=pg[0]<40,k=c-(MC-62);let col=baseCol(0,c,r,t);
  if(a==='rain'){const rn=hex(css('--rain')),dd=Math.min(1,(t-at)/700);col=mix(col,mix(rn,pg,dark?.5:.3),.85*dd);
    const sp=((c*37)%11)/11,y=((t/(360+sp*220)+sp*7)%1)*(MR+8)-4;if(c%2===0&&r<=y&&r>y-3&&r<MR-2)col=mix(col,dark?[200,215,230]:[238,244,250],.7*dd);
    if(r>=MR-2){const sx=((c*13+Math.floor(t/260))%17);if(sx===0)col=mix(col,dark?[200,215,230]:[238,244,250],.6*dd)}return col}
  const A=ANN[a];if(!A)return col;col=mix(col,pg,.55);const ac=hex(css(A[1]));
  for(const [cc,rr,al] of art(A[0],t))if(k===36+cc&&r===10+rr)return al?mix(ac,pg,.42):ac;return col}
function nowCol(c,r,t){const age=t-annT;if(age<600&&r>age/600*MR)return annCol(annP,c,r,t,annT-1e4);if(age<600&&Math.floor(age/600*MR)===r)return mix(annCol(ann,c,r,t,annT),[255,255,255],.25);return annCol(ann,c,r,t,annT)}
const GAL=['evening','night','window','morning'];
function galScene(g,c,r,t){const pg=hex(css('--phone')),dark=pg[0]<40;
  if(g==='evening')return baseCol(0,c,r,t);
  if(g==='night'){let col=mix([18,22,48],[52,46,92],r/MR);const h=(c*73+r*151)%211;if(h<3&&r<26)col=mix(col,[236,232,246],.4+.5*((Math.sin(t/(600+h*300)+h)+1)/2));
    const d=Math.hypot(c-(MC-16),r-10),d2=Math.hypot(c-(MC-13.5),r-8.5);if(d<5&&d2>4.2)col=[240,234,214];if(r>33-2*Math.sin(c/7))col=[14,14,24];return col}
  if(g==='window'){let col=mix([150,162,182],[110,120,145],r/MR);if(dark)col=mix(col,[30,34,48],.5);const lt=Math.sin(c/5)*Math.sin(r/4);if(lt>.8)col=mix(col,[236,196,140],.35);
    const sp=((c*29)%13)/13,y=((t/(2400+sp*1600)+sp*5)%1)*(MR+6)-3;if((c*7)%5===0&&Math.abs(r-y)<1.2)col=mix(col,[230,238,248],.6);return col}
  let col=mix([250,214,168],[168,196,232],1-r/MR);const d=Math.hypot(c-14,r-(22-Math.min(4,(t%40000)/10000)));if(d<5)col=[255,226,150];if(r>27+2*Math.sin(c/8+2))col=mix([150,170,120],pg,.3);if(dark)col=mix(col,[16,18,30],.5);return col}
function galCol(c,r,t){const n=Math.floor(t/9000),u=(t%9000)/1200,a=GAL[n%GAL.length],b=GAL[(n+GAL.length-1)%GAL.length];
  if(u<1&&!RM&&((c*131+r*71)%97)/97>u)return galScene(b,c,r,t);return galScene(a,c,r,t)}
function faceCol(f,c,r,t){return f===0?nowCol(c,r,t):f===1?galCol(c,r,t):baseCol(f-1,c,r,t)}
function baseCol(f,c,r,t){const sky1=hex(css('--sky1')),sky2=hex(css('--sky2')),pg=hex(css('--phone')),tr=hex(css('--training')),dark=pg[0]<40;
  if(f===0){let col=mix(sky1,sky2,r/MR*1.1);const h1=26+4*Math.sin(c/9+1),h2=31+3*Math.sin(c/6+3);if(r>h1)col=mix(hex(css('--routines')),pg,dark?.35:.45);if(r>h2)col=mix(hex(css('--routines')),[0,0,0],dark?.35:.25);
    if(r<14&&((c*7+r*13+Math.floor(t/900))%97===0))col=mix(col,[255,255,255],.6);return col}
  const ex=MC-62,k=c-ex;
  if(f===1){let col=mix([120,170,220],[200,220,235],r/MR);if(dark)col=mix(col,[10,20,40],.45);
    if(k<0){const rn=hex(css('--rain')),cl=mix(rn,pg,dark?.55:.35);col=mix(cl,col,Math.min(1,Math.max(0,(c-(ex-14))/14)));
      const sp=((c*37)%11)/11,y=((t/(380+sp*240)+sp*7)%1)*(MR+8)-4;if(c<ex-2&&c%2===0&&r>8&&r<=y&&r>y-3)col=mix(col,dark?[200,215,230]:[235,242,248],.75);return col}
    const dx=k-14,dy=r-12,d=Math.hypot(dx,dy);
    if(d<5)col=[255,196,92];else{const a=Math.atan2(dy,dx)+t/3000;if(d<8.5&&d>6&&Math.abs(Math.sin(a*4))>.85)col=[255,206,120]}
    if(digit('62',k-34,r-12))col=dark?[240,240,240]:[40,52,70];if(digit('4P',k-36,r-24))col=mix(col,dark?[220,225,235]:[60,70,90],.7);return col}
  let col=mix(tr,pg,.35+.25*r/MR);if(digit('124',k-22,r-15))col=dark?[235,240,250]:[255,255,255];
  if(k<0){const d=Math.floor((c-1)/(ex/7)),cx0=Math.round(1+d*ex/7),done=[1,0,1,1,0,0,0][d],today=d===4;
    if(d>=0&&d<7&&c>=cx0&&c<cx0+3&&r>=17&&r<20)col=done?(dark?[235,240,250]:[255,255,255]):today?mix(col,dark?[235,240,250]:[255,255,255],(Math.sin(t/500)+1)/4+.3):mix(col,pg,.25)}
  return col}
const FONT={'0':'111101101101111','1':'010110010010111','2':'111001111100111','4':'101101111001001','6':'111100111101111','P':'111101111100100'};
function digit(s,c,r){if(r<0||r>4)return false;for(let i=0;i<s.length;i++){const x=c-i*4;if(x>=0&&x<3){const g=FONT[s[i]];return g&&g[r*3+x]==='1'}}return false}
let wipe=null,gaps={};
function edgeT(c,r){const e=Math.min(c,61-c,r,MR-1-r),k=Math.min(c,61-c)<4&&Math.min(r,MR-1-r)<4?Math.min(4-Math.min(c,61-c),4-Math.min(r,MR-1-r)):0;return e>=3&&k<2?0:[.82,.6,.36,0][Math.max(0,Math.min(3,e-(k>1?1:0)))]}
function tileCol(c,r,t){let f=face;if(wipe){const p=wipe.p;const edge=wipe.dir>0?c/MC:1-c/MC;if(edge<p)f=wipe.to;else f=wipe.from}let col=faceCol(f,c,r,t);const pg=hex(css('--phone'));
  const g=gaps[c+','+r];if(g){const u=Math.min(1,Math.max(0,(t-g)/1100));col=mix(pg,col,u<0?0:(t-g<0?0:u))}
  return col}
// the edge (his 10:51 PM, back to the departure mosaic): a squircle whose colours climb out of the page over 16 whole
// tiles, Bayer-dithered steps, the scene's own detail mirrored out into the rim. No frame, no fade, no blur.
const BAY=[0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5],FE=16,PAD=24;const refl=(i,n)=>{if(i<0)i=-i-1;else if(i>n-1)i=2*n-1-i;return Math.max(0,Math.min(n-1,i))};
function blendQ(c,r){const R=6,hx=(MC-1)/2,hy=(MR-1)/2,qx=Math.max(0,Math.abs(c-hx)-(hx-R)),qy=Math.max(0,Math.abs(r-hy)-(hy-R))+1.2*Math.max(0,-r,r-(MR-1));
  const sd=(qx>0||qy>0)?Math.cbrt(qx*qx*qx+qy*qy*qy)-R:-Math.min(hx-Math.abs(c-hx),hy-Math.abs(r-hy));if(sd>=FE)return 0;
  const bq=(BAY[((r+64)&3)*4+((c+64)&3)]+.5)/16,u=Math.max(0,Math.min(1,(FE-sd)/FE)),l=u*u*u*(u*(u*6-15)+10);return Math.max(0,Math.min(1,Math.floor(l*24+bq)/24))}
function drawMos(t){CC={};const x=$('mos').getContext('2d'),pg=hex(css('--phone'));x.setTransform(2,0,0,2,0,0);x.clearRect(0,0,402,352);
  const tw=FW[wipe?wipe.to:face]+(RM?0:Math.sin(t/4300)*1.2);MCf=RM?tw:MCf+(tw-MCf)*.07;MC=Math.round(MCf);const X0=378-MC*4;$('mosW').style.width=MC*4+'px';
  // on paper the 0.8 pt gaps washed the colour out (his 12:12 AM): tiles grow to 3.6 so the gap is a thin line
  const TS=pg[0]<100?3.2:3.6;
  for(let c=-PAD;c<MC+PAD;c++)for(let r=-PAD;r<MR+PAD;r++){const q=blendQ(c,r);if(q<=0)continue;x.fillStyle=rgb(mix(pg,grade(tileCol(refl(c,MC),refl(r,MR),t),pg),q));x.fillRect(X0+c*4,96+r*4,TS,TS)}}
// on light pages: lift saturation 30% and deepen 10%, so colours hold their own against paper; dark pages untouched
// light pages (his 12:12 AM: dull): richer and BRIGHTER, saturation x1.55, then brightened x1.08 with a 5% lift of the shadows so it sits clean on paper
function grade(c,pg){if(pg[0]<100)return c;const m=(c[0]+c[1]+c[2])/3;return c.map(v=>{let w=m+(v-m)*1.55;w=w*1.08+(255-w)*.05;return Math.max(0,Math.min(255,Math.round(w)))})}

// ---------- one thing
const THINGS=[
 {k:'Training',a:'--training',big:'6:30 pm',num:1,mid:'Push A, bench first',small:'Bench best 205 lb, three weeks ago',s:'bar'},
 {k:'Kitchen',a:'--kitchen',big:'4 to get',num:1,mid:'Tortillas, cilantro, limes, beans',small:'For tacos tonight, on the way home',s:'bag'},
 {k:'Lists',a:'--lists',big:'6 of 14',num:1,mid:'Packing, for Sunday',small:'Next: socks, the book, the adapter',s:'case'},
 {k:'Routines',a:'--routines',big:'8 pm',num:1,mid:'Stretch, five minutes',small:'Third night this week',s:'moon'},
 {k:'Weather',a:'--rain',big:'64°',num:1,mid:'Clear until 4, then rain',small:'Sunset at 6:34 pm',s:'sun'}];
let ti=0;
function paintOne(dir){const T=THINGS[ti],O=$('one');
  O.innerHTML=`<div class="sc" style="position:absolute;left:0;right:0;top:29px;height:20px;display:flex;justify-content:space-between;align-items:flex-end;color:var(${T.a})"><span>${T.k}</span></div>
  <div id="tiers" style="position:absolute;left:0;right:0;top:57px;clip-path:inset(-57px 92px -29px 0)">
   <div class="t1" style="height:64px;line-height:64px;white-space:nowrap;overflow:hidden;margin-right:92px;color:var(${T.a});${T.num?'font-family:var(--nums);font-weight:400;font-size:56px;letter-spacing:-.02em':'font-weight:700;font-size:38px;letter-spacing:-.02em'}"><span id="bigT" style="display:inline-block">${T.big}</span></div>
   <div class="t2" style="height:28px;line-height:28px;font-size:20px;font-weight:500;white-space:nowrap;overflow:hidden;margin-right:92px;margin-top:6px">${T.mid}</div>
   <div class="t3" style="height:22px;line-height:22px;font-size:15px;font-weight:500;color:var(--ink2);white-space:nowrap;overflow:hidden;margin-top:6px;margin-right:92px">${T.small}</div></div>`;
  [O.querySelector('.t2'),O.querySelector('.t3')].forEach(m2=>{if(m2){let t=m2.textContent;while(m2.scrollWidth>m2.clientWidth&&t.includes(' ')){t=t.slice(0,t.lastIndexOf(' ')).replace(/,$/,'');m2.textContent=t}}});
  const big=$('bigT');let f=T.num?56:38;while(big.offsetWidth>big.parentElement.clientWidth&&f>(T.num?42:29)){f--;big.parentElement.style.fontSize=f+'px'}
  ['t1','t2','t3'].forEach((c,i)=>{const e=O.querySelector('.'+c);if(RM||!dir)return;e.style.clipPath='inset(0 0 100% 0)';setTimeout(()=>anim(.5,u=>e.style.clipPath=`inset(0 0 ${(1-u)*100}% 0)`,()=>e.style.clipPath=''),i*80)});
  if(dir!==undefined)lend()}
// sign art, 20 by 20 cells: [col,row,alt]
function art(kind,t){const C=[];const add=(c,r,a)=>{if(c>=0&&c<20&&r>=0&&r<20)C.push([c,r,a?1:0])};
  if(kind==='bar'){const y=Math.round(RM?0:-1.5*Math.max(0,Math.sin(t/700)));for(let c=0;c<20;c++)add(c,10+y);for(const [x,h] of [[2,5],[3,6],[4,6],[15,6],[16,6],[17,5]])for(let r=10-h;r<=10+h;r++)add(x,r+y,x===2||x===17);for(const x of [5,14])for(let r=8;r<=12;r++)add(x,r+y,1)}
  if(kind==='bag'){for(let c=3;c<=16;c++)for(let r=8;r<=18;r++)if(c===3||c===16||r===18||r===8)add(c,r);for(let c=6;c<=13;c++)if(c===6||c===13)for(let r=4;r<=8;r++)add(c,r);for(let c=6;c<=13;c++)add(c,4);
    const b=RM?0:Math.round(Math.sin(t/500));for(const [c,r] of [[6,6],[7,5],[8,6],[11,5],[12,6],[10,4]])add(c,r+b,1);for(let c=5;c<=14;c++)for(let r=10;r<=16;r++)if((c+r)%3===0)add(c,r,1)}
  if(kind==='case'){for(let c=1;c<=18;c++)for(let r=6;r<=18;r++)if(c===1||c===18||r===6||r===18)add(c,r);for(let c=7;c<=12;c++)add(c,3);add(7,4);add(7,5);add(12,4);add(12,5);const fill=Math.round(11*(6/14));for(let c=3;c<=16;c++)for(let r=17-fill;r<=16;r++)add(c,r,1)}
  if(kind==='moon'){for(let c=0;c<20;c++)for(let r=0;r<20;r++){const d=Math.hypot(c-9.5,r-10),d2=Math.hypot(c-13,r-7.5);if(d<8&&d2>6.2)add(c,r,d>6.5)}for(const [c,r,p] of [[16,15,0],[17,3,1],[3,2,2]])if(RM||Math.floor(t/600+p)%3)add(c,r,1)}
  if(kind==='sun'){for(let c=0;c<20;c++)for(let r=0;r<20;r++){const d=Math.hypot(c-9.5,r-9.5);if(d<4.6)add(c,r,d>3.4);const a=Math.atan2(r-9.5,c-9.5)-(RM?0:t/2400);if(d>6.3&&d<9.6&&Math.abs(Math.sin(a*4))>.93)add(c,r,1)}}
  return C}
let lendS=null,breathe=null;
function signOrigin(){return {x:24+354-80,y:400+57+(64+6+28)/2-40}}
function lend(){const T=THINGS[ti],t=performance.now(),cells=art(T.s,0).sort((a,b)=>b[1]-a[1]||a[0]-b[0]);
  const src=cells.map(()=>{const c=4+Math.floor(Math.random()*(MC-8)),r=4+Math.floor(Math.random()*(MR-8));return [c,r]});
  src.forEach(([c,r],i)=>gaps[c+','+r]=t+i*6+450);lendS={t,cells,src,kind:T.s,acc:hex(css(T.a)),srcCol:src.map(([c,r])=>faceCol(face,c,r,t))};haptic('tick')}
function drawFx(t){const x=$('fx').getContext('2d');x.setTransform(2,0,0,2,0,0);x.clearRect(0,0,402,874);if(!lendS)return;const O=signOrigin(),pg=hex(css('--phone'));
  const mx=378-MC*4,my=210;const done=t-lendS.t>lendS.cells.length*6+420;
  if(done){const cells=art(lendS.kind,t);const set=new Set(cells.map(c=>c[0]+','+c[1]));cells.forEach(([c,r,a])=>{const n=[[1,0],[-1,0],[0,1],[0,-1]].filter(([dx,dy])=>set.has((c+dx)+','+(r+dy))).length;
      let col=a?mix(lendS.acc,pg,.42):lendS.acc;if(n<4){const s=lendS.srcCol[(c*31+r*7)%lendS.srcCol.length];col=mix(col,s,.33)}x.fillStyle=rgb(col);x.fillRect(O.x+c*4,O.y+r*4,3.2,3.2)});
    if(breathe&&t-breathe.t<1000){const u=(t-breathe.t)/1000,k=u<.5?u*2:2-u*2;const [c,r]=breathe.cell,[sc,sr]=breathe.src;const ax=O.x+c*4,ay=O.y+r*4,bx=mx+sc*4,by=my+sr*4;x.fillStyle=rgb(lendS.acc);x.fillRect(ax+(bx-ax)*k,ay+(by-ay)*k-20*Math.sin(Math.PI*k),3.2,3.2)}
    return}
  lendS.cells.forEach(([c,r,a],i)=>{const st=lendS.t+i*6,u=Math.min(1,Math.max(0,(t-st)/420));if(t<st)return;const e=1-Math.pow(1-u,3);const [sc,sr]=lendS.src[i];
    const ax=mx+sc*4,ay=my+sr*4,bx=O.x+c*4,by=O.y+r*4;const s=3.2*(1+.4*Math.sin(Math.PI*u));const col=mix(lendS.srcCol[i],a?mix(lendS.acc,pg,.42):lendS.acc,u);
    x.fillStyle=rgb(col);x.fillRect(ax+(bx-ax)*e,ay+(by-ay)*e-18*Math.sin(Math.PI*u),s,s)})}
setInterval(()=>{if(!lendS||RM)return;const cells=art(lendS.kind,0);breathe={t:performance.now(),cell:cells[Math.floor(Math.random()*cells.length)],src:[4+Math.floor(Math.random()*(MC-8)),4+Math.floor(Math.random()*(MR-8))]}},5200);

// ---------- apps list
const APPS=[['Notes',''],['Training','Push A at 6:30 pm, bench first','--training'],['Kitchen','']];
$('apps').innerHTML=APPS.map(([n,f,a],i)=>`<div style="height:40px;display:flex;justify-content:space-between;align-items:baseline;line-height:40px;white-space:nowrap;gap:12px"><span style="font-size:${i===1?23:18}px;font-weight:600;color:${a?`var(${a})`:'var(--ink2)'}">${n}</span><span style="font-size:15px;font-weight:500;color:var(--ink2);overflow:hidden">${f}</span></div>`).join('');

// ---------- swipes: each zone owns its own drag (his 10:31 PM)
function zone(el,{onMove,onEnd,onDown,onUp,onMoveY,onEndY}){let sx=null,sy=null,lock=null;
  el.addEventListener('pointerdown',e=>{sx=e.clientX;sy=e.clientY;lock=null;el.setPointerCapture(e.pointerId);onDown&&onDown()});
  el.addEventListener('pointermove',e=>{if(sx==null)return;const dx=(e.clientX-sx)/sc(),dy=(e.clientY-sy)/sc();if(!lock&&Math.hypot(dx,dy)>10)lock=Math.abs(dx)>1.3*Math.abs(dy)?'x':'y';if(lock==='x')onMove(dx);else if(lock==='y'&&onMoveY)onMoveY(dy)});
  el.addEventListener('pointerup',e=>{if(sx==null)return;const dx=(e.clientX-sx)/sc(),dy=(e.clientY-sy)/sc();sx=null;onUp&&onUp();if(lock==='x')onEnd(dx);else if(lock==='y'&&onEndY)onEndY(dy);else onEnd(0)});
  el.addEventListener('pointercancel',()=>{sx=null;onUp&&onUp();onEnd(0)})}
const sc=()=>$('ph').getBoundingClientRect().width/402;
// one thing: tiers follow at their depths; past 50 pt it turns
zone($('one'),{  onMove:dx=>{const T=$('tiers');if(!T)return;[...T.children].forEach((c,i)=>c.style.transform=`translateX(${dx*[.9,.72,.54][i]}px)`)},
  onEnd:dx=>{if(Math.abs(dx)>50){const d=dx<0?1:-1;ti=(ti+d+THINGS.length)%THINGS.length;haptic('commit');paintOne(d)}else{const T=$('tiers');if(T)[...T.children].forEach(c=>{const x0=parseFloat((c.style.transform.match(/-?[\d.]+/)||[0])[0]);anim(.4,(e,u)=>c.style.transform=`translateX(${x0*(1-spring(u))}px)`)})}},
  // his 11:41 PM: up and down turn it too (up = next, down = back); tiers slide at the same depths, clipped at the slot
  onMoveY:dy=>{const T=$('tiers');if(!T)return;[...T.children].forEach((c,i)=>c.style.transform=`translateY(${dy*[.9,.72,.54][i]}px)`)},
  onEndY:dy=>{if(Math.abs(dy)>44){const d=dy<0?1:-1;ti=(ti+d+THINGS.length)%THINGS.length;haptic('commit');paintOne(d)}else{const T=$('tiers');if(T)[...T.children].forEach(c=>{const y0=parseFloat((c.style.transform.match(/-?[\d.]+/)||[0])[0]);anim(.4,(e,u)=>c.style.transform=`translateY(${y0*(1-spring(u))}px)`)})}}});
// mosaic: faces only
zone($('mosW'),{onMove:()=>{},
  onEnd:dx=>{if(Math.abs(dx)>40){const d=dx<0?1:-1,to=(face+d+FACES.length)%FACES.length;wipe={from:face,to,dir:d,p:0};haptic('commit');anim(RM?0:.5,e=>wipe.p=e,()=>{face=to;wipe=null})}}});

// ---------- the phone as it is today (from the code, sheet notes)
function oldPhone(){const P=$('old');let y=62+16;const S=16;const blk=(h,html)=>{const d=document.createElement('div');d.className='bl';d.style.top=y+'px';d.style.height=h+'px';d.innerHTML=html;P.appendChild(d);y+=h+S;return d};
  const b=blk(96,'');b.style.display='flex';b.style.flexDirection='column';b.style.gap='3px';b.innerHTML=ROWS.map((r,i)=>`<div class="rowl" style="font-weight:${i?400:500}">${r.replace(/class="hl"/g,'style="font-weight:700;font-size:25.8px;text-decoration:underline;text-decoration-thickness:1px;text-underline-offset:5px"')}</div>`).join('');
  y-=2;const m=blk(160,'<canvas width="496" height="320" style="width:248px;height:160px;display:block;margin-left:auto"></canvas>');m.dataset.mos=1;
  blk(196,`<div style="font-family:var(--nums);font-weight:200;font-size:60px;line-height:84px;color:var(--training)">6:30</div><div style="font-size:20px;line-height:28px;min-height:56px">Push A, <span style="font-size:22px;font-weight:600;color:var(--training);text-decoration:underline;text-decoration-thickness:1px;text-underline-offset:4px">Training</span> bench first</div><div style="font-size:15px;color:var(--ink3)">Bench best 205 lb, three weeks ago</div><div class="n" style="position:absolute;right:0;bottom:0;font-size:14px;font-weight:300;color:var(--ink3)">1 of 5</div>`);
  blk(120,APPS.map(([n,f,a],i)=>`<div style="height:40px;display:flex;justify-content:space-between;align-items:baseline;line-height:40px"><span style="font-size:${i===1?23.4:18}px;font-weight:${i===1?600:400};color:${a?`var(${a})`:'var(--ink3)'}">${n}</span><span style="font-size:16px;color:var(--ink2)">${f}</span></div>`).join(''));
  const t=document.createElement('span');t.className='tess';t.style.right='24px';t.style.bottom='60px';P.appendChild(t);
  const ov=document.createElement('div');ov.className='ov';ov.id='ovO';ov.hidden=true;P.appendChild(ov);
  oldY=y}
let oldY=0;
function drawOldMos(t){const cv=$('old').querySelector('[data-mos] canvas');if(!cv)return;const x=cv.getContext('2d');x.setTransform(2,0,0,2,0,0);for(let c=0;c<62;c++)for(let r=0;r<MR;r++){x.fillStyle=rgb(mix(baseCol(0,c,r,0),hex(css('--phone')),edgeT(c,r)));x.fillRect(c*4,r*4,3.2,3.2)}}

// ---------- overlays: spacing guides and touch zones
function guides(){const G=[[0,62,'status bar'],[84,180,'board 96'],[180,210,'30'],[210,370,'mosaic 160'],[370,400,'30'],[400,612,'one thing 212'],[612,640,'28'],[640,760,'apps 120'],[768,840,'foot'],[840,874,'home bar']];
  $('ovG').innerHTML=G.map(([a,b,l])=>`<div style="position:absolute;left:0;right:0;top:${a}px;height:${b-a}px;border-top:1px dashed var(--guide);${/^\d+$/.test(l)?'background:color-mix(in srgb,var(--guide) 10%,transparent)':''}"><span class="n" style="position:absolute;left:4px;top:1px;font-size:11px;color:var(--guide)">${l}${/^\d/.test(l)?'':''} at ${a}</span></div>`).join('');
  const O=[[62,78,'16'],[78,174,'board 96'],[174,188,'14'],[188,348,'mosaic 160'],[348,364,'16'],[364,560,'one thing 196'],[560,576,'16'],[576,696,'apps 120'],[696,720,'24'],[720,840,'empty 120: Tess band + inset']];
  $('ovO').innerHTML=O.map(([a,b,l])=>`<div style="position:absolute;left:0;right:0;top:${a}px;height:${b-a}px;border-top:1px dashed var(--guide);${/^\d+$|empty/.test(l)?'background:color-mix(in srgb,var(--guide) 10%,transparent)':''}"><span class="n" style="position:absolute;left:4px;top:1px;font-size:11px;color:var(--guide)">${l} at ${a}</span></div>`).join('')}
function zones(){const Z=[[24,84,354,96,'--sky2','Board: taps on highlights'],[122,202,264,176,'--training','Mosaic: faces, lean'],[24,400,354,212,'--lists','One thing: turn either way, hold'],[24,640,354,120,'--kitchen','Apps: up and down']];
  $('ovZ').innerHTML=Z.map(([x,y,w,h,c,l])=>`<div style="position:absolute;left:${x}px;top:${y}px;width:${w}px;height:${h}px;background:color-mix(in srgb,var(${c}) 16%,transparent);outline:1.5px solid var(${c})"><span style="position:absolute;left:6px;bottom:4px;font-size:12px;font-weight:600;color:var(${c})">${l}</span></div>`).join('')+`<div style="position:absolute;left:24px;top:370px;width:354px;height:30px;background:repeating-linear-gradient(45deg,transparent 0 6px,color-mix(in srgb,var(--ink3) 30%,transparent) 6px 7px)"><span style="position:absolute;left:6px;top:7px;font-size:12px;color:var(--ink2)">nothing starts here</span></div>`}
$('tg').onclick=()=>{const on=$('ovG').hidden;$('ovG').hidden=!on;$('ovO').hidden=!on;$('tg').setAttribute('aria-pressed',on)};
$('tz').onclick=()=>{const on=$('ovZ').hidden;$('ovZ').hidden=!on;$('tz').setAttribute('aria-pressed',on)};
$('th').onclick=()=>{document.documentElement.dataset.theme='dark';CC={};drawOldMos()};$('tw').onclick=()=>{document.documentElement.dataset.theme='light';CC={};drawOldMos()};

oldPhone();guides();zones();paintOne();fit();
(document.fonts?document.fonts.ready:Promise.resolve()).then(()=>{paintOne();lend()});
// weather words carry their weather (his 11:22 PM): rain falls through "Rain", flakes drift past "Snow", "Windy" sways
// letter by letter, "Sunny" catches a glint. Thin strokes, never pixels or dots; none under Reduce Motion.
// ---------- every weather word (his 11:51 PM): one effect per forecast case, Core's WeatherCondition list
// Clouds are soft layered puffs (shade under, body, lit top) that breathe and drift; the word's colour follows the cloud.
// Thin strokes only, never pixels or filled dots. Reduce Motion: no effect, the word keeps its colour.
const WXC=[
 ['clear','sky1','Sunny',' until 4 PM.','clear (0), day'],
 ['clearN','moon','Clear',' tonight.','clear (0), night'],
 ['mostly','sky1','Mostly sunny',' today.','mainlyClear (1), day'],
 ['mostlyN','moon','Mostly clear',' after 9 PM.','mainlyClear (1), night'],
 ['partly','pcloud','Partly cloudy',' this afternoon.','partlyCloudy (2), day'],
 ['partlyN','moon','Partly cloudy',' tonight.','partlyCloudy (2), night'],
 ['overcast','cloud','Cloudy',' until noon.','overcast (3)'],
 ['fog','fog','Fog',' until 10 AM.','fog (45, 48)'],
 ['drizzle','rain','Drizzle',' from 3 PM.','drizzle (51, 53, 55)'],
 ['fdrizzle','ice','Freezing drizzle',' at dawn.','freezingDrizzle (56, 57)'],
 ['rain','rain','Rain',' from 4 PM.','rain (61, 63, 80, 81)'],
 ['heavy','rain','Heavy rain',' after 6 PM.','heavyRain (65, 82)'],
 ['frain','ice','Freezing rain',' tonight.','freezingRain (66, 67)'],
 ['snow','snow','Snow',' after 8 PM.','snow (71, 73, 85)'],
 ['hsnow','snow','Heavy snow',' overnight.','heavySnow (75, 86)'],
 ['grains','snow','Snow grains',' this morning.','snowGrains (77)'],
 ['storm','storm','Thunderstorms',' after 5 PM.','thunderstorm (95)'],
 ['hail','storm','Storms with hail',' at 6 PM.','thunderstormHail (96, 99)'],
 ['wind','wind','Windy',' this afternoon.','windy, wind 20 mph or more'],
 ['windW','warn','Wind warning',', gusts 45 mph.','windWarning, gusts 40 mph or more'],
 ['heat','warn','Heat warning',', feels like 101°.','heatWarning, feels like 95° or more'],
 ['cold','ice','Cold warning',', feels like 2°.','coldWarning, feels like 5° or less']];
const wxSpan=(k,c,w)=>`<span class="hl wx${/^(clear|mostly|partly)$/.test(k)?' shine':''}" data-wx="${k}" data-c="var(--${c})" style="color:var(--${c});--c:var(--${c})">${w}</span>`;
const WXS={};WXC.forEach(([k,c,w,r])=>WXS[k]=wxSpan(k,c,w)+r);
const TONE={white:[['#FFFFFF','#E6E9ED','#8A949F'],['#F2F4F7','#C3C9D0','#454C54']],grey:[['#E3E6EA','#B5BCC4','#78818B'],['#B4BBC3','#838B94','#363C43']],
  rain:[['#A2ADB8','#71808D','#47535F'],['#828E9A','#56616C','#22282E']],storm:[['#8A88A4','#5A5874','#34334B'],['#75738F','#474561','#1A1928']]};
const rgba=(h,a)=>{const n=parseInt(h.slice(1),16);return `rgba(${n>>16&255},${n>>8&255},${n&255},${Math.max(0,Math.min(1,a)).toFixed(3)})`};
const isDark=()=>css('--phone').toLowerCase()==='#000000';
// a cloud is a flat-bottomed cumulus: a union of puffs filled once, lit from the top (hi to lo), with soft lit
// bumps inside and a 1.5 pt soft rim, drawn offscreen and laid on at one alpha so overlaps never bead up.
const CO=document.createElement('canvas');CO.width=900;CO.height=240;
function cloud(x,cx,cy,w,h,tone,a,t,seed){const [hi,mid,lo]=TONE[tone][isDark()?1:0],o=CO.getContext('2d'),S=2,pad=8,bw=w+pad*2,bh=h*1.5+pad*2;
  if(bw*S>CO.width||bh*S>CO.height)return cy+h*.32;o.setTransform(1,0,0,1,0,0);o.clearRect(0,0,CO.width,CO.height);o.setTransform(S,0,0,S,0,0);
  const ox=pad,oy=pad+h*.55,units=Math.max(1,Math.round(w/(h*2.4))),uw=w/units,P=[],B=[];
  for(let u=0;u<units;u++){const ux=ox+uw*u,j=Math.sin(seed*5+u*2.3),br=k=>1+.05*Math.sin(t/1800+k+seed+u);
    P.push([ux+uw*.24,oy+h*.02,h*.30*br(1)],[ux+uw*.5,oy-h*.16+j*h*.05,h*.42*br(2)],[ux+uw*.76,oy+h*.04,h*.29*br(3)]);
    if(u===0)P.push([ux+uw*.08,oy+h*.16,h*.19*br(4)]);if(u===units-1)P.push([ux+uw*.93,oy+h*.17,h*.17*br(5)]);
    B.push([ux+uw*.46,oy-h*.24+j*h*.05,h*.22],[ux+uw*.22,oy-h*.06,h*.14])}
  const base=oy+h*.3,shape=(g)=>{o.beginPath();P.forEach(([px,py,r])=>{o.moveTo(px+r+g,py);o.arc(px,py,r+g,0,7)});o.roundRect(ox-g,oy-h*.05-g,w+g*2,base-(oy-h*.05)+g*2,h*.2+g)};
  o.save();o.beginPath();o.rect(0,0,bw,base+1.6);o.clip();o.fillStyle=rgba(mid,.3);shape(1.6);o.fill();o.fillStyle=rgba(mid,1);shape(0);o.fill();
  o.globalCompositeOperation='source-atop';const g=o.createLinearGradient(0,oy-h*.6,0,base);g.addColorStop(0,hi);g.addColorStop(.55,mid);g.addColorStop(1,lo);o.fillStyle=g;o.fillRect(0,0,bw,bh);
  B.forEach(([px,py,r])=>{const rg=o.createRadialGradient(px,py,0,px,py,r*1.6);rg.addColorStop(0,rgba(hi,.75));rg.addColorStop(1,rgba(hi,0));o.fillStyle=rg;o.fillRect(px-r*2,py-r*2,r*4,r*4)});o.restore();
  x.save();x.globalAlpha=a;x.drawImage(CO,0,0,bw*S,bh*S,cx-w/2-pad,cy-h*.55-pad,bw,bh);x.restore();return cy+h*.3}
function glint(x,cx,cy,s,col,a){if(s<=.2)return;x.strokeStyle=col;x.globalAlpha=a;x.lineWidth=1;x.lineCap='round';x.beginPath();x.moveTo(cx-s,cy);x.lineTo(cx+s,cy);x.moveTo(cx,cy-s);x.lineTo(cx,cy+s);x.stroke();x.lineWidth=.7;x.beginPath();x.moveTo(cx-s*.4,cy-s*.4);x.lineTo(cx+s*.4,cy+s*.4);x.moveTo(cx-s*.4,cy+s*.4);x.lineTo(cx+s*.4,cy-s*.4);x.stroke();x.globalAlpha=1}
function flake(x,fx,fy,r){x.beginPath();for(let a=0;a<3;a++){const an=a*Math.PI/3;x.moveTo(fx-Math.cos(an)*r,fy-Math.sin(an)*r);x.lineTo(fx+Math.cos(an)*r,fy+Math.sin(an)*r)}x.stroke()}
function letters(el){if(el.dataset.split)return[...el.querySelectorAll('.lt')];el.innerHTML=[...el.textContent].map(ch=>ch===' '?' ':`<span class="lt">${ch}</span>`).join('');el.dataset.split=1;return[...el.querySelectorAll('.lt')]}
function drops(x,L,W,top,bot,n,len,lw,per,slant,col,a,t,seed){x.strokeStyle=col;x.lineWidth=lw;x.lineCap='round';for(let i=0;i<n;i++){const sp=((i*37+seed)%11)/11,u=((t/(per+sp*per*.35))+sp)%1,dx=L+3+((i*23+seed*7)%Math.max(1,W-6)),y=top+u*(bot-top),sx=slant*u;
  x.globalAlpha=a*Math.min(1,(1-u)*6,u*6);x.beginPath();x.moveTo(dx+sx+slant*.25,y);x.lineTo(dx+sx,y+len);x.stroke()}x.globalAlpha=1}
function drawWord(x,el,b,t,xb){// his 12:11 AM: clouds sit level with the word (same height), behind it, a little see-through; never above it
const cl=(cx,cy,w,h,tone,a,t2,seed)=>{const {T:bT,H:bH,L:bL,W:bW}=b,h2=Math.max(h,bH*1.1),cy2=bT+bH*.7+(cy-(bT+bH*.4))*.12;w=Math.min(w,bW*.5);cx=Math.max(bL+w*.5,Math.min(bL+bW-w*.5,cx));xb.save();xb.beginPath();xb.rect(bL-3,bT-1,bW+6,bH+2);xb.clip();cloud(xb,cx,cy2,w,h2,tone,a*(tone==="white"?(isDark()?.5:.9):.62),t2,seed);xb.restore();return bT+bH*.45};
  // soft wisps in front, the fog technique in the cloud's own colour, kept inside the word (his 12:16 AM)
  const puffs=(n,tone,a)=>{const c=TONE[tone][isDark()?1:0][0];x.save();x.beginPath();x.rect(L-3,T-1,W+6,H+2);x.clip();for(let i=0;i<n;i++){const u=((t/(8000+i*2300))+i*.41)%1,cx=L-W*.2+u*W*1.4,cy=T+H*(.4+.18*(i%3)),rw=W*(.22+.06*i),rh=H*.24;x.save();x.translate(cx,cy);x.scale(rw/rh,1);const g=x.createRadialGradient(0,0,0,0,0,rh);g.addColorStop(0,rgba(c,a*Math.sin(u*Math.PI)));g.addColorStop(1,rgba(c,0));x.fillStyle=g;x.beginPath();x.arc(0,0,rh,0,7);x.fill();x.restore()}x.restore()};const {L,T,W,H}=b,k=el.dataset.wx,col=css(el.dataset.c.slice(4,-1)),pg=css('--phone'),base=T+H*1.02;
  const wordCol=c=>{if(el.style.color!==c)el.style.color=c};
  if(k==='clearN'||k==='mostlyN'||k==='partlyN'){const N=k==='clearN'?4:k==='mostlyN'?3:2;for(let i=0;i<N;i++){const per=2600+i*700,u=((t+i*900)%per)/per,s=Math.sin(Math.min(1,u*2.2)*Math.PI)*3.6;glint(x,L+W*(.12+.78*((i*.37+.15)%1)),T+H*(i%2?.2:.06)-2,s,col,.95)}}
  if(k==='mostly'||k==='mostlyN')puffs(2,'white',.3);if(k==='partly'||k==='partlyN')puffs(3,'white',.34);if(k==='overcast')puffs(4,'grey',.4);
  if(k==='mostly')cl(L+W*(.66+.16*Math.sin(t/5200)),T+H*.36,Math.min(52,W*.36),H*.78,'white',1,t,1);
  if(k==='mostlyN')cl(L+W*(.64+.18*Math.sin(t/5600)),T+H*.36,Math.min(50,W*.34),H*.74,'white',.9,t,2);
  if(k==='partly'||k==='partlyN'){const a=k==='partly'?1:.9;cl(L+W*(.3+.12*Math.sin(t/6100)),T+H*.3,Math.min(56,W*.34),H*.78,'white',a,t,3);cl(L+W*(.76+.08*Math.sin(t/4700+1)),T+H*.3,Math.min(52,W*.32),H*.72,'white',a,t,4)}
  if(k==='overcast'){cl(L+W*(.22+.08*Math.sin(t/7000)),T+H*.28,W*.5,H*.82,'grey',.95,t,5);cl(L+W*(.7+.1*Math.sin(t/5400+2)),T+H*.44,W*.5,H*.78,'grey',.92,t,6);cl(L+W*(1.02+.05*Math.sin(t/6300)),T+H*.2,W*.36,H*.7,'grey',.88,t,7)}
  if(k==='fog'){// the word thins where the mist is thick (a moving mask), soft elongated wisps drift past in front and behind
    const m=[0,1,2].map(i=>((t/(6400+i*2100))+i*.37)%1*140-20);el.style.webkitMaskImage=el.style.maskImage=`linear-gradient(90deg,${[...Array(15)].map((_,q)=>{const p=q*100/14;let v=1;m.forEach((c,i)=>{const d=(p-c)/(16+i*5);v-=[.62,.5,.42][i]*Math.exp(-d*d)});return `rgba(0,0,0,${Math.max(.3,v).toFixed(2)}) ${p.toFixed(1)}%`}).join(',')})`;
    const fc=css('--fog'),wisp=(c,cx,cy,rw,rh,a)=>{c.save();c.translate(cx,cy);c.scale(rw/rh,1);const g=c.createRadialGradient(0,0,0,0,0,rh);g.addColorStop(0,rgba(pg,a));g.addColorStop(.5,rgba(pg,a*.6));g.addColorStop(1,rgba(pg,0));c.fillStyle=g;c.beginPath();c.arc(0,0,rh,0,7);c.fill();c.restore()},tint=(c,cx,cy,rw,rh,a)=>{c.save();c.translate(cx,cy);c.scale(rw/rh,1);const g=c.createRadialGradient(0,0,0,0,0,rh);g.addColorStop(0,rgba(fc,a));g.addColorStop(1,rgba(fc,0));c.fillStyle=g;c.beginPath();c.arc(0,0,rh,0,7);c.fill();c.restore()};
    for(let i=0;i<3;i++){const u=((t/(9000+i*2500))+i*.33)%1;tint(xb,L-W*.3+u*W*1.6,T+H*(.35+.2*i),W*.5,H*.36,.32)}
    for(let i=0;i<4;i++){const u=((t/(7000+i*1700))+i*.27)%1,a=Math.sin(u*Math.PI)*.8;wisp(x,L-W*.35+u*W*1.7,T+H*(.3+.16*i)+Math.sin(t/1500+i)*1.5,W*(.32+.08*i),H*.2,a)}}
  const rc=()=>T-2;// his 12:16 AM: no clouds on rain, snow or storms, only the weather itself
  if(k==='drizzle'){const cb=rc('rain',.8);drops(x,L,W,cb,base,16,3,.9,1050,0,col,.75,t,1)}
  if(k==='rain'){const cb=rc('rain',.88);drops(x,L,W,cb,base,11,7,1.3,640,0,col,.85,t,2)}
  if(k==='heavy'){const cb=rc('rain',.95);drops(x,L,W,cb,base,20,9,1.4,480,-3,col,.9,t,3);x.strokeStyle=col;x.lineWidth=1;for(let i=0;i<5;i++){const u=((t/520)+i*.2)%1,sx=L+W*((i*.31+.1)%1);if(u<.35){x.globalAlpha=.8*(1-u/.35);x.beginPath();x.moveTo(sx-1-u*8,base-u*6);x.lineTo(sx,base);x.lineTo(sx+1+u*8,base-u*6);x.stroke()}}x.globalAlpha=1}
  if(k==='fdrizzle'||k==='frain'){const cb=rc('rain',.85);drops(x,L,W,cb,base,k==='frain'?11:16,k==='frain'?7:3,k==='frain'?1.3:.9,k==='frain'?640:1050,0,col,.85,t,4);
    const gy=T+H*.97;x.strokeStyle=col;x.lineWidth=1.2;x.globalAlpha=.7;x.beginPath();x.moveTo(L,gy);x.lineTo(L+W,gy);x.stroke();const u=(t%3200)/3200,gx=L+u*W;x.strokeStyle=isDark()?'#FFFFFF':'#FFFFFF';x.lineWidth=1.6;x.globalAlpha=Math.sin(u*Math.PI);x.beginPath();x.moveTo(gx-7,gy);x.lineTo(gx+7,gy);x.stroke();glint(x,gx,gy,2.6*Math.sin(u*Math.PI),col,.9)}
  if(k==='snow'||k==='hsnow'){const cb=rc('grey',.82),n=k==='snow'?9:17;x.strokeStyle=col;x.lineWidth=1.1;x.lineCap='round';for(let i=0;i<n;i++){const sp=((i*41)%13)/13,u=((t/(2600+sp*1400))+sp)%1,fx=L+4+((i*27)%Math.max(1,W-8))+Math.sin(t/800+i)*4,fy=cb+u*(base-cb+6);x.globalAlpha=.95*Math.sin(u*Math.PI);flake(x,fx,fy,1.6+(i%3)*.5)}x.globalAlpha=1;
    if(k==='hsnow'){const g=.5+.5*Math.sin(t/3000);x.strokeStyle=col;x.lineWidth=1.6;x.globalAlpha=.55+.4*g;x.beginPath();for(let p=0;p<=W;p+=2){const yy=T+H*.2-Math.abs(Math.sin(p/7))*1.4*g;p?x.lineTo(L+p,yy):x.moveTo(L,yy)}x.stroke();x.globalAlpha=1}}
  if(k==='grains'){const cb=rc('grey',.75);x.strokeStyle=col;x.lineWidth=1.2;x.lineCap='round';for(let i=0;i<22;i++){const sp=((i*29)%17)/17,u=((t/(900+sp*300))+sp)%1,gx=L+2+((i*19)%Math.max(1,W-4))+Math.sin(i*7+t/200)*.6,gy=cb+u*(base-cb);x.globalAlpha=.9*Math.min(1,(1-u)*6,u*6);x.beginPath();x.moveTo(gx,gy);x.lineTo(gx,gy+1.6);x.stroke()}x.globalAlpha=1}
  if(k==='storm'||k==='hail'){const cb=rc('storm',.95);drops(x,L,W,cb,base,k==='hail'?6:10,7,1.2,560,-2,col,.7,t,5);
    if(k==='hail'){x.strokeStyle=css('--ice');x.lineWidth=1.1;for(let i=0;i<7;i++){const sp=((i*31)%9)/9,u=((t/(820+sp*200))+sp)%1,hx=L+4+((i*37)%Math.max(1,W-8));let y=cb+u/.8*(base-cb);if(u>.8){const v=(u-.8)/.2;y=base-Math.sin(v*Math.PI)*6}x.globalAlpha=u>.8?1-(u-.8)/.2*.6:Math.min(1,u*8);x.save();x.translate(hx+(u>.8?(u-.8)*20:0),y);x.rotate(u*6);x.strokeRect(-1.3,-1.3,2.6,2.6);x.restore()}x.globalAlpha=1}
    const cyc=Math.floor(t/5200),p=(t%5200)/5200,fl=p<.045||(p>.085&&p<.12);
    if(fl){let bx=L+W*(.25+.5*((cyc*.618)%1)),by=cb-2;x.strokeStyle=css('--bolt');x.lineCap='round';x.lineJoin='round';const pts=[[bx,by]];for(let s=0;s<5;s++){bx+=((s*7+cyc*3)%5-2)*2.6;by+=(base-cb)/5;pts.push([bx,by])}
      [[5,.22],[1.6,1]].forEach(([w,a])=>{x.lineWidth=w;x.globalAlpha=a;x.beginPath();pts.forEach(([px,py],j)=>j?x.lineTo(px,py):x.moveTo(px,py));x.stroke()});x.globalAlpha=1;wordCol('var(--bolt)')}else wordCol(el.dataset.c)}
  if(k==='wind'||k==='windW'){const S=letters(el),amp=k==='wind'?1:1.35;S.forEach((s,i)=>{const g=Math.max(0,Math.sin(t/(k==='wind'?1400:900)-i*.5)),sh=k==='windW'?Math.sin(t/45+i)*.35:0;s.style.transform=`translate(${(g*g*4*amp+sh).toFixed(2)}px,${(-g*g*1.2*amp).toFixed(2)}px) skewX(${(-g*g*12*amp).toFixed(1)}deg) rotate(${(g*g*2*amp).toFixed(1)}deg)`});
    x.strokeStyle=k==='wind'?col:css('--wind');x.lineWidth=1.2;x.lineCap='round';const ng=k==='wind'?5:8;for(let i=0;i<ng;i++){const u=((t/(k==='wind'?1300:850)+i*.13)%1),gx=L-18+u*(W+52),gy=T+H*(.12+.11*i%.9)+Math.sin(t/300+i)*1.2,len=(12+5*(i%3))*(k==='wind'?1:1.6);x.globalAlpha=Math.sin(u*Math.PI)*.8;x.beginPath();x.moveTo(gx,gy);x.quadraticCurveTo(gx+len*.6,gy-2,gx+len,gy);x.stroke()}x.globalAlpha=1}
  if(k==='heat'){const S=letters(el);S.forEach((s,i)=>{s.style.transform=`translateY(${(Math.sin(t/260-i*.7)*1.3).toFixed(2)}px) scaleY(${(1+Math.sin(t/260-i*.7)*.03).toFixed(3)})`});
    x.strokeStyle=col;x.lineWidth=1.1;x.lineCap='round';for(let i=0;i<4;i++){const u=((t/2200)+i*.25)%1,hx=L+W*(.15+.23*i),y0=T+H*.05-u*14;x.globalAlpha=.7*Math.sin(u*Math.PI);x.beginPath();for(let s=0;s<=10;s++){const yy=y0-s,xx=hx+Math.sin(s/2.2+t/180+i)*1.6;s?x.lineTo(xx,yy):x.moveTo(xx,yy)}x.stroke()}x.globalAlpha=1}
  if(k==='cold'){x.strokeStyle=col;x.lineCap='round';for(let i=0;i<7;i++){const per=3800,u=((t+i*540)%per)/per,s=Math.sin(Math.min(1,u*1.6)*Math.PI)*3.4,fx=L+W*(.06+.14*i),fy=i%2?T+H*.14:base+1;x.globalAlpha=.9;x.lineWidth=1;if(s>.3){flake(x,fx,fy,s);x.lineWidth=.7;for(let a=0;a<6;a++){const an=a*Math.PI/3,mx=fx+Math.cos(an)*s*.6,my=fy+Math.sin(an)*s*.6;x.beginPath();x.moveTo(mx,my);x.lineTo(mx+Math.cos(an+.6)*s*.35,my+Math.sin(an+.6)*s*.35);x.stroke()}}}x.globalAlpha=1}}
function drawSet(cv,root,t,bk){const R_=root.getBoundingClientRect(),k=cv===$('wxfx')?402/R_.width:1;if(cv!==$('wxfx')){const w=Math.round(R_.width*2),h=Math.round(R_.height*2);[cv,bk].forEach(c=>{if(c.width!==w||c.height!==h){c.width=w;c.height=h}})}
  const x=cv.getContext('2d'),xb=bk.getContext('2d');[x,xb].forEach(c=>{c.setTransform(2,0,0,2,0,0);c.clearRect(0,0,cv.width,cv.height)});if(RM)return;
  root.querySelectorAll('.wx').forEach(el=>{const b=el.getBoundingClientRect();if(b.bottom<0||b.top>innerHeight)return;drawWord(x,el,{L:(b.left-R_.left)*k,T:(b.top-R_.top)*k,W:b.width*k,H:b.height*k},t,xb)})}
function drawWx(t){drawSet($('wxfx'),$('ph'),t,$('wxbk'));const G=$('wxG');if(G)drawSet($('wxGc'),G,t,$('wxGb'))}
$('wxG').innerHTML=WXC.map(([k,c,w,r,cap])=>`<div class="wxc"><div class="wxl">${wxSpan(k,c,w)}${r}</div><div class="wxk">${cap}</div></div>`).join('')+'<canvas id="wxGc" style="position:absolute;inset:0;width:100%;height:100%;pointer-events:none;z-index:2"></canvas>';$('wxG').insertAdjacentHTML('afterbegin','<canvas id="wxGb" style="position:absolute;inset:0;width:100%;height:100%;pointer-events:none;z-index:0"></canvas>');

let wxI=WXC.findIndex(c=>c[0]==='rain');$('wxB').textContent='Weather word: '+WXC[wxI][2].toLowerCase();$('wxB').onclick=()=>{wxI=(wxI+1)%WXC.length;const [k,,w]=WXC[wxI];$('wxB').textContent='Weather word: '+w.toLowerCase();const r=$('board').children[1];r.innerHTML=WXS[k];announce(r.textContent)};
(function loop(t){drawMos(t);drawFx(t);drawWx(t);requestAnimationFrame(loop)})(performance.now());
drawOldMos();matchMedia('(prefers-color-scheme: dark)').addEventListener('change',()=>{CC={};drawOldMos()});
})();
