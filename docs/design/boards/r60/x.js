(()=>{const $=s=>document.querySelector(s),RM=matchMedia('(prefers-reduced-motion: reduce)').matches;
const BW=354,BH=350,GX=12,GY=10;
const IC={pin:'<svg viewBox="0 0 10 10" fill="none" stroke="currentColor" stroke-width="1.3" stroke-linecap="round"><path d="M3 1h4M4 1v3L2 6h6L6 4V1M5 6v4"/></svg>',lock:'<svg viewBox="0 0 10 10" fill="none" stroke="currentColor" stroke-width="1.3"><rect x="1.5" y="4.5" width="7" height="5" rx="1"/><path d="M3 4.5V3a2 2 0 0 1 4 0v1.5"/></svg>',
 wave:'<svg viewBox="0 0 10 10" fill="none" stroke="currentColor" stroke-width="1.3" stroke-linecap="round"><path d="M1 5v0M3 3v4M5 1v8M7 3v4M9 4.5v1"/></svg>',check:'<svg viewBox="0 0 10 10" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"><path d="M1.5 5.5l2.3 2.3L8.5 2"/></svg>'};
let uid=0;const N=(w,c,s,imp,rec,o={})=>({id:++uid,w,c,s,imp,rec,...o});
const POOL=[N('Gift ideas','gold','for Mom, four so far',.92,8),N('Morning pages','clay','today, 300 words',.8,40),N('Three for tomorrow','ink','from Tess, just now',.78,3,{tess:1}),
 N('Packing','lists','6 left',.86,90,{ic:'check'}),N('0:42','clay','voice memo, this morning',.62,220,{ic:'wave',num:1}),N('Private note','ink2','locked',.5,180,{ic:'lock'}),
 N('Book quotes','teal','12 quotes',.56,900),N('Standup','slate','Thursday',.48,1500),N('Level 3, row F','ink','pinned, where the car is',.7,300,{ic:'pin'}),
 N('garden','ink2','9 notes',.34,5000),N('recipes','ink2','14 notes',.36,5000),N('Form cues','training','from Training',.44,2600),N('Birthday plans','gold','in 3 weeks',.52,2000),
 N('Dream','clay','last night',.4,600),N('Podcast notes','teal','2 episodes',.32,4000),N('Lease questions','slate','ask by Monday',.58,1100),N('ideas','ink2','23 notes',.3,5000),
 N('Private note','ink2','locked',.42,3000,{ic:'lock'}),N('Paint colors','gold','three swatches',.38,2400),N('Questions to ask','slate','for Tuesday',.46,1700)];
const CAPS=[N('Call the plumber','slate','just now, today’s capture',.9,0),N('Bread starter','clay','just now',.84,0),N('Movie list','teal','just now, 3 titles',.82,0)];let capI=0;

// ---------- measuring
const cx=document.createElement('canvas').getContext('2d');const fam=n=>n.tess?"Newsreader,Georgia,serif":n.num?"Outfit,system-ui,sans-serif":"Figtree,system-ui,sans-serif";
const wgt=n=>n.tess?500:n.num?300:Math.round(480+n.imp*340);const sty=n=>n.tess?'italic ':'';
let MC=new Map();const met=n=>{const k=fam(n)+wgt(n)+n.w;if(!MC.has(k)){cx.font=`${sty(n)}${wgt(n)} 100px ${fam(n)}`;const m=cx.measureText(n.w),H=cx.measureText('Hg');MC.set(k,{a:(m.width-(n.num?0:3*0))/100*(n.tess?1:0.97)+(n.ic?.6:0),asc:H.fontBoundingBoxAscent/100,desc:H.fontBoundingBoxDescent/100})}return MC.get(k)};
const subW=n=>{cx.font=`500 12.5px Figtree,system-ui,sans-serif`;return cx.measureText(n.s).width};
const LH=1;const topFor=(n,size,base)=>{const m=met(n),box=LH*size,inner=(m.asc+m.desc)*size;return base-((box-inner)/2+m.asc*size)};
const CAP=.72,DESC=.22,SUBH=17;

// ---------- layouts -> [{n,x,y,size,sub}]
function poster(L){const n=L.length;let best=null;
  const rowOf=(i,k)=>{const ws=L.slice(i,i+k),A=ws.reduce((s,w)=>s+met(w).a,0);let size=(BW-GX*(k-1))/A;const capd=size>104;size=Math.min(size,104);const sub=ws.some(w=>subW(w)<=met(w).a*size);return{ws,size,h:size*(CAP+DESC)+(sub?SUBH:0),capd}};
  const rec=(i,prev,acc)=>{if(i>=n){const H=acc.reduce((s,r)=>s+r.h,0)+GY*(acc.length-1);let pen=(H-BH)**2;acc.forEach((r,j)=>{if(r.capd)pen+=4000;if(j&&r.size>acc[j-1].size*1.08)pen+=900});if(H>BH)pen+=(H-BH)*400;if(!best||pen<best.pen)best={pen,rows:acc};return}
    for(let k=Math.max(1,prev);k<=Math.min(5,n-i);k++){const r=rowOf(i,k);if(r.size<13)continue;rec(i+k,k,[...acc,r])}};
  rec(0,1,[]);const out=[];let y=0;best.rows.forEach(r=>{let x=0;const base=y+r.size*CAP;const tot=r.ws.reduce((s,w)=>s+met(w).a*r.size,0),gx=r.ws.length>1?(BW-tot)/(r.ws.length-1):0;
    r.ws.forEach(w=>{const ww=met(w).a*r.size;out.push({n:w,x,y:topFor(w,r.size,base),size:r.size,sub:subW(w)<=ww?base+r.size*DESC+2:null,ww});x+=ww+gx});y+=r.h+GY});return out}
function blocks(L0){const L=[...L0].sort((a,b)=>b.imp-a.imp);const out=[];let y=0,i=0;const half=(BW-GX)/2;
  while(i<L.length){const n=L[i];let cells;if(n.imp>=.78||i===0){cells=[{n,x:0,w:BW,cap:96}];i++}else{cells=[{n,x:0,w:half,cap:54}];if(L[i+1])cells.push({n:L[i+1],x:half+GX,w:half,cap:54});i+=cells.length}
   cells.forEach(c=>{c.size=Math.min(c.cap,c.w/met(c.n).a);c.sub=subW(c.n)<=c.w});const mx=Math.max(...cells.map(c=>c.size)),sub=cells.some(c=>c.sub),h=mx*(CAP+DESC)+(sub?SUBH:0);if(y+h>BH+2)break;
   const base=y+mx*CAP;cells.forEach(c=>{const ww=met(c.n).a*c.size;out.push({n:c.n,x:c.x+(c.w-ww)*0,y:topFor(c.n,c.size,base),size:c.size,sub:c.sub?base+mx*DESC+2:null,ww})});y+=h+GY}
  const spare=BH-y+GY;if(spare>0&&out.length){const rowsY=[...new Set(out.map(o=>o.y))];}return out}
function newest(L){const ord=[...L].sort((a,b)=>a.rec-b.rec);const build=mult=>{const rows=[];let cur=[],w=0;ord.forEach(n=>{const s=(16+n.imp*46)*mult,ww=met(n).a*s;if(cur.length&&w+GX+ww>BW*1.08){rows.push(cur);cur=[];w=0}cur.push({n,s,ww});w+=(cur.length>1?GX:0)+ww});if(cur.length)rows.push(cur);
   return rows.map(r=>{const raw=r.reduce((s,i)=>s+i.ww,0),f=Math.min(1.5,(BW-GX*(r.length-1))/raw);r.forEach(i=>{i.s*=f;i.ww*=f});const mx=Math.max(...r.map(i=>i.s)),sub=r.some(i=>subW(i.n)<=i.ww);return{r,mx,h:mx*(CAP+DESC)+(sub?SUBH:0),full:f<1.5}})};
  let lo=.3,hi=2,rows;for(let it=0;it<24;it++){const m=(lo+hi)/2;rows=build(m);const H=rows.reduce((s,r)=>s+r.h,0)+GY*(rows.length-1);if(H>BH)hi=m;else lo=m}rows=build(lo);
  const out=[];let y=0;rows.forEach(R=>{const base=y+R.mx*CAP;let x=0;const tot=R.r.reduce((s,i)=>s+i.ww,0),gx=R.r.length>1&&R.full?(BW-tot)/(R.r.length-1):GX;R.r.forEach(i=>{out.push({n:i.n,x,y:topFor(i.n,i.s,base),size:i.s,sub:subW(i.n)<=i.ww?base+R.mx*DESC+2:null,ww:i.ww});x+=i.ww+gx});y+=R.h+GY});return out}

// ---------- phones
const PH=[];
function phone(v,title,cap,kind){const col=document.createElement('div');col.className='col';
  col.innerHTML=`<h2>${title}</h2><div class="fit"><div class="phone"><div class="scr" data-home><div class="z ttl"><span style="color:var(--notes)">Notes</span><small>Friday</small></div>
   <div class="z state"><b style="color:var(--notes)">3 new</b> today, <b style="color:var(--lists)">packing</b> has 6 left</div><div class="band"></div>
   <div class="z ft"><span class="act">New note</span><span class="tess" aria-hidden="true"></span></div></div>
   <div class="scr sub-p"><button class="back">Back</button><div class="z ttl" style="top:118px"><span class="st"></span></div><p class="z stl" style="top:176px;margin:0;font-size:17px;color:var(--ink2)"></p></div></div></div><p>${cap}</p>`;
  $('#rows').appendChild(col);const P=col.querySelector('.phone'),home=P.querySelector('[data-home]'),sub=P.querySelector('.sub-p'),band=P.querySelector('.band');
  const S={v,band,kind,els:new Map(),vis:POOL.slice(0,12).map(n=>({...n})),P};
  S.open=n=>{const st=sub.querySelector('.st');st.textContent=n.w;st.style.color=`var(--${n.c})`;st.style.fontFamily=n.tess?'var(--tess)':'';st.style.fontStyle=n.tess?'italic':'';sub.querySelector('.stl').textContent=n.s;home.style.transform='translateX(-30%)';sub.classList.add('on')};
  sub.querySelector('.back').onclick=()=>{sub.classList.remove('on');home.style.transform=''};PH.push(S);return S}
const mkEl=(S,n)=>{const b=document.createElement('button');b.className='wd';b.innerHTML=`<span class="w" style="color:var(--${n.c});font-family:${fam(n)};font-weight:${wgt(n)};${n.tess?'font-style:italic;letter-spacing:-.01em;':''}">${n.ic?IC[n.ic]:''}${n.w}</span><span class="s">${n.s}</span>`;b.onclick=()=>S.open(n);b.setAttribute('aria-label',`${n.w}, ${n.s}`);S.band.appendChild(b);return{b,n,w:b.firstChild,sEl:b.lastChild,flip:RM?1:0,dead:0}};
const spr=(o,k,tg,K=.16,D=.72)=>{if(RM||o[k]===undefined){o[k]=tg;o['v'+k]=0;return}o['v'+k]=(o['v'+k]||0)*D+(tg-o[k])*K;o[k]+=o['v'+k]};
function pile(L){seedP=seedP||1;const r=()=>(seedP=(seedP*16807)%2147483647)/2147483647;const T=newest(L);return T.map(p=>{const sz=p.size*.92,ww=met(p.n).a*sz,ht=sz*(CAP+DESC);const x=Math.max(-10,Math.min(BW-ww*.7,r()*(BW-ww*.6))),y=BH-ht-Math.pow(r(),1.8)*170-6,rot=(r()-.5)*70;return{...p,x,y,size:sz,r:rot,sub:null,pile:1,k:.1,d:.8}})}
let seedP=0;
function relayout(S){if(S.v===3)return;if(S.v==='wall')return S.lay();const L=S.v===1?poster(S.vis):S.v===2?blocks(S.vis):S.v===5?(S.piled?pile(S.vis):newest(S.vis)):newest(S.vis);S.L=L;
  if(S.v===5&&S.cascade){const now=performance.now(),ord=[...L].sort((a,b)=>(a.y-b.y)||(a.x-b.x));ord.forEach((p,i)=>{p.hold=now+(S.piled?i*22:i*55)});S.cascade=0}
  L.forEach(p=>{let e=S.els.get(p.n.id);if(!e){e=mkEl(S,p.n);S.els.set(p.n.id,e);e.x=p.x;e.y=p.y;e.size=p.size;e.r=p.r||0}e.tg=p;e.hold=p.hold||0;if(p.hold&&!S.piled&&!RM){e.vr=(e.vr||0)+(Math.random()-.5)*6}});
  [...S.els.values()].forEach(e=>{if(!L.find(p=>p.n.id===e.n.id))e.dead=1})}
function frame(S,dt){if(S.v===3)return ticker(S,dt);
  S.els.forEach((e,id)=>{if(e.dead){e.flip=Math.max(0,(e.flip??1)-(RM?1:dt/220));if(e.flip<=0){e.b.remove();S.els.delete(id);return}}else e.flip=Math.min(1,e.flip+(RM?1:dt/300));
    if(!e.tg)return;if(e.hold&&performance.now()<e.hold&&!RM){}else{const K=e.tg.k||.16;spr(e,'x',e.tg.x,K,e.tg.d||.72);spr(e,'y',e.tg.y,K,e.tg.d||.72);spr(e,'size',e.tg.size,K);spr(e,'r',e.tg.r||0,K*.8,.7)}
    e.w.style.fontSize=e.size.toFixed(2)+'px';const ang=(1-e.flip)*90;e.b.style.transform=`translate(${e.x.toFixed(1)}px,${e.y.toFixed(1)}px) rotate(${(e.r||0).toFixed(2)}deg) perspective(400px) rotateX(${(e.dead?-ang:ang).toFixed(1)}deg)`;
    const sz=e.size;e.b.style.minHeight=Math.max(44,sz*(CAP+DESC))+'px';if(e.tg.sub!=null&&!e.tg.pile&&Math.abs(e.y-e.tg.y)<1.5&&Math.abs(e.r||0)<1){e.sEl.style.display='block';e.sEl.style.top=(e.tg.sub-e.tg.y+(e.y-e.tg.y)*0)+'px'}else e.sEl.style.display='none'})}
// ---------- ticker (variant 3)
const TR=[{h:96,sp:7},{h:76,sp:10},{h:62,sp:13},{h:50,sp:17},{h:42,sp:22}];
function tickBuild(S){S.band.innerHTML='';S.rows=[];const ord=[...POOL].sort((a,b)=>b.imp-a.imp);let y=0;TR.forEach((t,ri)=>{const items=ord.filter((_,i)=>i%5===ri);const size=(t.h-(ri<3?SUBH:0))/(CAP+DESC);const strip=document.createElement('div');strip.className='strip';strip.style.top=y+'px';S.band.appendChild(strip);
   const make=()=>{strip.innerHTML='';let x=0;const els=[];for(let rep=0;rep<2;rep++)items.forEach(n=>{const e=mkEl(S,n);e.b.remove();strip.appendChild(e.b);e.w.style.fontSize=size+'px';const ww=met(n).a*size;const base=size*CAP;e.b.style.transform=`translate(${x}px,${topFor(n,size,base)}px)`;e.b.style.minHeight='44px';e.x=x;
     if(ri<3&&subW(n)<=ww){e.sEl.style.display='block';e.sEl.style.top=(base+size*DESC+2-topFor(n,size,base))+'px'}else e.sEl.style.display='none';els.push(e);x+=ww+GX*2});return{els,len:x/2}};
   const m=make();S.rows.push({strip,off:-((ri*53)%80),sp:t.sp,len:m.len,els:m.els,size,items,ri});y+=t.h+GY});}
function ticker(S,dt){if(!S.rows)tickBuild(S);S.rows.forEach(r=>{if(!RM)r.off-=r.sp*dt/1000;if(r.off<-r.len)r.off+=r.len;r.strip.style.transform=`translateX(${r.off.toFixed(2)}px)`})}
function tickSwap(S){const r=S.rows[Math.floor(Math.random()*S.rows.length)],i=Math.floor(Math.random()*r.items.length),pool=POOL.filter(n=>!r.items.includes(n));const nn=pool[Math.floor(Math.random()*pool.length)];const old=r.items[i];
  const targets=r.els.filter(e=>e.n===old);targets.forEach(e=>{const flip=(t0)=>{const go=t=>{const u=Math.min(1,(t-t0)/360);const ang=u<.5?u*2*90:(1-u)*2*90;e.w.style.transform=`perspective(400px) rotateX(${ang}deg)`;if(u>=.5&&!e.sw){e.sw=1;const w=e.w,mw_=met(old).a*r.size;w.innerHTML=(nn.ic?IC[nn.ic]:'')+nn.w;w.style.color=`var(--${nn.c})`;w.style.fontFamily=fam(nn);w.style.fontWeight=wgt(nn);w.style.fontStyle=nn.tess?'italic':'';
      const f=Math.min(1,mw_/(met(nn).a*r.size));w.style.fontSize=(r.size*f)+'px';e.sEl.textContent=nn.s;if(subW(nn)>met(nn).a*r.size*f)e.sEl.style.display='none';e.b.onclick=()=>S.open(nn)}if(u<1&&!RM)requestAnimationFrame(go);else{e.w.style.transform='';e.sw=0}};requestAnimationFrame(go)};flip(performance.now())});r.items[i]=nn}

// ---------- build
phone(1,'1 Poster rows','<b>Strict poster.</b> Words in importance order, each row one size, scaled so the row runs exactly edge to edge; rows step down in size. One baseline per row, 12 pt gutters, 10 pt between rows.');
phone(2,'2 Masonry','<b>Masonry.</b> The most important notes take the full width; the rest pair up in two equal columns, each word set to fill its column exactly, subtitles tucked under. Every pair shares a baseline; 12 pt gutter, 10 pt between rows.');
phone(3,'3 Ticker','<b>Slow ticker.</b> Five rows of fixed sizes drift left at their own slow speeds, bigger rows slower. Every few seconds one word flips over vertically into another note in the same place. Tap a word as it passes.');
phone(4,'4 Newest first','<b>My pick: newest first, own sizes.</b> Notes run in time order from the top left, each at its own size, rows justified edge to edge on one shared baseline. A new capture lands top left and the band re-flows; older notes slide down and shrink to fit.');
const S5=phone(5,'5 Pile, then poster','<b>The pile tidies itself.</b> After a long time away, or when you pull the band down, the words lie jumbled at the bottom like a fallen heap, tilted every way. Then, word by word from the top left, they lift, straighten and click into the justified band, with their subtitles appearing last. Pull down to toss them again; pull up or tap Notes to tidy now. It also tidies itself after a moment.');
S5.piled=1;S5.cascade=1;setTimeout(()=>{S5.piled=0;S5.cascade=1;relayout(S5)},RM?0:1600);
(()=>{const P=S5.P,home=P.querySelector('[data-home]');let d=null;home.style.touchAction='none';home.addEventListener('pointerdown',e=>{d={y:e.clientY,t:performance.now()}});home.addEventListener('pointerup',e=>{if(!d)return;const k=402/P.getBoundingClientRect().width,dy=(e.clientY-d.y)*k;d=null;
  if(dy>60)toss();else if(dy<-60)tidyNow()});P.querySelector('.ttl span').style.cursor='pointer';P.querySelector('.ttl span').onclick=tidyNow;
  let tt=null;function toss(){S5.piled=1;S5.cascade=1;seedP=Math.floor(Math.random()*9e4)+1;relayout(S5);clearTimeout(tt);tt=setTimeout(tidyNow,RM?20000:2600)}function tidyNow(){if(!S5.piled)return;S5.piled=0;S5.cascade=1;relayout(S5)}S5.toss=toss})();
const fit=()=>document.querySelectorAll('.fit').forEach(f=>f.querySelector('.phone').style.transform=`scale(${f.clientWidth/402})`);fit();addEventListener('resize',fit);
const all=()=>PH.forEach(relayout);
(document.fonts?document.fonts.ready:Promise.resolve()).then(()=>{MC=new Map();PH.forEach(S=>{if(S.v===3){S.rows=null}else{S.els.forEach(e=>e.b.remove());S.els.clear()}});all();if(!S5.piled){}});all();
// liveness: swap the quietest visible note for one from the pool; now and then one grows
let tick=0;setInterval(()=>{tick++;PH.forEach(S=>{if(S.v===3){if(S.rows)tickSwap(S);return}if(S.v===5&&S.piled)return;if(S.v==='wall')return;
  if(tick%3===0){const g=S.vis[Math.floor((tick*7)%S.vis.length)];g.imp=Math.min(.95,g.imp+.28);setTimeout(()=>{g.imp-=.28;relayout(S)},RM?20000:9000)}
  else{const q=[...S.vis].sort((a,b)=>a.imp-b.imp)[(tick>>1)%3],cand=POOL.filter(n=>!S.vis.find(v=>v.id===n.id));const nn={...cand[(tick*5)%cand.length]};S.vis[S.vis.indexOf(q)]=nn}relayout(S)})},RM?20000:4200);
$('#nw').onclick=()=>{const c=CAPS[capI++%CAPS.length];PH.forEach(S=>{if(S.v===3)return;const q=[...S.vis].sort((a,b)=>a.imp-b.imp)[0];S.vis[S.vis.indexOf(q)]={...c,id:++uid};S.vis.forEach(n=>n.rec+=30);relayout(S)})};
$('#away').onclick=()=>{PH.filter(S=>S.v==='wall').forEach(S=>S.drop());S5.toss();clearTimeout(S5.t2);S5.t2=setTimeout(()=>{S5.piled=0;S5.cascade=1;relayout(S5)},RM?0:900)};
$('#tg').onclick=()=>{const on=!document.body.classList.contains('guide');document.body.classList.toggle('guide',on);$('#tg').setAttribute('aria-pressed',on)};
$('#th').onclick=()=>{document.documentElement.dataset.theme='dark'};$('#tw').onclick=()=>{document.documentElement.dataset.theme='light'};

const SK=[];(document.fonts?document.fonts.ready:Promise.resolve()).then(()=>{


// ===================== walls =====================
const WALLW=354;
const SHAPES={
 arch:(t,H)=>{const r=WALLW/2,y=t*H;let half=y<r?Math.sqrt(Math.max(0,r*r-(r-y)*(r-y))):r;half=Math.max(62,half);return[WALLW/2-half,WALLW/2+half]},
 half:(t)=>{const h=Math.sqrt(Math.max(0,1-(1-t)*(1-t)));return[WALLW-Math.max(118,WALLW*h),WALLW]},
 zig:(t)=>{const st=[.4,.6,.8,1][Math.min(3,Math.floor(t*4))]*WALLW;return[(WALLW-st)/2,(WALLW+st)/2]},
 rise:()=>[0,226]};
function wallLayout(L,shape,H,fromBottom){const ord=fromBottom?L:[...L].sort((a,b)=>b.imp-a.imp);
  const build=ch=>{const rows=[];let i=0,y=0;while(i<ord.length){const t=(y+ch/2)/H;if(t>1)break;const[x0,x1]=SHAPES[shape](Math.min(1,t),H),w=x1-x0;const s0=(ch-GY)/(CAP+DESC)*(rows.length===0&&!fromBottom?1.5:1);const cur=[];let nat=0;
    while(i<ord.length){const a=met(ord[i]).a*s0;if(cur.length&&nat+GX+a>w*1.15)break;cur.push(ord[i]);nat+=(cur.length>1?GX:0)+a;i++;if(rows.length===0&&!fromBottom)break}
    const A=cur.reduce((s,n)=>s+met(n).a,0);let size=(w-GX*(cur.length-1))/A;size=Math.min(size,s0*1.35);const ch2=size*(CAP+DESC);rows.push({cur,size,x0,w,y,h:ch2});y+=ch2+GY}return{rows,used:i,y}};
  let lo=14,hi=shape==='rise'?46:90,best;for(let it=0;it<22;it++){const m=(lo+hi)/2,b=build(m);if(b.used<ord.length)hi=m;else{lo=m;best=b}}best=best||build(lo);
  const out=[];best.rows.forEach((r,ri)=>{const base=r.y+r.size*CAP;const tot=r.cur.reduce((s,n)=>s+met(n).a*r.size,0);const gx=r.cur.length>1?(r.w-tot)/(r.cur.length-1):0;let x=r.cur.length>1?r.x0:r.x0+(r.w-tot)/2;
    r.cur.forEach(n=>{const ww=met(n).a*r.size;out.push({n,x,y:topFor(n,r.size,base),size:r.size,sub:null,ww,row:ri});x+=ww+gx})});
  if(fromBottom){const shift=H-best.y;out.forEach(o=>o.y+=shift)}return out}
function wallPhone(id,title,cap,cfg){const col=document.createElement('div');col.className='col';
  col.innerHTML=`<h2>${title}</h2><div class="fit"><div class="phone"><div class="scr" data-home><div class="z ttl"><span style="color:var(--${cfg.acc})">${cfg.room}</span><small>Friday</small></div>
   <div class="z state">${cfg.state}</div><div class="band" style="top:${cfg.top}px;height:${cfg.H}px;overflow:visible"></div>${cfg.info||''}
   <div class="z ft"><span class="act" style="color:var(--${cfg.acc})">${cfg.act}</span><span class="tess" aria-hidden="true"></span></div></div>
   <div class="scr sub-p"><button class="back">Back</button><div class="z ttl" style="top:118px"><span class="st"></span></div><p class="z stl" style="top:176px;margin:0;font-size:17px;color:var(--ink2)"></p></div></div></div><p>${cap}</p>`;
  $('#walls').appendChild(col);const P=col.querySelector('.phone'),home=P.querySelector('[data-home]'),sub=P.querySelector('.sub-p'),band=P.querySelector('.band');
  const S={v:'wall',band,els:new Map(),vis:cfg.items,P,cfg,piled:1};S.open=n=>{const st=sub.querySelector('.st');st.textContent=n.w;st.style.color=`var(--${n.c})`;st.style.fontFamily=n.tess?'var(--tess)':'';st.style.fontStyle=n.tess?'italic':'';sub.querySelector('.stl').textContent=n.s;home.style.transform='translateX(-30%)';sub.classList.add('on')};
  sub.querySelector('.back').onclick=()=>{sub.classList.remove('on');home.style.transform=''};
  let d=null;home.style.touchAction='none';home.addEventListener('pointerdown',e=>d=e.clientY);home.addEventListener('pointerup',e=>{if(d==null)return;const k=402/P.getBoundingClientRect().width,dy=(e.clientY-d)*k;d=null;if(dy>60)S.drop()});
  S.lay=()=>{const L=wallLayout(S.vis,cfg.shape,cfg.H,cfg.fromBottom);const now=performance.now();
    if(S.piled){L.forEach(p=>{p.k=.1;p.d=.78})}
    const ord=[...L].sort((a,b)=>(b.y-a.y)||(a.x-b.x));ord.forEach((p,i)=>{p.hold=S.piled?now+i*(RM?0:75):0;p.k=.11;p.d=.7});
    L.forEach(p=>{let e=S.els.get(p.n.id);if(!e){e=mkEl(S,p.n);e.flip=1;S.els.set(p.n.id,e)}if(S.piled){e.x=p.x+(Math.random()-.5)*120;e.y=-220-Math.random()*260;e.r=(Math.random()-.5)*80;e.size=p.size;e.vx=e.vy=e.vr=0}e.tg=p;e.hold=p.hold});
    [...S.els.values()].forEach(e=>{if(!L.find(p=>p.n.id===e.n.id))e.dead=1});S.piled=0};
  S.drop=()=>{S.piled=1;S.lay()};PH.push(S);return S}


const NOTE=POOL.map(n=>({...n}));
const W1=wallPhone('a','Arch','<b>Arch.</b> The most important note is the keystone at the crown; the courses widen down to the full width, each justified to the curve. The two corners the arch leaves free hold the counts.',{room:'Notes',acc:'notes',act:'New note',state:'<b style="color:var(--notes)">3 new</b> today, <b style="color:var(--lists)">packing</b> has 6 left',shape:'arch',H:520,top:176,items:NOTE.map(n=>({...n})),
  info:'<div style="position:absolute;left:24px;top:182px;font-size:13px;line-height:18px;color:var(--ink2)"><span class="n" style="font-size:30px;line-height:34px;color:var(--notes);display:block">3</span>new today</div><div style="position:absolute;right:24px;top:182px;text-align:right;font-size:13px;line-height:18px;color:var(--ink2)"><span class="n" style="font-size:30px;line-height:34px;color:var(--lists);display:block">6</span>left to pack</div>'});
const W2=wallPhone('b','Half arch','<b>Half arch.</b> The wall hugs the right side and curves away at the top; the curve’s open space holds Tess’s line and today’s counts. The narrow top course is the newest important note.',{room:'Notes',acc:'notes',act:'New note',state:'<b style="color:var(--notes)">3 new</b> today',shape:'half',H:540,top:170,items:NOTE.slice(0,17).map(n=>({...n})),
  info:'<div style="position:absolute;left:24px;top:178px;width:170px;font-family:var(--tess);font-style:italic;font-size:21px;line-height:27px;color:var(--ink)">Three things for tomorrow are waiting when you are.</div><div style="position:absolute;left:24px;top:300px;font-size:13px;line-height:18px;color:var(--ink2)"><span class="n" style="font-size:30px;line-height:34px;color:var(--lists);display:block">6</span>left to pack</div>'});
const W3=wallPhone('c','Ziggurat','<b>Ziggurat.</b> Four stepped tiers, the narrowest on top for what matters most, each step a course or two, justified to its own width. The steps leave room on both sides for small facts.',{room:'Notes',acc:'notes',act:'New note',state:'<b style="color:var(--notes)">3 new</b> today, <b style="color:var(--lists)">packing</b> has 6 left',shape:'zig',H:520,top:180,items:NOTE.map(n=>({...n})),
  info:'<div style="position:absolute;left:24px;top:186px;font-size:13px;line-height:18px;color:var(--ink2)"><span class="n" style="font-size:26px;line-height:30px;color:var(--notes);display:block">58</span>notes</div><div style="position:absolute;right:24px;top:186px;text-align:right;font-size:13px;line-height:18px;color:var(--ink2)"><span class="n" style="font-size:26px;line-height:30px;color:var(--gold);display:block">4</span>pinned</div>'});
const RW=[['Morning pages','gold','7 am, done'],['Vitamins','gold','7:30, done'],['Walk','training','12:30, done'],['Push-ups','training','5 pm, done'],['Water the plants','clay','late since 9 am'],['Evening stretch','slate','next, 8 pm'],['Tidy kitchen','clay','9 pm'],['Read','teal','9:30 pm'],['Journal','teal','10:30 pm']].map((r,i)=>({id:900+i,w:r[0],c:r[1],s:r[2],imp:.6,rec:i}));
let laid=4;const W4=wallPhone('d','Rising wall, Routines','<b>Another room: Routines, a wall that rises with the day.</b> Every routine you finish is laid as a brick, bottom up in the order you did them; the wall’s height is how full the day has been. What’s still to do lies on the ground to the right, the late one in wine. Tap “Lay the next one” to watch a brick go up.',{room:'Routines',acc:'routines',act:'Start stretch',state:'<b style="color:var(--go)">4 done</b>, stretch at 8, <b style="color:var(--wine)">plants</b> late',shape:'rise',fromBottom:1,H:470,top:200,items:RW.slice(0,laid),
  info:'<div class="pend" style="position:absolute;left:262px;top:520px;width:120px;height:160px"></div><button class="tr layb" style="position:absolute;left:28px;top:140px">Lay the next one</button><div style="position:absolute;left:24px;right:24px;top:671px;border-top:1px solid var(--ink3);opacity:.6"></div>'});
const pend=()=>{const P=W4.P.querySelector('.pend');P.innerHTML=RW.slice(laid).map((r,i)=>`<div style="position:absolute;left:${(i%2)*10}px;top:${142-i*27}px;transform:rotate(${(i%2?-1:1)*(2+i*1.5)}deg);transform-origin:0 100%;white-space:nowrap;font-weight:600;font-size:17px;color:${r.s.startsWith('late')?'var(--wine)':'var(--ink2)'}">${r.w}</div>`).join('')};pend();
W4.P.querySelector('.layb').onclick=()=>{if(laid>=RW.length){laid=4;W4.vis=RW.slice(0,laid);W4.els.forEach(e=>e.b.remove());W4.els.clear();W4.piled=1;W4.lay();pend();return}laid++;W4.vis=RW.slice(0,laid);const now=performance.now();W4.lay();const e=W4.els.get(RW[laid-1].id);e.x=330;e.y=380;e.r=-30;e.hold=now;pend()};
[W1,W2,W3,W4].forEach(S=>S.lay());

// ===================== type study =====================
const SPW=POOL.slice(0,15);
const TR5=[
 {t:'1 Figtree, weight by importance',c:'One variable face, weight 400 to 800 with importance; kind colors.',fam:n=>n.tess?'Newsreader':n.num?'Outfit':'Figtree',wt:(n,d)=>n.tess?500:n.num?300:Math.round(400+n.imp*400-(d?40:0)),st:()=>'',it:n=>!!n.tess},
 {t:'2 Bricolage condensed',c:'Bricolage Grotesque at 75% width, weight 640 to 800, a true poster face with optical sizing; more words per course.',fam:n=>n.tess?'Newsreader':n.num?'Outfit':'Bricolage Grotesque',wt:(n,d)=>n.tess?500:n.num?300:Math.round(640+n.imp*160-(d?40:0)),st:n=>n.tess||n.num?'':'condensed',it:n=>!!n.tess},
 {t:'3 Fraunces and Figtree',c:'Fraunces (soft serif) for the big notes, Figtree for small ones, Newsreader italic for Tess. Warm, bookish.',fam:n=>n.tess?'Newsreader':n.num?'Outfit':n.imp>=.6?'Fraunces':'Figtree',wt:(n,d)=>n.tess?500:n.num?300:n.imp>=.6?(d?560:600):(d?520:560),st:()=>'',it:n=>!!n.tess},
 {t:'4 One weight',c:'Figtree 600 everywhere; size is the only signal. Very even, a little flat.',fam:n=>n.tess?'Newsreader':n.num?'Outfit':'Figtree',wt:(n,d)=>n.tess?500:n.num?300:(d?580:600),st:()=>'',it:n=>!!n.tess},
 {t:'5 Three steps, tuned (pick)',c:'Figtree in three weight steps (720, 620, 520), tracking by size, dark 40 lighter, small words +20 on paper.',fam:n=>n.tess?'Newsreader':n.num?'Outfit':'Figtree',wt:(n,d)=>n.tess?500:n.num?300:(n.imp>=.7?720:n.imp>=.45?620:520)-(d?40:0)+(!d&&n.imp<.45?20:0),st:()=>'',it:n=>!!n.tess}];
const lsFor=s=>s>=48?-.035:s>=28?-.025:s>=18?-.01:0;
function setWall(inn,T,dark,col){inn.innerHTML='';const H=268,BW2=330,X0=12;const m=(n,sz)=>{cx.font=`${T.it(n)?'italic ':''}${T.wt(n,dark)} ${sz}px "${T.fam(n)}"`;cx.fontStretch=T.st(n)||'normal';const w=cx.measureText(n.w).width;const A=cx.measureText('H');cx.fontStretch='normal';return{w:w+lsFor(sz)*sz*(n.w.length-1)+(n.ic?sz*.6:0),asc:A.fontBoundingBoxAscent,desc:A.fontBoundingBoxDescent}};
  const ord=[...SPW].sort((a,b)=>b.imp-a.imp);const build=mult=>{const rows=[];let cur=[],w=0;ord.forEach(n=>{const sz=(13+n.imp*40)*mult,ww=m(n,sz).w;if(cur.length&&w+12+ww>BW2*1.1){rows.push(cur);cur=[];w=0}cur.push({n,sz,ww});w+=(cur.length>1?12:0)+ww});if(cur.length)rows.push(cur);
   return rows.map(r=>{const raw=r.reduce((s,i)=>s+i.ww,0),f=Math.min(1.4,(BW2-12*(r.length-1))/raw);r.forEach(i=>{i.sz*=f;i.ww=m(i.n,i.sz).w});const mx=Math.max(...r.map(i=>i.sz));return{r,mx,h:mx*.94,full:f<1.4}})};
  let lo=.3,hi=2.5,rows;for(let k=0;k<22;k++){const mm=(lo+hi)/2;rows=build(mm);const Hh=rows.reduce((s,r)=>s+r.h,0)+10*(rows.length-1);if(Hh>H)hi=mm;else lo=mm}rows=build(lo);
  let y=12;rows.forEach(R=>{const base=y+R.mx*.73;const tot=R.r.reduce((s,i)=>s+i.ww,0),gx=R.r.length>1&&R.full?(BW2-tot)/(R.r.length-1):12;let x=X0;R.r.forEach((i,ii)=>{const e=document.createElement('div');e.className='t';const mt=m(i.n,i.sz);
     e.innerHTML=(i.n.ic?IC[i.n.ic]:'')+i.n.w;e.style.cssText+=`font-family:"${T.fam(i.n)}",sans-serif;font-weight:${T.wt(i.n,dark)};font-size:${i.sz.toFixed(2)}px;letter-spacing:${lsFor(i.sz)}em;${T.it(i.n)?'font-style:italic;':''}${T.st(i.n)?'font-stretch:75%;font-variation-settings:"wdth" 75;':''}color:${col(i.n,ii,R)};left:${x.toFixed(1)}px;top:${(base-((i.sz-(mt.asc+mt.desc))/2+mt.asc)).toFixed(1)}px;font-optical-sizing:auto`;
     const sv=e.querySelector('svg');if(sv)sv.style.cssText='width:.5em;height:.5em;margin-right:.1em;vertical-align:.08em';inn.appendChild(e);x+=i.ww+gx});y+=R.h+10})}
const kindCol=n=>`var(--${n.c})`;
const specBox=(host,title,cap,T,col)=>{const d=document.createElement('div');d.className='spc';d.innerHTML=`<div class="sp2"><div class="sbx fl"><div class="in"></div></div><div class="sbx fd"><div class="in"></div></div></div><p><b>${title}.</b> ${cap}</p>`;$(host).appendChild(d);
  const [a,b]=d.querySelectorAll('.sbx');const go=()=>{[a,b].forEach((bx,i)=>{const inn=bx.querySelector('.in');inn.style.transform=`scale(${bx.clientWidth/354})`;setWall(inn,T,i===1,col)})};go();new ResizeObserver(()=>{[a,b].forEach(bx=>bx.querySelector('.in').style.transform=`scale(${bx.clientWidth/354})`)}).observe(d)};
TR5.forEach(T=>specBox('#spec',T.t,T.c,T,kindCol));
const ranked=[...SPW].sort((a,b)=>b.imp-a.imp);const rk=n=>ranked.indexOf(n);
specBox('#spec2','Kind colors, full','Every note in its kind’s color. Lively, but busy: six colors at once breaks the 3 to 4 rule.',TR5[4],kindCol);
specBox('#spec2','Tonal','Notes violet in three tints by importance, with one accent (gold) for the single most important note. Calm and branded, but kinds no longer read.',TR5[4],n=>rk(n)===0?'var(--gold)':rk(n)<4?'var(--v1)':rk(n)<9?'var(--v2)':'var(--v3)');
specBox('#spec2','Ink, important in color (pick)','The top five in their kind colors, the rest in ink and ink 2 by importance. Color means “this matters”, and the page stays at 3 to 4 colors.',TR5[4],n=>rk(n)<5?`var(--${n.c})`:rk(n)<9?'var(--ink)':'var(--ink2)');

// ===================== sketches =====================
const SW=[['Gift ideas','gold',.92],['Packing','lists',.86],['Morning pages','clay',.8],['Three for tomorrow','ink',.78,1],['Level 3, row F','ink',.7],['0:42','clay',.62],['Lease questions','slate',.58],['Book quotes','teal',.56],['Birthday plans','gold',.52],['Standup','slate',.48],['Form cues','training',.44],['garden','ink2',.34],['recipes','ink2',.36],['Dream','clay',.4]];
const tw=(w,sz,wt=700,tess)=>{cx.font=`${tess?'italic 500':wt} ${sz}px ${tess?'Newsreader,serif':'Figtree,system-ui'}`;return cx.measureText(w).width*(tess?1:.97)};
function sketch(title,cap,init){const d=document.createElement('div');d.className='skw';d.innerHTML=`<div class="sk"><div class="in"></div></div><p><b>${title}.</b> ${cap}</p>`;$('#sks').appendChild(d);const box=d.querySelector('.sk'),inn=d.querySelector('.in');
  const fitS=()=>inn.style.transform=`scale(${box.clientWidth/354})`;fitS();new ResizeObserver(fitS).observe(box);
  const mk=(w,c,sz,tess)=>{const e=document.createElement('div');e.className='t';e.textContent=w;e.style.color=`var(--${c})`;e.style.fontSize=sz+'px';if(tess){e.style.fontFamily='var(--tess)';e.style.fontStyle='italic';e.style.fontWeight=500;e.style.letterSpacing='-.01em'}inn.appendChild(e);return e};
  const st=init(inn,mk,box);SK.push(st)}
const ease=u=>1-Math.pow(1-u,3),pos=(e,x,y,r=0,sx=1,ex='')=>e.style.transform=`translate(${x.toFixed(1)}px,${y.toFixed(1)}px) rotate(${r}deg) scale(${sx})${ex}`;
// 1 fan
sketch('Fan fold','The band folds shut like a paper fan when you scroll past it and fans open as you come back. Tap to fold.',(inn,mk,box)=>{const rows=[[0,1],[2,3],[4,5,6],[7,8,9],[10,11,12,13]].map((ix,ri)=>{const ws=ix.map(i=>SW[i]),A=ws.reduce((s,w)=>s+tw(w[0],100,700,w[3])/100,0),sz=Math.min(60,(330-10*(ws.length-1))/A);const row=document.createElement('div');row.style.cssText='position:absolute;left:12px;top:0;width:330px;transform-origin:50% 0';inn.appendChild(row);let x=0;const tot=ws.reduce((s,w)=>s+tw(w[0],sz,700,w[3]),0),g=ws.length>1?(330-tot)/(ws.length-1):0;
  ws.forEach(w=>{const e=mk(w[0],w[1],sz,w[3]);row.appendChild(e);pos(e,x,0);x+=tw(w[0],sz,700,w[3])+g});return{row,h:sz*.95}});let open=1,a=0;box.onclick=()=>open^=1;
  return t=>{const auto=RM?1:((t/5200)%1<.7?1:0);const tg=(open&&auto)?0:78;a+=RM?(tg-a):(tg-a)*.08;let y=10;rows.forEach((r,i)=>{const ang=(i%2?-1:1)*a;r.row.style.transform=`translateY(${y.toFixed(1)}px) perspective(500px) rotateX(${ang.toFixed(1)}deg)`;y+=(r.h+6)*Math.cos(a*Math.PI/180)})}});
// 2 split-flap poster
sketch('Flap poster','A fixed grid where each cell flips over to its next note, like a departure board but for words; sizes stay, content turns.',(inn,mk)=>{const cells=[[12,14,330,64],[12,88,160,44],[182,88,160,44],[12,142,104,34],[124,142,104,34],[236,142,106,34],[12,186,104,30],[124,186,104,30],[236,186,106,30]];let k=0;
  const C=cells.map(([x,y,w,h],i)=>{const it=SW[i],e=mk('', it[1],h);pos(e,x,y);const set=it=>{e.textContent=it[0];e.style.color=`var(--${it[1]})`;let f=h;e.style.fontSize=f+'px';while(tw(it[0],f)>w&&f>10){f--;}e.style.fontSize=f+'px';e.style.fontFamily=it[3]?'var(--tess)':'';e.style.fontStyle=it[3]?'italic':''};set(it);return{e,x,y,set,f:0,i}});
  let nx=0,lt=0;return t=>{if(t-lt>1300&&!RM){lt=t;const c=C[(nx*4)%C.length];nx++;c.f=t;c.nx=SW[(c.i+nx*3)%SW.length]}C.forEach(c=>{if(!c.f)return;const u=Math.min(1,(t-c.f)/420);const ang=u<.5?u*180:(u-1)*180;if(u>=.5&&c.nx){c.set(c.nx);c.nx=null}pos(c.e,c.x,c.y,0,1,` perspective(300px) rotateX(${ang.toFixed(0)}deg)`);if(u>=1)c.f=0})}});
// 3 magnets
sketch('Magnets','Words drop in and snap edge to edge into rows, each one clicking against the last, then let go and fall away. Notes you add arrive like this.',(inn,mk)=>{const items=SW.slice(0,11),E=[];let tgt=[],x=12,y=14,rowH=0,t0=0;items.forEach(w=>{const sz=16+w[2]*30,ww=tw(w[0],sz,700,w[3]);if(x+ww>342){x=12;y+=rowH+6;rowH=0}tgt.push({x,y,sz});x+=ww+8;rowH=Math.max(rowH,sz*.95);E.push(mk(w[0],w[1],sz,w[3]))});
  return t=>{if(!t0)t0=t;const T=RM?1e9:(t-t0)%9000;E.forEach((e,i)=>{const g=tgt[i],st=i*380,u=Math.max(0,Math.min(1,(T-st)/420));let yy;if(T>7600){const v=(T-7600)/900;yy=g.y+v*v*400}else{yy=u<1?-60+(g.y+60)*u*u:g.y;if(u>=1){const b=(T-st-420)/120;if(b<1)yy-=Math.sin(b*Math.PI)*3}}pos(e,g.x,RM?g.y:yy)})}});
// 4 mural
sketch('Mural','The words set as one huge poster wall, far bigger than the band, that slowly pans past like a camera over a mural. Drag to look around.',(inn,mk,box)=>{const wall=document.createElement('div');wall.style.cssText='position:absolute;left:0;top:0';inn.appendChild(wall);let y=0;for(let r=0;r<7;r++){const sz=[96,60,74,44,84,52,66][r];let x=0;let i=r*3;while(x<900){const w=SW[i%SW.length];const e=mk(w[0],w[1],sz,w[3]);wall.appendChild(e);pos(e,x,y);x+=tw(w[0],sz,700,w[3])+14;i+=5}y+=sz*.92+6}
  let dx=0,dy=0,dr=null;box.addEventListener('pointerdown',e=>dr={x:e.clientX-dx,y:e.clientY-dy});box.addEventListener('pointermove',e=>{if(dr){dx=e.clientX-dr.x;dy=e.clientY-dr.y}});box.addEventListener('pointerup',()=>dr=null);
  return t=>{const px=RM?-120:-300+Math.sin(t/9000)*270+dx,py=RM?-60:-130+Math.cos(t/7000)*110+dy;wall.style.transform=`translate(${px.toFixed(1)}px,${py.toFixed(1)}px)`}});
// 5 letterpress
sketch('Letterpress','Each word is pressed into the page: it lands a touch large and a touch heavy, then settles with a tiny kick to the words already set.',(inn,mk)=>{const items=SW.slice(0,9),E=[],G=[];let x=12,y=14,rh=0;items.forEach(w=>{const sz=18+w[2]*32,ww=tw(w[0],sz,700,w[3]);if(x+ww>342){x=12;y+=rh+8;rh=0}G.push({x,y});x+=ww+10;rh=Math.max(rh,sz*.92);const e=mk(w[0],w[1],sz,w[3]);e.style.opacity=0;E.push(e)});let t0=0;
  return t=>{if(!t0)t0=t;const T=RM?1e9:(t-t0)%8000;let kick=0;E.forEach((e,i)=>{const st=i*520,u=(T-st)/260;if(T>7400||u<0){e.style.opacity=RM?1:0;if(RM)pos(e,G[i].x,G[i].y);return}e.style.opacity=1;const sc=u<1?1.22-.25*ease(u):1-.03*Math.max(0,1-(u-1)*3);if(u>=1&&u<1.4)kick=1;pos(e,G[i].x,G[i].y,0,sc);e.style.fontWeight=u<1?900:700});
   if(kick&&!RM)E.forEach((e,i)=>{})}});
// 6 sand
sketch('Pour','The words pour in letter by letter like sand and settle into a justified block, each letter finding its place in reading order.',(inn,mk)=>{const L=[];let y=12;[[0,2],[1,6,7],[4,9,11]].forEach(ix=>{const ws=ix.map(i=>SW[i]),sz=Math.min(54,(330-14*(ws.length-1))/ws.reduce((s,w)=>s+tw(w[0],100,700,w[3])/100,0));const tot=ws.reduce((s,w)=>s+tw(w[0],sz,700,w[3]),0),g=ws.length>1?(330-tot)/(ws.length-1):0;let x=12;
   ws.forEach(w=>{let cx_=x;[...w[0]].forEach(ch=>{const cw=tw(ch,sz,700,w[3]);if(ch!==' '){const e=mk(ch,w[1],sz,w[3]);e.style.letterSpacing='0';L.push({e,x:cx_,y,sx:40+Math.random()*270})}cx_+=cw+(w[3]?0:-sz*.03*0)});x+=tw(w[0],sz,700,w[3])+g});y+=sz*.98+6});let t0=0;
  return t=>{if(!t0)t0=t;const T=RM?1e9:(t-t0)%9000;L.forEach((l,i)=>{const st=i*55,u=Math.max(0,Math.min(1,(T-st)/700));if(T>8200){const v=(T-8200)/800;l.e.style.opacity=1-v;pos(l.e,l.x,l.y+v*v*30);return}l.e.style.opacity=u>0?1:0;const yy=-40+(l.y+40)*u*u,xx=l.sx+(l.x-l.sx)*ease(u);pos(l.e,RM?l.x:xx,RM?l.y:yy)})}});
// 7 drum
sketch('Drum','The notes ride a turning drum; the one facing you is full size and in color, the ones rolling away tilt and shrink. Drag up or down to spin it.',(inn,mk,box)=>{const n=12,E=SW.slice(0,n).map(w=>{const e=mk(w[0],w[1],40,w[3]);e.style.left='0';return{e,w}});let a=0,v=.004,dr=null;box.addEventListener('pointerdown',e=>dr=e.clientY);box.addEventListener('pointermove',e=>{if(dr!=null){v=(dr-e.clientY)*.0009;dr=e.clientY}});box.addEventListener('pointerup',()=>dr=null);
  return t=>{if(!RM){a+=v;v+=(.0035-v)*.02}E.forEach((o,i)=>{const th=(i/n)*Math.PI*2-a,z=Math.cos(th),yy=115+Math.sin(th)*92;if(z<0){o.e.style.opacity=0;return}const sz=40,w=tw(o.w[0],sz,700,o.w[3]);o.e.style.opacity=1;o.e.style.color=z>.93?`var(--${o.w[1]})`:'var(--ink3)';o.e.style.transform=`translate(${(177-w/2).toFixed(1)}px,${(yy-sz*.5).toFixed(1)}px) scaleY(${z.toFixed(3)}) scale(${(.6+.4*z).toFixed(3)})`;o.e.style.transformOrigin=`${w/2}px 50%`})}});
// 8 masthead
sketch('Masthead','A front page that rearranges itself by importance: the top note is the headline, the next two are the deck, the rest run as small type. When something matters more, it takes the headline.',(inn,mk)=>{const it=SW.slice(0,9).map(w=>({w,imp:w[2],e:mk(w[0],w[1],20,w[3])}));let lt=0,k=0;const lay=()=>{const o=[...it].sort((a,b)=>b.imp-a.imp);o.forEach((x,i)=>{let sz,X,Y;if(i===0){sz=Math.min(64,330/(tw(x.w[0],100,700,x.w[3])/100));X=12;Y=12}else if(i<3){sz=Math.min(30,158/(tw(x.w[0],100,700,x.w[3])/100));X=i===1?12:184;Y=88}else{sz=Math.min(18,104/(tw(x.w[0],100,700,x.w[3])/100));X=12+((i-3)%3)*112;Y=140+Math.floor((i-3)/3)*30}x.tg={X,Y,sz}})};lay();it.forEach(x=>{x.x=x.tg.X;x.y=x.tg.Y;x.s=x.tg.sz});
  return t=>{if(t-lt>3200&&!RM){lt=t;it.forEach(x=>x.imp=x.w[2]);const p=it[(++k*5)%it.length];p.imp=1.2;lay()}it.forEach(x=>{const K=RM?1:.12;x.x+=(x.tg.X-x.x)*K;x.y+=(x.tg.Y-x.y)*K;x.s+=(x.tg.sz-x.s)*K;x.e.style.fontSize=x.s.toFixed(2)+'px';pos(x.e,x.x,x.y)})}});
});
let lt=performance.now();(function loop(t){const dt=Math.min(60,t-lt);lt=t;PH.forEach(S=>frame(S,dt));SK.forEach(f=>f(t));requestAnimationFrame(loop)})(lt);
})();
