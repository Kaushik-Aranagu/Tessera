// Door data: [title, when, first lines, meta]. Weights come from order (newest first).
const N=(t,w,b,m)=>({t,w,b,m});
const DATA={
'All notes':[N('Plumber','an hour ago','Mike, 555 0142. Comes Tuesday between 8 and 10. Ask about the kitchen tap too.','Mentions <b>Kitchen</b>'),N('Trip packing','this morning','Charger, passport, the grey jacket. Snacks for the drive. Check the weather the night before.','14 items, 9 done'),N('Tacos','yesterday','Double the lime. Char the tortillas on the flame. Pickled onions the day before.','Mentions <b>Tacos</b> recipe'),N('Book ideas','yesterday','A town where every door opens somewhere else. Start with the baker.','3 pages'),N('Garage','Tuesday','Shelf for paint, hooks for bikes, throw out the old tiles.','6 items'),N('Work notes','Monday','Move the review to Thursday. Send the draft to the team first.','2 pages'),N('Gift list','Sunday','Mom: a scarf in green. Sam: the record he mentioned.','5 people'),N('Run plan','October 18','Easy 5k Monday, intervals Wednesday, long run Saturday.','Mentions <b>Run</b>')],
'Ideas':[N('Book ideas','yesterday','A town where every door opens somewhere else. Start with the baker.','3 pages'),N('Paint colors','Thursday','Warm white for the hall, deep green for the study door.','4 colours'),N('Gift list','Sunday','Mom: a scarf in green. Sam: the record he mentioned.','5 people'),N('Dreams','October 20','Flying over a lake of glass, then the train again.','1 page'),N('Garden','October 12','Tomatoes on the south wall. Basil in pots.','2 pages')],
'From Tess':[N('Tess said','this morning','You slept 6 hours. Your long run moved to Sunday so Saturday can be easy.','From Tess, about <b>Run plan</b>'),N('Doctor','Tuesday','Your checkup is November 3 at 9. I added the questions you asked me to keep.','From Tess, about <b>Calendar</b>'),N('Taxes','October 19','The forms you need are in Money. Two receipts are still missing.','From Tess, about <b>Money</b>'),N('Week ahead','October 18','A full week. Wednesday is the heavy day; I kept the evening clear.','From Tess')],
'Voice memos':[N('Voice memo','Tuesday','“Remember to call the bank about the card, and pick up the dry cleaning.”','2:14'),N('Run plan','Monday','“Long run felt good, knee fine, try 10 more minutes next week.”','0:48'),N('Dreams','October 20','“Lake of glass, then the train, the same station as last time.”','1:05'),N('Song idea','October 16','“Hum, then the chorus goes up on the third line.”','0:32'),N('Kitchen','October 14','“Tap drips at night, the left one.”','0:19')],
'Pinned':[N('Trip packing','this morning','Charger, passport, the grey jacket. Snacks for the drive.','14 items, 9 done'),N('Mom’s birthday','Saturday','Dinner at 7. Cake from the corner bakery. Card is in the drawer.','In 3 weeks')],
'Mentions':[N('Bench press','4 notes','Run plan, Work notes, Tess said, Gym bag','Exercise'),N('Tacos','3 notes','Tacos, Gift list, Week ahead','Recipe'),N('Sam','5 notes','Gift list, Trip packing, Book ideas, Dreams, Plumber','Person'),N('Kitchen','2 notes','Plumber, Kitchen','Place'),N('Run','6 notes','Run plan, Tess said, Voice memo, Sleep log, Shoes, Stretch','Routine')],
'Private':[N('Journal','last night','Long day. Better after the walk.','2 pages'),N('Letter draft','October 21','I wanted to say this in person, but','1 page'),N('Passwords hint','October 3','The blue notebook, second shelf.','1 line')],
'Archive':[N('Old phone','October 2','Trade in by the 15th. Wipe it first.','Archived October 2'),N('Wifi code','September 28','Network at the cabin, the long one on the router.','Archived September 28'),N('Movies','September 20','The one with the lighthouse. The French one Sam liked.','Archived September 20'),N('Moving boxes','September 9','12 boxes, kitchen first, label the cables.','Archived September 9'),N('Summer trip','August 30','Lake house, the long drive, the good diner.','Archived August 30')]};
const ACT={'All notes':'New note','Ideas':'New idea','From Tess':'Ask Tess','Voice memos':'Record','Pinned':'New note','Mentions':'New note','Private':'New private note','Archive':'Restore'};
const SUBL={'All notes':'38 notes, the newest an hour ago.','Ideas':'9 ideas, the newest yesterday.','From Tess':'4 from Tess, one this morning.','Voice memos':'5 memos, 4 minutes in all.','Pinned':'2 pinned.','Mentions':'5 things your notes mention.','Private':'3 private notes.','Archive':'61 archived, the oldest from June.'};
// Door words for the wall: its notes, newest weightiest, repeated small when the door is small.
function doorWords(d){const L0=DATA[DOORS[d][0]].map((n,i,a)=>[n.t,Math.max(2,9-i*1.6),i]);let out=[...L0];let r=0;while(L0.length>4&&out.length<10){out.push([L0[r%L0.length][0],2,r]);r++}return out}
let PL=null,seed=7;
function compute(){const src=DOOR<0?POOL:doorWords(DOOR);WL=src;
  if(DOOR>=0&&src.length<=4){// a small door: its few notes only, no repeats, and the band shrinks to what they fill
    let y=0;const rows=[];src.forEach(x=>{const a=unit(x[0],F.w),h=Math.min(64,W*C/a);rows.push([{x,a,h}])});
    while(rows.reduce((q,r)=>q+r[0].h,0)+G*(rows.length-1)>150&&rows.length>1){rows.sort((p,q)=>p[0].h-q[0].h);// join the two thinnest rows into one justified row
      const r1=rows.shift(),r2=rows.shift(),bs=r1.concat(r2),h=(W-G*(bs.length-1))*C/bs.reduce((q,b)=>q+b.a,0);rows.push(bs.map(b=>({...b,h})))}
    rows.sort((p,q)=>src.indexOf(p[0].x)-src.indexOf(q[0].x));let ci=0;
    L=[];rows.forEach(r=>{let x=0;r.forEach(b=>{const fs=b.h/C,w=b.a*fs;L.push({t:b.x[0],key:b.x[0],x,y,w,h:b.h,fs,col:(ci++*5+1)%12});x+=w+G});y+=r[0].h+G});H=Math.round(y-G);PL=RM?null:pile(L,seed++);return}
  const vis=DOOR<0?src.slice(start).concat(src.slice(0,start)):src;L=layout(vis);PL=RM?null:pile(L,seed++)}
function place(P,mode,stag){const band=P.querySelector('.wall');band.style.top=TOP+'px';band.style.height=H+'px';
  const old={};band.querySelectorAll('.w').forEach(e=>{if(!e.dataset.gone)old[e.dataset.k]=e});const keep=new Set();
  L.forEach((o,i)=>{const k=o.key;let e=old[k];if(!e){e=document.createElement('div');e.className='w';e.dataset.k=k;e.style.opacity=0;band.appendChild(e);e.onclick=()=>wordTap(o.t)}
    keep.add(k);const sig=o.t+o.w.toFixed(1)+o.h.toFixed(1)+o.col+F.f+F.sh;if(e.dataset.sig!==sig){e.innerHTML=svg(o);e.dataset.sig=sig}e.dataset.t=o.t;e.style.width=o.w+'px';e.style.height=o.h+'px';
    let tr=`translate(${o.x}px,${o.y}px)`;if(mode==='pile'&&PL){const p=PL[i];tr=`translate(${p.cx-o.w/2}px,${p.cy-o.h/2}px) rotate(${p.t}rad) scale(${p.s})`}
    const d=stag?i*22:0;
    if(RM){e.style.transition='opacity .3s';e.style.transform=tr;e.style.opacity=1}else{e.style.transition=`transform ${mode==='pile'?'.5s cubic-bezier(.5,0,.8,.4)':'.65s cubic-bezier(.2,.9,.25,1.06)'} ${d}ms,opacity .4s`;e.style.transform=tr;requestAnimationFrame(()=>e.style.opacity=1)}});
  Object.keys(old).forEach(k=>{if(!keep.has(k)){const e=old[k];e.dataset.gone=1;(RM?Promise.resolve():fxDust(e,false,600)).then(()=>{e.style.opacity=0;setTimeout(()=>e.remove(),300)})}})}
// Dials: 3 places, 64 pt slots, loop, drag to turn, spring settle.
const SL=48;let dragging=false;
function makeDial(key,count,cls){return{key,count,pos:0,cls}}
let DD=makeDial('doors',DOORS.length,'dw'),ND=makeDial('notes',0,'nw');
function bindDial(P,el,D,onTapFocus){let y0=0,p0=0,moved=false;
  el.onpointerdown=e=>{dragging=true;moved=false;y0=e.clientY;p0=D.pos;el.setPointerCapture(e.pointerId);PH.forEach(Q=>Q.querySelectorAll('.'+D.cls).forEach(w=>w.style.transition='none'))};
  el.onpointermove=e=>{if(!dragging)return;const sc=P.getBoundingClientRect().height/874,dy=(e.clientY-y0)/sc;if(Math.abs(dy)>4)moved=true;D.pos=p0-dy/SL;spinD(D)};
  el.onpointerup=e=>{dragging=false;if(!moved){const r=e.target.closest('.'+D.cls);if(r){const i=+r.dataset.i,n=D.count,d=((i-D.pos)%n+n*1.5)%n-n/2;if(Math.abs(d)<.5)onTapFocus(i);else D.pos=Math.round(D.pos+d)}}else D.pos=Math.round(D.pos);settleD(D)}}
const mod=(a,n)=>((a%n)+n)%n;
function spinD(D){const n=D.count;if(!n)return;PH.forEach(P=>{P.querySelectorAll('.'+D.cls).forEach(e=>{const i=+e.dataset.i;let d=((i-D.pos)%n+n*1.5)%n-n/2;if(n<=3)d=i-Math.max(0,Math.min(n-1,D.pos));const ad=Math.abs(d),sc=1+.32*Math.max(0,1-ad),blur=RM?0:Math.min(1.8,ad*1.8);
    e.style.transform=`translateY(${d*SL}px) scale(${sc})`;e.style.filter=blur>.02?`blur(${blur.toFixed(2)}px)`:'none';e.style.visibility=ad>1.5?'hidden':'visible';e.classList.toggle('focus',ad<.5)})});
  const f=D.count<=3?Math.max(0,Math.min(D.count-1,Math.round(D.pos))):mod(Math.round(D.pos),n);if(D.focus!==f){D.focus=f;(D.key==='doors'?peekDoor:peekNote)(f)}}
function settleD(D){if(D.count<=3)D.pos=Math.max(0,Math.min(D.count-1,Math.round(D.pos)));PH.forEach(P=>P.querySelectorAll('.'+D.cls).forEach(w=>w.style.transition=RM?'none':'transform .45s cubic-bezier(.2,.9,.25,1.08),filter .45s'));spinD(D)}
const PEEK={'All notes':['Plumber','Trip packing','Tacos'],'Ideas':['Book ideas','Paint colors','Gift list'],'From Tess':['Tess said','Doctor','Taxes'],'Voice memos':['Voice memo','Run plan','Dreams'],'Pinned':['Trip packing','Mom’s birthday'],'Mentions':['Bench press','Tacos','Sam'],'Private':['Private note','Private note','Private note'],'Archive':['Old phone','Wifi code','Movies']};
const WHEN={'All notes':'an hour ago','Ideas':'yesterday','From Tess':'this morning','Voice memos':'Tuesday','Pinned':'this morning','Mentions':'yesterday','Private':'last week','Archive':'October 2'};
function peekDoor(f){PH.forEach(P=>{const pk=P.querySelector('.peek');if(!pk)return;const d=DOORS[f];pk.innerHTML=`<p class="pw">Newest ${WHEN[d[0]]}</p>${PEEK[d[0]].map((t,j)=>`<p class="pt${j?'':' p0'}">${t}</p>`).join('')}`;if(!RM)pk.animate([{transform:'translateY(6px)',opacity:0},{transform:'none',opacity:1}],{duration:260,easing:'cubic-bezier(.2,.9,.25,1)'})})}
function peekNote(f){if(DOOR<0)return;const dn=DOORS[DOOR][0],n=DATA[dn][f];PH.forEach(P=>{const pv=P.querySelector('.pv');if(!pv)return;
  let body=dn==='From Tess'?`<p class="body tessw">${n.b}</p>`:`<p class="body">${n.b}</p>`;
  if(dn==='Voice memos'){const [m,s]=n.m.split(':');body=`<span class="dur">${m}<small>m</small> ${s}<small>s</small></span>`+body}
  pv.innerHTML=body+(dn==='Voice memos'?'':`<p class="meta">${n.m}</p>`);if(!RM)pv.animate([{transform:'translateY(6px)',opacity:0},{transform:'none',opacity:1}],{duration:260,easing:'cubic-bezier(.2,.9,.25,1)'})})}
function wordTap(t){if(DOOR<0)return;const i=DATA[DOORS[DOOR][0]].findIndex(n=>n.t===t);if(i>=0){ND.pos=i;settleD(ND)}}
function build(P){P.innerHTML=`<button class="back" hidden>Notes</button><div class="z ttl" style="top:54px;font-size:40px;font-weight:700;letter-spacing:-.03em;line-height:44px;color:var(--room)">Notes</div><div class="z sub" style="top:102px;font-size:16px;color:var(--t2)">Three new today, one from Tess.</div><div class="wall"></div><div class="low"></div><div class="z" style="left:28px;bottom:30px;height:44px;display:flex;align-items:center"><button class="act main">New note</button></div><span class="tess"></span>`;
  P.querySelector('.back').onclick=()=>go(-1)}
function lower(P){const low=P.querySelector('.low');low.innerHTML='';
  if(DOOR<0){low.innerHTML=`<div class="shelf" style="top:432px"><div class="dial"><div class="rail"></div><div class="peek"></div></div></div><div class="rc2" style="top:612px">You last wrote in <b style="color:var(--t);font-weight:600">Plumber</b>, an hour ago.</div>`;
    const rail=low.querySelector('.rail');DOORS.forEach((d,i)=>{const e=document.createElement('div');e.className='dw';e.dataset.i=i;e.innerHTML=`<span class="nm" style="color:var(--${d[2]})">${d[0]}</span><span class="n">${d[1]}</span>`;rail.appendChild(e)});
    bindDial(P,low.querySelector('.dial'),DD,i=>go(i))}
  else{const dn=DOORS[DOOR][0],items=DATA[dn];
    if(dn==='Private'&&!unlocked){low.innerHTML=`<div class="lock" style="top:340px"><p style="margin:0;font-size:22px;font-weight:700;color:var(--slate2)">Locked</p><p style="margin:0;font-size:16px;color:var(--t2)">Private notes open with Face ID and lock again when you leave.</p><button class="act unl" style="color:var(--slate2);margin-top:8px">Unlock</button></div>`;low.querySelector('.lock .unl').onclick=()=>{unlocked=true;go(DOOR,true)};return}
    low.innerHTML=`<div class="nd" style="top:324px"></div><div class="pv" style="top:488px"></div>`;const nd=low.querySelector('.nd');
    items.forEach((n,i)=>{const e=document.createElement('div');e.className='nw';e.dataset.i=i;e.innerHTML=`<span class="nm">${n.t}</span><span class="when">${n.w}</span>`;nd.appendChild(e)});
    bindDial(P,nd,ND,()=>{const e=P.querySelector('.nw.focus');if(e)e.animate([{opacity:1},{opacity:.45},{opacity:1}],{duration:280})})}}
let unlocked=false;
function head(P){const ttl=P.querySelector('.ttl'),sub=P.querySelector('.sub'),act=P.querySelector('.act.main'),back=P.querySelector('.back');
  if(DOOR<0){ttl.textContent='Notes';ttl.style.color='var(--room)';ttl.style.fontSize='40px';sub.style.top='102px';sub.textContent='Three new today, one from Tess.';act.textContent='New note';back.hidden=true}
  else{const d=DOORS[DOOR];ttl.textContent=d[0];ttl.style.color=`var(--${d[2]==='t'||d[2]==='t2'?'t':d[2]})`;ttl.style.fontSize='34px';sub.style.top='98px';sub.textContent=SUBL[d[0]];act.textContent=ACT[d[0]];back.hidden=false}}
const PH=[document.getElementById('p1'),document.getElementById('p2')];PH.forEach(build);
function all(mode,stag){PH.forEach(P=>place(P,mode,stag));state=mode}
let busy=false;
function go(d,keepLock){if(busy)return;if(!keepLock&&d!==DOOR)unlocked=false;DOOR=d;document.querySelectorAll('.go').forEach(b=>b.setAttribute('aria-pressed',+b.dataset.d===d));
  if(d<0){H=220;TOP=180}else{H=150;TOP=150}
  const hideWall=d>=0&&DOORS[d][0]==='Private'&&!unlocked;
  PH.forEach(P=>{head(P);lower(P)});
  if(d>=0){ND=makeDial('notes',DATA[DOORS[d][0]].length,'nw');ND.focus=-1}else{DD.focus=-1}
  if(hideWall){WL=[];L=[];all('wall')}else{compute();all('wall',true)}
  if(d>=0)settleD(ND);else settleD(DD)}
function words(P){return [...P.querySelectorAll('.wall .w')].filter(e=>e.style.opacity!=='0'&&!e.dataset.gone)}
function fxFlip(e){if(RM)return;const s=e.querySelector('svg');s.animate([{transform:'perspective(400px) rotateX(0)'},{transform:'perspective(400px) rotateX(-180deg)',offset:.5},{transform:'perspective(400px) rotateX(-360deg)'}],{duration:800,easing:'cubic-bezier(.4,0,.2,1)'})}
const AZ='ABCDEFGHIJKLMNOPRSTUVWY';
function fxJumble(e){if(RM)return;const t=e.querySelector('text'),word=e.dataset.t.toUpperCase();let n=0;const steps=14,iv=setInterval(()=>{n++;const fixed=Math.floor(word.length*n/steps);t.textContent=word.split('').map((ch,i)=>i<fixed||ch===' '||ch==='’'?ch:AZ[Math.floor(Math.random()*AZ.length)]).join('');if(n>=steps){clearInterval(iv);t.textContent=word}},55)}
function fxDust(e,back=true,dur=1300){if(RM)return Promise.resolve();const f=e.querySelector('filter'),dm=f&&f.querySelector('feDisplacementMap'),t=e.querySelector('text');if(!t)return Promise.resolve();const H0=e.offsetHeight;t.setAttribute('filter',`url(#${f.id})`);
  return new Promise(res=>{const t0=performance.now();(function step(now){const p=Math.min(1,(now-t0)/dur),q=back?(p<.5?p*2:2-p*2):p,ease=q*q;dm.setAttribute('scale',(ease*H0*1.6).toFixed(1));t.style.opacity=(1-ease*.95).toFixed(3);if(p<1)requestAnimationFrame(step);else{if(back){t.removeAttribute('filter');t.style.opacity=1}res()}})(t0)})}
function fxWave(){PH.forEach(P=>words(P).forEach(e=>{const m=e.style.transform.match(/translate\(([\d.]+)px,\s*([\d.]+)px/);const d=m?(+m[1]+ +m[2]*1.4)*1.6:0;setTimeout(()=>fxFlip(e),d)}))}
function fxMelt(){if(RM||DOOR>=0){fxWave();return}busy=true;Promise.all(PH.flatMap(P=>words(P).map((e,i)=>new Promise(r=>setTimeout(()=>fxDust(e,false,700).then(r),i*18))))).then(()=>{PH.forEach(P=>P.querySelector('.wall').innerHTML='');start=(start+5)%POOL.length;compute();all('wall',true);busy=false})}
function cycle(){if(RM||!L.length){all('wall');return}busy=true;all('pile',true);setTimeout(()=>{all('wall',true);busy=false},1500)}
function pickDo(fn){const ws=words(PH[0]);if(!ws.length)return;const i=Math.floor(Math.random()*ws.length),k=ws[i].dataset.k;PH.forEach(P=>{const e=P.querySelector(`.wall .w[data-k="${CSS.escape(k)}"]`);if(e&&!e.dataset.gone)fn(e)})}
function ready(){return document.fonts?Promise.all([F.w,800,700].map(w=>document.fonts.load(`${w} 40px '${F.f}'`,'AB')).concat([document.fonts.load(`500 20px Outfit`,'12'),document.fonts.load(`400 18px Newsreader`,'Ab')])).then(()=>document.fonts.ready):Promise.resolve()}
function fit(){document.querySelectorAll('.fit').forEach(f=>{f.firstElementChild.style.transform=`scale(${f.clientWidth/402})`})}addEventListener('resize',fit);fit();
const tools=document.querySelector('.go').parentNode;DOORS.forEach((d,i)=>{const b=document.createElement('button');b.className='tr go';b.dataset.d=i;b.textContent=d[0];tools.appendChild(b)});
document.querySelectorAll('.go').forEach(b=>b.onclick=()=>go(+b.dataset.d));
ready().then(()=>{capRatio();go(-1);0});
let tick=0;
setInterval(()=>{if(dragging||RM||busy)return;if(DOOR<0){DD.pos=Math.round(DD.pos)+1;settleD(DD)}},6000);
setInterval(()=>{if(RM||busy||state!=='wall')return;tick++;
  if(tick%24===0){[fxWave,fxMelt][(tick/24)%2]();return}
  if(tick%8===0&&DOOR<0){start=(start+1)%POOL.length;compute();all('wall');return}
  [()=>pickDo(fxFlip),()=>pickDo(fxJumble),()=>pickDo(e=>fxDust(e))][tick%3]()},5000);
})();
</script>
