(()=>{const $=s=>document.querySelector(s),RM=matchMedia('(prefers-reduced-motion: reduce)').matches;
let T=1180,play=0;const fmt=m=>{const h=Math.floor(m/60),mi=m%60,ap=h>=12?'PM':'AM',hh=h%12||12;return mi?`${hh}:${String(mi).padStart(2,'0')} ${ap}`:`${hh} ${ap}`};
const cx=document.createElement('canvas').getContext('2d');const mw=(t,s,wt)=>{cx.font=`${Math.round(wt)} ${s}px Figtree,system-ui,sans-serif`;return cx.measureText(t).width};

// ---------- live state
const RT=[{n:'Morning pages',k:'Mornings',at:420,min:10},{n:'Vitamins',k:'Mornings',at:450,min:2},{n:'Water the plants',k:'Home',at:540,min:5,doneAt:1240},{n:'Walk',k:'Body',at:750,min:25},{n:'Push-ups',k:'Body',at:1020,min:8},{n:'Evening stretch',k:'Evenings',at:1200,min:12},{n:'Tidy kitchen',k:'Home',at:1260,min:15},{n:'Read 20 minutes',k:'Mind',at:1290,min:20},{n:'Journal',k:'Mind',at:1350,min:10}];
const isDone=r=>T>=(r.doneAt??(r.at+r.min));const isLate=r=>!isDone(r)&&T>r.at+30;
const ROOMS={
 routines:{title:'Routines',acc:'routines',act:'Start next',words:[['Mornings','gold'],['Evenings','slate'],['Body','training'],['Home','clay'],['Mind','teal'],['Borrowed','kitchen']],
  st(k){if(k==='Borrowed')return{imp:.22,s:'3 from other rooms',st:'wait'};const rs=RT.filter(r=>r.k===k),late=rs.find(isLate),open=RT.filter(r=>!isDone(r)).sort((a,b)=>a.at-b.at),nx=open.find(r=>!isLate(r)),mine=rs.filter(r=>!isDone(r));
   const h=m=>fmt(m).replace(':00','').toLowerCase();
   if(late)return{imp:1,s:`${late.n.toLowerCase()}, late since ${h(late.at)}`,st:'late'};
   if(nx&&nx.k===k)return{imp:.86,s:`${nx.n.toLowerCase()} at ${h(nx.at)}`,st:'next'};
   if(!mine.length)return{imp:.16,s:rs.length>1?'all done':`${rs[0].n.toLowerCase()} done`,st:'done'};
   const soon=mine[0],d=soon.at-T;return{imp:.32+.4*Math.max(0,1-d/240),s:`${soon.n.toLowerCase()} at ${h(soon.at)}`,st:'wait'}},
  line(){const late=RT.filter(isLate),dn=RT.filter(isDone).length,nx=RT.filter(r=>!isDone(r)&&!isLate(r)).sort((a,b)=>a.at-b.at)[0];return `<b style="color:var(--go)">${dn} done</b>${nx?`, ${nx.n.toLowerCase()} next`:''}${late.length?`, <b style="color:var(--wine)">${late[0].n.toLowerCase()}</b> late`:''}`}},
 kitchen:{title:'Kitchen',acc:'kitchen',act:'Shopping',words:[['Pantry','teal'],['Shopping','kitchen'],['Recipes','clay'],['Meal plan','gold'],['Leftovers','slate']],
  st(k){const ramp=(a,b)=>Math.max(0,Math.min(1,(T-a)/(b-a)));
   if(k==='Pantry')return{imp:.74,s:'rice goes out today, 2 low',st:'late'};
   if(k==='Shopping'){const open=T>=540&&T<1260;return{imp:open?.5+.3*ramp(900,1080):.3,s:open?'9 to buy, store open till 9':'9 to buy, stores closed',st:'wait'}}
   if(k==='Recipes'){if(T>=1215)return{imp:.18,s:'dal cooked tonight',st:'done'};return{imp:.3+.66*ramp(960,1140),s:T>=960?'6 ready for dinner':'6 ready from what you have',st:T>=1080?'next':'wait'}}
   if(k==='Meal plan'){if(T<600)return{imp:.85,s:'plan today: dinner open',st:'next'};return{imp:.26,s:'dinner is dal',st:'done'}}
   return T>=1215?{imp:.46,s:'dal, for tomorrow’s lunch',st:'wait'}:{imp:.3,s:'2 in the fridge',st:'wait'}},
  line(){return T>=1215?'<b style="color:var(--go)">Dinner done</b>, <b style="color:var(--wine)">rice</b> goes out today':'<b style="color:var(--wine)">Rice</b> goes out today, <b style="color:var(--kitchen)">9</b> to buy'}}};
const sc=st=>st==='late'?'var(--wine)':st==='done'?'var(--go)':'var(--ink2)';

// ---------- springs
const SP={k:.14,d:.74};const spr=(o,key,tg,k=SP.k,d=SP.d)=>{if(RM||o[key]===undefined){o[key]=tg;o['v'+key]=0;return}o['v'+key]=(o['v'+key]||0)*d+(tg-o[key])*k;o[key]+=o['v'+key]};

// ---------- a phone
const ALL=[];
function phone(row,roomKey,variant){const R=ROOMS[roomKey];const col=document.createElement('div');col.className='col';
  col.innerHTML=`<div class="fit"><div class="phone"><div class="scr" data-home><div class="z ttl"><button class="tbtn tt" style="color:var(--${R.acc})">${R.title}</button><small>Friday</small></div><div class="z state"></div><div class="stage" style="position:absolute;inset:0;pointer-events:none"></div>
   <div class="z ft"><span class="act" style="color:var(--${R.acc})">${R.act}</span><span class="tess" aria-hidden="true"></span></div></div>
   <div class="scr sub-p"><button class="back">Back</button><div class="z ttl" style="top:118px"><span class="st"></span></div><p class="z stl" style="top:176px;margin:0;font-size:17px;color:var(--ink2)"></p></div></div></div>`;
  $(row).appendChild(col);const P=col.querySelector('.phone'),home=P.querySelector('[data-home]'),sub=P.querySelector('.sub-p'),stage=P.querySelector('.stage');
  const W=R.words.map(([n,c])=>{const b=document.createElement('button');b.className='kw';b.innerHTML=`<span class="w" style="color:var(--${c})">${n}</span><span class="s"></span>`;stage.appendChild(b);return{n,c,b,wEl:b.firstChild,sEl:b.lastChild}});
  const open=w=>{sub.querySelector('.st').textContent=w.n;sub.querySelector('.st').style.color=`var(--${w.c})`;sub.querySelector('.stl').textContent=w.cur.s;home.style.transform='translateX(-30%)';sub.classList.add('on')};
  sub.querySelector('.back').onclick=()=>{sub.classList.remove('on');home.style.transform=''};
  const S={R,W,stage,home,P,variant,mode:0};let moved=false,dn=null,drag=null;
  W.forEach(w=>{w.b.addEventListener('click',e=>{if(moved){moved=false;return}open(w)});w.b.addEventListener('pointerdown',e=>{if(variant==='B'){drag=w;w.pin=1}})});
  home.addEventListener('pointerdown',e=>{const r=P.getBoundingClientRect(),k=402/r.width;dn={x:(e.clientX-r.left)*k,y:(e.clientY-r.top)*k};moved=false});
  home.addEventListener('pointermove',e=>{if(!dn)return;const r=P.getBoundingClientRect(),k=402/r.width,p={x:(e.clientX-r.left)*k,y:(e.clientY-r.top)*k};if(Math.hypot(p.x-dn.x,p.y-dn.y)>8)moved=true;
    if(drag&&moved){drag.x+=(p.x-(drag.lx??dn.x));drag.y+=(p.y-(drag.ly??dn.y));drag.lx=p.x;drag.ly=p.y}});
  home.addEventListener('pointerup',e=>{const r=P.getBoundingClientRect(),k=402/r.width,p={x:(e.clientX-r.left)*k,y:(e.clientY-r.top)*k};
    if(dn&&variant==='A'){const dy=p.y-dn.y;if(dy>60)S.mode=1;else if(dy<-60)S.mode=0}if(drag){drag.pin=0;drag.lx=drag.ly=undefined;drag=null}dn=null;setTimeout(()=>moved=false,0)});
  P.querySelector('.tt').onclick=()=>{if(variant==='A')S.mode^=1};
  if(variant==='A'){const h=document.createElement('div');h.className='hint';h.style.cssText='left:24px;top:136px';h.textContent='pull down to tidy';stage.appendChild(h);S.hint=h}
  if(variant==='D'){const f=document.createElement('div');f.className='floor';f.style.top='560px';stage.appendChild(f)}
  ALL.push(S)}

// ---------- layouts: each sets per word targets {x,y,r,s,wt,sub}
const seedR=s=>()=>(s=(s*16807)%2147483647)/2147483647;
const TOSS={};function tossed(S){const key=S.R.title;if(!TOSS[key]){const rnd=seedR(key.length*977+13);TOSS[key]=S.W.map(()=>({x:rnd(),y:rnd(),r:(rnd()-.5)*36}))}
  const ord=[...S.W].sort((a,b)=>b.cur.imp-a.cur.imp);const boxes=[];
  ord.forEach((w,i)=>{const t=TOSS[key][S.W.indexOf(w)],s=20+w.cur.imp*40,wd=mw(w.n,s,420+w.cur.imp*400),h=s;let x=30+t.x*(340-wd),y=170+t.y*470,r=t.r*(w.cur.imp>.8?.45:1);
    for(let it=0;it<60;it++){const hit=boxes.find(b=>x<b.x+b.w+10&&x+wd+10>b.x&&y<b.y+b.h+18&&y+h+18>b.y);if(!hit)break;y+=(y>hit.y?1:-1)*14;if(y<160||y>650){y=160+((it*97)%480);x=30+((it*53)%Math.max(1,340-wd))}}
    boxes.push({x,y,w:wd,h});w.tg={x,y,r,s,wt:420+w.cur.imp*400,sub:0}})}
function tidy(S){const ord=[...S.W].sort((a,b)=>b.cur.imp-a.cur.imp);let y=176;ord.forEach((w,i)=>{const s=Math.round(22+w.cur.imp*30);w.tg={x:28,y,r:0,s,wt:420+w.cur.imp*380,sub:1,delay:i*70};y+=s+30})}
function weighted(S){S.W.forEach(w=>{const s=18+w.cur.imp*44;w.tg={...(w.tg||{}),s,wt:400+w.cur.imp*440,r:0,sub:1}})}
function tide(S){const ord=[...S.W].sort((a,b)=>b.cur.imp-a.cur.imp),SZ=[56,40,31,25,21,19];let y=172;ord.forEach((w,i)=>{const s=SZ[i];w.tg={x:28+(i?0:0),y,r:0,s,wt:i?560-i*30:780,sub:i<3?1:0,rank:i};y+=s+(i<3?34:16)})}
function standing(S){const F=560;let x=36;const up=S.W.filter(w=>w.cur.st!=='done'),down=S.W.filter(w=>w.cur.st==='done');
  up.forEach(w=>{const s=Math.round(30+w.cur.imp*34);w.tg={x,y:F,r:-90+(w.cur.st==='late'?-9:0),s,wt:500+w.cur.imp*300,sub:0,stand:1};x+=s*1.04+(w.cur.st==='late'?22:12)});
  let lx=28,ly=F+8;down.forEach(w=>{const s=19,wd=mw(w.n,s,450);if(lx+wd>376){lx=28;ly+=26}w.tg={x:lx,y:ly,r:0,s,wt:450,sub:0,stand:0};lx+=wd+16})}

// ---------- render
function step(t){ALL.forEach(S=>{const{R}=S;S.W.forEach(w=>w.cur=R.st(w.n));
  const L=S.variant==='A'?(S.mode?tidy:tossed):S.variant==='B'?weighted:S.variant==='C'?tide:standing;L(S);
  if(S.hint){S.hint.textContent=S.mode?'pull up to toss':'pull down to tidy'}
  const st=S.P.querySelector('.state');const ln=R.line();if(st.dataset.l!==ln){st.innerHTML=ln;st.dataset.l=ln}
  if(S.variant==='B'){if(!S.init){S.W.forEach((w,i)=>{w.x=60+((i*131)%240);w.y=220+((i*89)%330)});S.init=1}
    S.W.forEach(w=>{spr(w,'s',w.tg.s,.08,.8);spr(w,'wt',w.tg.wt,.08,.8);w.bw=Math.max(mw(w.n,w.s,w.wt),mw(w.cur.s,13,500));w.bh=w.s+26});
    for(let it=0;it<(RM?40:3);it++){S.W.forEach(w=>{if(w.pin)return;const cxx=201-w.bw/2,cyy=420-w.bh/2;w.x+=(cxx-w.x)*.004*(1+w.cur.imp*2);w.y+=(cyy-w.y)*.006*(1+w.cur.imp*2);if(w.cur.st==='done'){w.y+=.25}});
      for(let i=0;i<S.W.length;i++)for(let j=i+1;j<S.W.length;j++){const a=S.W[i],b=S.W[j],ox=Math.min(a.x+a.bw,b.x+b.bw)-Math.max(a.x,b.x)+16,oy=Math.min(a.y+a.bh,b.y+b.bh)-Math.max(a.y,b.y)+12;if(ox>0&&oy>0){if(oy<ox){const d=(a.y<b.y?-1:1)*oy*.25;if(!a.pin)a.y+=d;if(!b.pin)b.y-=d}else{const d=(a.x<b.x?-1:1)*ox*.25;if(!a.pin)a.x+=d;if(!b.pin)b.x-=d}}}
      S.W.forEach(w=>{w.x=Math.max(26,Math.min(376-w.bw,w.x));w.y=Math.max(150,Math.min(720-w.bh,w.y))})}
    S.W.forEach(w=>{w.r=0;w.sub=1})}
  else S.W.forEach((w,i)=>{const g=w.tg;if(g.delay&&!RM){w.wait=(w.wait??0);}const kk=S.variant==='D'?.09:.12;
    const lag=(S.variant==='A'&&S.lastMode!==S.mode)?1:0;if(lag)w.hold=t+(g.delay||0);if(w.hold&&t<w.hold&&!RM)return draw(w);
    spr(w,'x',g.x,kk);spr(w,'y',g.y,kk);spr(w,'r',g.r,S.variant==='D'?.07:kk,S.variant==='D'?.8:SP.d);spr(w,'s',g.s,kk);spr(w,'wt',g.wt,kk);w.sub=g.sub;
    if(S.variant==='D'&&w.cur.st==='late'&&!RM)w.r+=Math.sin(t/260)*1.6;if(S.variant==='D'&&w.cur.st==='next'&&!RM)w.y+=Math.sin(t/700)*.6;draw(w)});
  if(S.variant==='A')S.lastMode=S.mode;
  S.W.forEach(w=>{if(S.variant==='B')draw(w)})})
  function draw(w){const tg=w.tg||{};let x=w.x,y=w.y,r=w.r||0;const stand=tg.stand;
    w.wEl.style.fontSize=w.s.toFixed(1)+'px';w.wEl.style.fontWeight=Math.round(w.wt);
    const showSub=w.sub&&!stand;w.sEl.style.display=showSub?'block':'none';if(showSub){if(w.sEl.textContent!==w.cur.s)w.sEl.textContent=w.cur.s;w.sEl.style.color=sc(w.cur.st)}
    w.b.style.minHeight='44px';w.b.style.minWidth='44px';
    w.b.style.transform=stand?`translate(${x.toFixed(1)}px,${y.toFixed(1)}px) rotate(${r.toFixed(2)}deg)`:`translate(${x.toFixed(1)}px,${y.toFixed(1)}px) rotate(${r.toFixed(2)}deg)`;
    w.b.setAttribute('aria-label',`${w.n}, ${w.cur.s}`)}}
function loop(t){if(play){T+=play;if(T>=1380){T=1180;play=0;$('#play').textContent='Play the day'}$('#clk').value=T;$('#clkL').textContent=fmt(Math.round(T/5)*5)}step(t);requestAnimationFrame(loop)}

// ---------- build
const fit=()=>document.querySelectorAll('.fit').forEach(f=>f.querySelector('.phone').style.transform=`scale(${f.clientWidth/402})`);
[['#rA','A'],['#rB','B'],['#rC','C'],['#rD','D']].forEach(([r,v])=>{phone(r,'routines',v);phone(r,'kitchen',v)});
fit();addEventListener('resize',fit);
$('#clk').oninput=e=>{T=+e.target.value;play=0;$('#play').textContent='Play the day';$('#clkL').textContent=fmt(T)};
$('#play').onclick=()=>{if(play){play=0;$('#play').textContent='Play the day';return}if(T>=1370)T=360;if(T>1180)T=360;play=RM?20:1.2;$('#play').textContent='Pause'};
$('#th').onclick=()=>document.documentElement.dataset.theme='dark';$('#tw').onclick=()=>document.documentElement.dataset.theme='light';
(document.fonts?document.fonts.ready:Promise.resolve()).then(()=>{Object.keys(TOSS).forEach(k=>delete TOSS[k])});
requestAnimationFrame(loop);
})();
