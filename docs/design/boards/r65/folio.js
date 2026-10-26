// ---- Round 247 v3: his Codex-era door pages (2:45-8:35 AM Oct 24) ----
// The band stays fixed (354 x 124). Under it, the Folio: a page of small note cards that turns like a real sheet,
// curling left on a sideways swipe and folding top to bottom on a vertical one. Notes carry areas (tags); an area
// gathers its notes across every door. The turn words name the neighbouring notes. "Titles" opens a searchable list.
const AREAS={'Plumber':['Home','Kitchen'],'Trip packing':['Trip'],'Tacos':['Kitchen','Family'],'Book ideas':['Writing'],'Garage':['Home'],'Work notes':['Work'],'Gift list':['Family'],'Run plan':['Health'],
  'Paint colors':['Home'],'Dreams':['Writing'],'Garden':['Home'],'Tess said':['Health'],'Doctor':['Health'],'Taxes':['Work'],'Week ahead':['Work','Family'],'Voice memo':['Errands'],'Song idea':['Writing'],'Kitchen':['Kitchen','Home'],
  'Mom’s birthday':['Family'],'Wifi code':['Home','Trip'],'Old phone':['Errands'],'Movies':['Family'],'Moving boxes':['Home'],'Summer trip':['Trip','Family'],'Journal':[],'Letter draft':[],'Passwords hint':[]};
const ACOL={Home:'c1',Kitchen:'c9',Trip:'c4',Work:'c10',Family:'c7',Health:'c6',Writing:'c3',Errands:'c2'};
let AREA=null,OPEN=null,fpage=0,prevDoor=-1;
const PER=3;
function areasOf(n){return AREAS[n.t]||[]}
function curItems(){if(AREA){const seen=new Set(),out=[];DOORS.forEach(d=>{if(d[0]==='Private'||d[0]==='Mentions')return;(DATA[d[0]]||[]).forEach(n=>{if(areasOf(n).includes(AREA)&&!seen.has(n.t)){seen.add(n.t);out.push({...n,door:d[0]})}})});return out}
  return DATA[DOORS[DOOR][0]]}
const aw=a=>`<span class="ar" style="color:var(--${ACOL[a]})">${a}</span>`;
function card(dn,n,i){const ar=areasOf(n);const sub=dn==='Voice memos'?line(dn,n):(dn==='Mentions'?n.w:line(dn,n));
  const tess=dn==='From Tess';const ab=tess?n.m.replace(/^From Tess(, about )?/,''):'';
  return `<button class="cd" data-i="${i}"><span class="ct"><span class="cn${tess?' tq0':''}">${tess&&ab?`About ${ab}`:n.t}</span><span class="cw">${dn==='Mentions'?'':n.w}</span></span><span class="cs${tess?' tq':''}">${sub}</span>${ar.length&&dn!=='Private'?`<span class="ca">${ar.map(aw).join('')}</span>`:''}</button>`}
function pageHTML(dn,items,p){return `<div class="fpg">${items.slice(p*PER,p*PER+PER).map((n,j)=>card(dn,n,p*PER+j)).join('')}</div>`}
const FT=300,FH=402,FW=354;
function renderList(P,low,dn,items){fpage=Math.min(fpage,Math.max(0,Math.ceil(items.length/PER)-1));
  low.innerHTML=`<div class="fhd" style="top:${FT-8}px"><span>${AREA?items.length+' notes in '+AREA:'Newest first'}</span><button class="ttlw">Titles</button></div>
  <div class="folio" style="top:${FT+24}px;height:${FH}px"><div class="under"></div><div class="front"></div><div class="shade"></div><div class="flap"></div></div>
  <div class="nb" style="top:${FT+24+FH+8}px"><button class="nbp"></button><button class="nbn"></button></div>`;
  paint(P,dn,items);bindFolio(P,dn,items);
  low.querySelector('.ttlw').onclick=()=>titles(P)}
function paint(P,dn,items){const fo=P.querySelector('.folio');fo.querySelector('.front').innerHTML=pageHTML(dn,items,fpage);fo.querySelector('.under').innerHTML='';
  ['flap','shade'].forEach(c=>fo.querySelector('.'+c).style.cssText='');fo.querySelector('.front').style.clipPath='';
  const pages=Math.ceil(items.length/PER),pv=P.querySelector('.nbp'),nx=P.querySelector('.nbn');
  // the turn words name the neighbouring notes, never "Previous" / "Next", never arrows
  pv.textContent=fpage>0?items[fpage*PER-1].t:'';nx.textContent=fpage<pages-1?items[(fpage+1)*PER].t:'';
  pv.onclick=()=>turn(-1,'x');nx.onclick=()=>turn(1,'x');
  fo.querySelectorAll('.front .cd').forEach(c=>c.onclick=()=>{if(fo.dataset.dragged)return;openNote(items[+c.dataset.i])})}
// The curl. A straight fold line crosses the sheet; the part past it lifts over as a flap showing the sheet's back,
// with a crease shade along the fold and a soft contact shadow on the page beneath. The fold tilts a little at the
// middle of the turn (the corner lifts first) and straightens as it lands.
function geom(t,axis){const S=axis==='x'?FW:FH,f=S*(1-t),tilt=(axis==='x'?22:16)*Math.sin(Math.PI*t);return {S,a:f+tilt,b:f-tilt}}
function frame(P,t,axis){const fo=P.querySelector('.folio'),fr=fo.querySelector('.front'),fl=fo.querySelector('.flap'),sh=fo.querySelector('.shade');const {S,a,b}=geom(t,axis);
  if(axis==='x'){// fold runs top to bottom at x=a (top) .. b (bottom); front keeps the left part
    fr.style.clipPath=`polygon(0 0,${a}px 0,${b}px ${FH}px,0 ${FH}px)`;
    fl.style.clipPath=`polygon(${a}px 0,${2*a-FW}px 0,${2*b-FW}px ${FH}px,${b}px ${FH}px)`;
    const m=(a+b)/2,w=FW-m;fl.style.background=`linear-gradient(90deg,var(--back2) ${m-w}px,var(--back) ${m-w*.35}px,var(--back3) ${m-4}px,var(--crease) ${m}px)`;
    sh.style.background=`linear-gradient(90deg,rgba(0,0,0,${.22*Math.sin(Math.PI*t)}) ${m}px,rgba(0,0,0,0) ${m+46}px)`;sh.style.clipPath=`polygon(${a}px 0,${FW}px 0,${FW}px ${FH}px,${b}px ${FH}px)`}
  else{// fold runs left to right at y; the top part folds down over the page (top to bottom)
    const ya=FH-a,yb=FH-b;// fold moves from the top edge (t=0) to the bottom (t=1)
    fr.style.clipPath=`polygon(0 ${ya}px,${FW}px ${yb}px,${FW}px ${FH}px,0 ${FH}px)`;
    fl.style.clipPath=`polygon(0 ${ya}px,${FW}px ${yb}px,${FW}px ${Math.min(2*yb,FH+60)}px,0 ${Math.min(2*ya,FH+60)}px)`;
    const m=(ya+yb)/2;fl.style.background=`linear-gradient(180deg,var(--crease) ${m}px,var(--back3) ${m+4}px,var(--back) ${m+m*.65}px,var(--back2) ${2*m}px)`;
    sh.style.background=`linear-gradient(0deg,rgba(0,0,0,${.2*Math.sin(Math.PI*t)}) ${FH-m}px,rgba(0,0,0,0) ${FH-m+40}px)`;sh.style.clipPath=`polygon(0 0,${FW}px 0,${FW}px ${yb}px,0 ${ya}px)`}
  fl.style.opacity=t>0&&t<1?1:0;sh.style.opacity=t>0&&t<1?1:0}
let turning=false;
function turn(dir,axis,from){const dn=AREA||DOORS[DOOR][0],items=curItems(),pages=Math.ceil(items.length/PER),np=fpage+dir;if(turning||np<0||np>=pages){PH.forEach(P=>nudge(P,axis));return}
  turning=true;const D=document.documentElement;
  PH.forEach(P=>{const fo=P.querySelector('.folio');const ddn=AREA?'All notes':DOORS[DOOR][0];
    // forward: the current page curls away over the next; back: the previous page curls back onto the current
    if(dir>0){fo.querySelector('.under').innerHTML=pageHTML(ddn,items,np)}else{fo.querySelector('.under').innerHTML=pageHTML(ddn,items,fpage);fo.querySelector('.front').innerHTML=pageHTML(ddn,items,np)}});
  if(RM){fpage=np;PH.forEach(P=>{const fo=P.querySelector('.folio');fo.querySelector('.front').animate([{opacity:0},{opacity:1}],{duration:200});paint(P,AREA?'All notes':DOORS[DOOR][0],items)});turning=false;return}
  const t0=performance.now(),dur=720,s0=from!=null?from:(dir>0?0:1),s1=dir>0?1:0;
  (function step(now){const p=Math.min(1,(now-t0)/dur),e=1-Math.pow(1-p,3),t=s0+(s1-s0)*e;PH.forEach(P=>frame(P,t,axis));
    if(p<1)requestAnimationFrame(step);else{fpage=np;PH.forEach(P=>paint(P,AREA?'All notes':DOORS[DOOR][0],items));turning=false;if(navigator.vibrate)try{navigator.vibrate(6)}catch(e){}}})(t0)}
function nudge(P,axis){if(RM)return;const fr=P.querySelector('.folio .front');fr.animate([{transform:'none'},{transform:axis==='x'?'translateX(-6px)':'translateY(-6px)'},{transform:'none'}],{duration:260,easing:'cubic-bezier(.2,.9,.25,1)'})}
// Drag follows the finger: the axis is chosen after 8 pt; let go past a third and the page turns, else it settles back.
function bindFolio(P,dn,items){const fo=P.querySelector('.folio');let sx,sy,ax=null,dir=0,live=false;
  fo.onpointerdown=e=>{if(turning)return;sx=e.clientX;sy=e.clientY;ax=null;live=false;delete fo.dataset.dragged;fo._pid=e.pointerId};
  fo.onpointermove=e=>{if(sx==null||turning)return;const sc=P.getBoundingClientRect().width/402,dx=(e.clientX-sx)/sc,dy=(e.clientY-sy)/sc;
    if(!ax){if(Math.hypot(dx,dy)<8)return;ax=Math.abs(dx)>Math.abs(dy)?'x':'y';try{fo.setPointerCapture(fo._pid)}catch(_){}dir=ax==='x'?(dx<0?1:-1):(dy>0?1:-1);fo.dataset.dragged=1;
      const pages=Math.ceil(items.length/PER),np=fpage+dir;if(np<0||np>=pages){ax='none';return}
      live=true;PH.forEach(Q=>{const f=Q.querySelector('.folio'),ddn=AREA?'All notes':DOORS[DOOR][0];if(dir>0)f.querySelector('.under').innerHTML=pageHTML(ddn,items,np);else{f.querySelector('.under').innerHTML=pageHTML(ddn,items,fpage);f.querySelector('.front').innerHTML=pageHTML(ddn,items,np)}})}
    if(!live||RM)return;const S=ax==='x'?FW:FH,d=ax==='x'?-dx:dy,t=dir>0?Math.max(0,Math.min(1,d/S)):1-Math.max(0,Math.min(1,-d/S));PH.forEach(Q=>frame(Q,t,ax));fo.dataset.t=t};
  fo.onpointerup=fo.onpointercancel=e=>{const was=live,t=+fo.dataset.t||0;sx=null;if(ax==='none'){PH.forEach(Q=>nudge(Q,'x'));return}if(!was){if(ax==null)delete fo.dataset.dragged;return}
    live=false;const done=dir>0?t>.33:t<.67;
    if(done){turn(dir,ax,t)}else{const t0=performance.now(),s0=t,s1=dir>0?0:1;turning=true;(function step(now){const p=Math.min(1,(now-t0)/320),e2=1-Math.pow(1-p,3);PH.forEach(Q=>frame(Q,s0+(s1-s0)*e2,ax));if(p<1)requestAnimationFrame(step);else{turning=false;PH.forEach(Q=>paint(Q,AREA?'All notes':DOORS[DOOR][0],items))}})(t0)}
    setTimeout(()=>delete fo.dataset.dragged,30)}}
// Titles: the small word above the Folio opens a searchable list of every title on this page.
function titles(P){const items=curItems();PH.forEach(Q=>{const ov=document.createElement('div');ov.className='tov';
  ov.innerHTML=`<div class="tovh"><input class="tin" placeholder="Search titles" aria-label="Search titles"><button class="tcl">Done</button></div><div class="tlist">${items.map((n,i)=>`<button class="tli" data-i="${i}"><span>${n.t}</span><span class="cw">${n.w}</span></button>`).join('')}</div>`;
  Q.appendChild(ov);if(!RM)ov.animate([{opacity:0,transform:'translateY(14px)'},{opacity:1,transform:'none'}],{duration:280,easing:'cubic-bezier(.2,.9,.25,1)'});
  const close=()=>{PH.forEach(R=>{const o=R.querySelector('.tov');o&&o.remove()})};
  ov.querySelector('.tcl').onclick=close;
  ov.querySelector('.tin').oninput=ev=>{const q=ev.target.value.toLowerCase();PH.forEach(R=>{const o=R.querySelector('.tov');if(!o)return;if(R!==Q)o.querySelector('.tin').value=ev.target.value;o.querySelectorAll('.tli').forEach(b=>b.hidden=!items[+b.dataset.i].t.toLowerCase().includes(q))})};
  ov.querySelectorAll('.tli').forEach(b=>b.onclick=()=>{close();const i=+b.dataset.i;const np=Math.floor(i/PER);if(np!==fpage){fpage=np;PH.forEach(R=>paint(R,AREA?'All notes':DOORS[DOOR][0],items))}PH.forEach(R=>{const c=R.querySelector(`.front .cd[data-i="${i}"]`);c&&!RM&&c.animate([{opacity:.3},{opacity:1}],{duration:500})})})});
  P.querySelector('.tov .tin').focus()}
// A note opens as its own page, without the band: title, when it was updated, the words, then Areas.
function openNote(n){OPEN=n;PH.forEach(P=>{const w=P.querySelector('.wall');w.style.transition=RM?'none':'opacity .3s';w.style.opacity=0;w.style.pointerEvents='none';noteHead(P);noteBody(P)})}
function noteHead(P){const ttl=P.querySelector('.ttl'),sub=P.querySelector('.sub'),back=P.querySelector('.back');back.hidden=false;back.textContent=AREA||DOORS[DOOR][0];
  ttl.textContent=OPEN.t;ttl.style.fontSize='34px';ttl.style.color='var(--t)';sub.style.top='98px';sub.textContent='Updated '+OPEN.w+'.';P.querySelector('.act.main').textContent='Edit'}
function noteBody(P){const low=P.querySelector('.low');const n=OPEN,dn=n.door||(AREA?'All notes':DOORS[DOOR][0]),ar=areasOf(n);
  const body=dn==='Voice memos'?`<p class="nb1"><span class="dur s" style="font-size:20px">${n.m.split(':')[0]}<small>m</small> ${n.m.split(':')[1]}<small>s</small></span></p><p class="nb1">${n.b}</p>`:`<p class="nb1${dn==='From Tess'?' tessw2':''}">${n.b}</p>${dn==='Voice memos'||dn==='Mentions'?'':`<p class="nb2">${n.m}</p>`}`;
  low.innerHTML=`<div class="note" style="top:146px">${body}${ar.length?`<div class="arw"><button class="arb">Areas</button>${ar.map(aw).join('')}</div>`:''}</div>`;
  const b=low.querySelector('.arb');if(b)b.onclick=()=>pane(P,b,ar)}
// The areas pane: glass, sized to what it holds (his ask; the one place glass is allowed). No border, no bright rim.
function pane(P,anchor,ar){PH.forEach(Q=>{const old=Q.querySelector('.gp');if(old){old.remove();return}
  const a=Q.querySelector('.arb');if(!a)return;const r=a.getBoundingClientRect(),pr=Q.getBoundingClientRect(),sc=pr.width/402;
  const gp=document.createElement('div');gp.className='gp';const all=Object.keys(ACOL);
  gp.innerHTML=all.map(x=>`<button class="gpi${ar.includes(x)?' on':''}" data-a="${x}"><span style="color:var(--${ACOL[x]})">${x}</span><span class="gpn">${countArea(x)}</span></button>`).join('');
  gp.style.left='24px';gp.style.top=((r.bottom-pr.top)/sc+4)+'px';Q.appendChild(gp);
  if(!RM)gp.animate([{opacity:0,transform:'translateY(-8px) scale(.97)'},{opacity:1,transform:'none'}],{duration:240,easing:'cubic-bezier(.2,.9,.25,1)'});
  gp.querySelectorAll('.gpi').forEach(b=>b.onclick=()=>{PH.forEach(R=>{const g=R.querySelector('.gp');g&&g.remove()});goArea(b.dataset.a)})})}
function countArea(a){const s=new Set();DOORS.forEach(d=>{if(d[0]==='Private'||d[0]==='Mentions')return;DATA[d[0]].forEach(n=>{if(areasOf(n).includes(a))s.add(n.t)})});return s.size}
function goArea(a){if(!AREA)prevDoor=DOOR;AREA=a;OPEN=null;fpage=0;if(DOOR<0)DOOR=0;H=BH;TOP=140;PH.forEach(P=>{const w=P.querySelector('.wall');w.style.opacity=1;w.style.pointerEvents='';head(P);lower(P)});compute();all('wall',true)}
function head(P){const ttl=P.querySelector('.ttl'),sub=P.querySelector('.sub'),act=P.querySelector('.act.main'),back=P.querySelector('.back');back.textContent='Notes';
  if(AREA){const items=curItems(),doors=new Set(items.map(n=>n.door)).size;ttl.textContent=AREA;ttl.style.color=`var(--${ACOL[AREA]})`;ttl.style.fontSize='34px';sub.style.top='98px';sub.textContent=`${items.length} notes across ${doors} doors.`;act.textContent='New note';back.hidden=false;back.textContent=prevDoor>=0?DOORS[prevDoor][0]:'Notes';return}
  if(DOOR<0){ttl.textContent='Notes';ttl.style.color='var(--room)';ttl.style.fontSize='40px';sub.style.top='102px';sub.textContent='Three new today, one from Tess.';act.textContent='New note';back.hidden=true}
  else{const d=DOORS[DOOR];ttl.textContent=d[0];ttl.style.color=`var(--${d[2]==='t'||d[2]==='t2'?'t':d[2]})`;ttl.style.fontSize='34px';sub.style.top='98px';sub.textContent=SUBL[d[0]];act.textContent=ACT[d[0]];back.hidden=false}}
function lower(P){const low=P.querySelector('.low');low.innerHTML='';
  if(DOOR<0&&!AREA){low.innerHTML=`<div class="shelf" style="top:432px"><div class="dial"><div class="rail"></div><div class="peek"></div></div></div><div class="rc2" style="top:612px">You last wrote in <b style="color:var(--t);font-weight:600">Plumber</b>, an hour ago.</div>`;
    const rail=low.querySelector('.rail');DOORS.forEach((d,i)=>{const e=document.createElement('div');e.className='dw';e.dataset.i=i;e.innerHTML=`<span class="nm" style="color:var(--${d[2]})">${d[0]}</span><span class="n">${d[1]}</span>`;rail.appendChild(e)});
    bindDial(P,low.querySelector('.dial'),DD,i=>go(i));return}
  const dn=AREA?'All notes':DOORS[DOOR][0],items=curItems();
  if(!AREA&&dn==='Private'&&!unlocked){low.innerHTML=`<div class="lock" style="top:340px"><p style="margin:0;font-size:22px;font-weight:700;color:var(--slate2)">Locked</p><p style="margin:0;font-size:16px;color:var(--t2)">Private notes open with Face ID and lock again when you leave.</p><button class="act unl" style="color:var(--slate2);margin-top:8px">Unlock</button></div>`;low.querySelector('.lock .unl').onclick=()=>{unlocked=true;go(DOOR,true)};return}
  renderList(P,low,dn,items)}
function back(){if(OPEN){OPEN=null;PH.forEach(P=>{const w=P.querySelector('.wall');w.style.opacity=1;w.style.pointerEvents='';head(P);lower(P)});return}
  if(AREA){AREA=null;fpage=0;const d=prevDoor;prevDoor=-1;go(d,true);return}go(-1)}
PH.forEach(P=>P.querySelector('.back').onclick=back);
function wordTap(t){if(DOOR<0&&!AREA)return;const items=curItems(),i=items.findIndex(n=>n.t===t);if(i<0)return;const np=Math.floor(i/PER);
  const flash=()=>PH.forEach(R=>{const c=R.querySelector(`.front .cd[data-i="${i}"]`);c&&!RM&&c.animate([{opacity:.3},{opacity:1}],{duration:500})});
  if(np===fpage){flash();return}turn(np>fpage?1:-1,'x');setTimeout(flash,760)}
const _go=go;go=function(d,keep){if(d!==DOOR){fpage=0}AREA=null;OPEN=null;PH.forEach(P=>{const w=P.querySelector('.wall');w.style.opacity=1;w.style.pointerEvents=''});_go(d,keep)};
document.querySelectorAll('.go').forEach(b=>b.onclick=()=>go(+b.dataset.d));
