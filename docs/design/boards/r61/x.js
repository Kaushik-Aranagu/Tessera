(()=>{
const RM=matchMedia('(prefers-reduced-motion: reduce)').matches;
const POOL=[['Trip packing',9,1],['Mom’s birthday',9,6],['Tacos',8,3],['Garage',7,2],['Book ideas',8,4],['Passport',7,1],['Work notes',6,5],['Gift list',6,6],['Dreams',5,4],['Run plan',6,7],['Recipes',6,3],['Plumber',4,2],['Tess said',5,4],['Voice memo',4,5],['Wifi code',3,2],['Movies',4,4],['Sleep log',3,7],['Paint colors',4,2],['Kids’ sizes',3,6],['Coffee beans',3,3],['Quotes',3,4],['Bike fit',3,7],['Taxes',4,5],['Doctor',4,7],['Neighbors',2,6],['Podcasts',2,4],['Seeds',2,2],['Spices',2,3],['Shoes',2,6],['Old phone',2,2],['Jokes',2,4],['Stretch',2,7],['Wine',2,3],['Fonts',2,4],['Keys',2,2]];
let caps=false,start=0,FACE='Archivo',STR='75%';const FW={stack:700};
const cv=document.createElement('canvas').getContext('2d');
const W=354,H=470,GAP=3;
function wd(t,size,wt){cv.font=`${STR==='75%'?'condensed ':''}${wt} ${size}px '${FACE}'`;return cv.measureText(caps?t.toUpperCase():t).width}
// Rows solve their own height: a single word's width is a*h/.86, and a stack of n words, each line sized to fill the
// brick's width, is (h-(n-1)GAP)/(.86*sum(1/a_i)) wide, so a row's width is (almost) linear in h. Each row picks bricks
// until it reaches its target height's width, then h is solved so the row meets both edges exactly. Nothing is stretched.
const unit=(t,wt)=>wd(t,100,wt)/100;// width per px of font size
function brickW(b,h){if(!b.stack)return b.a/.86*h;const n=b.lines.length;return (h-(n-1)*GAP)/(.86*b.lines.reduce((s,l)=>s+1/l.a,0))}
function solveH(bricks){let lo=4,hi=400;for(let k=0;k<40;k++){const m=(lo+hi)/2,w=bricks.reduce((s,b)=>s+brickW(b,m),0)+GAP*(bricks.length-1);if(w>W)hi=m;else lo=m}return lo}
const MINFS=13;// nothing smaller than 13 px, so the smallest bricks still read
function layout(words){const s0=[...words].sort((a,b)=>b[1]-a[1]),hi=s0.filter(x=>x[1]>3),lo=s0.filter(x=>x[1]<=3).sort((a,b)=>b[0].length-a[0].length);// stacks pair words of like length, so no line shrinks to nothing
  const items=hi.concat(lo);const out=[];let y=0,f=0,e=items.length-1,r=0;
  const T=[74,52,62,46,68,50,58,44];const PAT=[['B','S'],['S','B','S'],['B','B','S'],['S','B'],['B','S','B']];
  const mk=(x,wt)=>({t:x[0],k:x[2],wt,a:unit(x[0],wt)});
  while(f<=e&&y<H-14){const tgt=Math.min(T[r%T.length],H-y),pat=PAT[r%PAT.length],bricks=[];let wsum=0,p=0;
    while(f<=e){const kind=pat[p%pat.length];p++;let b;
      if(kind==='B'){const wt=tgt>=60?900:800;b={lines:[mk(items[f],wt)],wt};b.a=b.lines[0].a;f++}
      else{let n=tgt>=60?3:2;while(n>1&&(tgt-(n-1)*GAP)/n<MINFS*.86/.75)n--;const L=[];for(let q=0;q<n&&e>=f;q++)L.push(mk(items[e--],FW.stack));b=L.length>1?{stack:true,lines:L,wt:FW.stack}:{lines:L,wt:FW.stack,a:L[0].a}}
      bricks.push(b);wsum+=brickW(b,tgt)+(bricks.length>1?GAP:0);if(wsum>=W*.95)break}
    let h=solveH(bricks);
    if(y+h>H){h=H-y}
    let x=0;bricks.forEach(b=>{const bw=brickW(b,h);
      if(!b.stack){const fs=h/.86;out.push({t:b.lines[0].t,x,y,fs,wt:b.wt,h,ls:0})}
      else{let yy=y;b.lines.forEach(l=>{const fs=bw/l.a,lh=fs*.86;out.push({t:l.t,x,y:yy,fs,wt:l.wt,h:lh,ls:0});yy+=lh+GAP})}
      x+=bw+GAP});
    y+=h+GAP;r++}
  return out}
function render(P){let wall=P.querySelector('.wall');const vis=POOL.slice(start).concat(POOL.slice(0,start));const L=layout(vis);
  const old={};wall.querySelectorAll('.w').forEach(e=>old[e.dataset.t]=e);const keep=new Set();let ci=0;
  L.forEach((o,idx)=>{let e=old[o.t];if(!e){e=document.createElement('div');e.className='w';e.dataset.t=o.t;e.style.opacity=0;wall.appendChild(e);e.onclick=()=>{e.animate([{filter:'none'},{opacity:.4},{opacity:1}],{duration:300})}}
    keep.add(o.t);e.textContent=caps?o.t.toUpperCase():o.t;e.style.font=`${o.wt} ${o.fs}px '${FACE}'`;e.style.fontStretch=STR;e.style.letterSpacing=(o.ls||0)+'px';e.style.height=o.h+'px';e.style.lineHeight=o.h+'px';
    e.style.color=`var(--c${(idx*5)%12})`;
    const tr=`translate(${o.x}px,${o.y}px)`;
    if(RM){e.style.transform=tr;e.style.opacity=1}else{e.style.transition='transform .6s cubic-bezier(.2,.9,.25,1.05),opacity .4s';e.style.transform=tr;requestAnimationFrame(()=>e.style.opacity=1)}});
  Object.keys(old).forEach(t=>{if(!keep.has(t)){old[t].style.opacity=0;setTimeout(()=>old[t].remove(),450)}})}
function build(P){P.innerHTML=`<div class="z" style="top:54px;font-size:40px;font-weight:700;letter-spacing:-.03em;line-height:44px;color:var(--room)">Notes</div><div class="z" style="top:104px;font-size:16px;color:var(--t2)">Three new today, one from Tess.</div><div class="wall"></div><div class="z" style="top:640px;font-size:15px;line-height:22px;color:var(--t2)">Pinned: <b style="color:var(--t);font-weight:600">Trip packing</b>, <b style="color:var(--t);font-weight:600">Mom’s birthday</b>.</div><div class="z" style="left:28px;bottom:30px;height:44px;display:flex;align-items:center"><button class="act">New note</button></div><span class="tess"></span>`}
const PH=[document.getElementById('p1'),document.getElementById('p2')];PH.forEach(build);
function all(){PH.forEach(render)}
function toss(){if(RM){all();return}PH.forEach(P=>{P.querySelectorAll('.w').forEach((e,i)=>{e.style.transition='transform .55s cubic-bezier(.5,0,.75,0)';const x=(i*53)%240,y=360+((i*37)%90);e.style.transform=`translate(${x}px,${y}px) rotate(${((i*29)%50)-25}deg)`})});setTimeout(all,900)}
function fit(){document.querySelectorAll('.fit').forEach(f=>{f.firstElementChild.style.transform=`scale(${f.clientWidth/402})`})}addEventListener('resize',fit);fit();
document.getElementById('toss').onclick=toss;document.getElementById('swap').onclick=()=>{start=(start+3)%POOL.length;all()};
document.querySelectorAll('.ff').forEach(b=>b.onclick=()=>{FACE=b.dataset.f;STR=b.dataset.s;document.querySelectorAll('.ff').forEach(x=>x.setAttribute('aria-pressed',x===b));const st=STR==='75%'?'condensed ':'';Promise.all(['700','800','900'].map(w=>document.fonts.load(`${st}${w} 40px '${FACE}'`,'Ab'))).then(all,all)});
document.querySelectorAll('.cs').forEach(b=>b.onclick=()=>{caps=b.dataset.c==='u';document.querySelectorAll('.cs').forEach(x=>x.setAttribute('aria-pressed',x===b));all()});
(document.fonts?Promise.all(['700','800','900'].map(w=>document.fonts.load(`condensed ${w} 40px 'Archivo'`,'Ab'))).then(()=>document.fonts.ready):Promise.resolve()).then(()=>{all();if(!RM)setTimeout(toss,600)});
setInterval(()=>{if(RM)return;start=(start+1)%POOL.length;all()},6000);
})();
