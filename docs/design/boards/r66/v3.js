/* ================= v3: one landing for every room (283, his 12:22 and 12:26 PM notes, Oct 25) =================
   Five fixed sections on every room landing, the same place on every room: top (title, nav word, two summary lines),
   keystone (354 x 182 at 196), up next (one switcher element at 422, swipes up and down through the room's next things,
   right is Done, left is Not now), doors (the depth-blur dial on the left at 540, the room's own summary on the right),
   action (bottom left). Every section opens the Bridge way: it rises 10 pt out of a 3 pt blur at 95 percent size, 80 ms
   apart. From Bridge, the mosaic flips tile by tile into the room's keystone; each room has its own flip order. */
{const st=document.createElement('style');st.textContent=`
.lnav{position:absolute;right:16px;top:56px;font:500 15px var(--sans);color:var(--ink2);background:none;border:0;min-height:44px;padding:0 8px;cursor:pointer;z-index:6}
.lsay{position:absolute;left:24px;right:24px;top:106px;height:64px;font:300 24px/32px var(--sans);letter-spacing:-.01em;overflow:hidden;z-index:6}
.lsay b{font-weight:600}
.lcap{position:absolute;left:24px;right:24px;top:388px;height:22px;font-size:15px;color:var(--ink2);white-space:nowrap;overflow:hidden;z-index:6}
.lsw{position:absolute;left:24px;right:24px;top:422px;height:96px;touch-action:none;cursor:pointer;overflow:hidden;z-index:6}
.lsw .su{position:absolute;left:0;right:0;top:32px;height:32px;line-height:32px;font-size:20px;white-space:nowrap;overflow:hidden;transform-origin:left center;
 transition:transform .38s cubic-bezier(.3,.9,.3,1),filter .3s,opacity .3s,color .3s}
.lsw .su b{font-weight:600}
.lsum{position:absolute;left:212px;right:24px;top:556px;height:120px;z-index:6}
.lsum .lb{font-size:13px;color:var(--ink2);height:20px;white-space:nowrap;overflow:hidden}
.lsum .ln{font-size:16px;line-height:24px;height:24px;white-space:nowrap;overflow:hidden}
.lsum .ln:first-of-type{font-weight:700}
.lsum.rise{animation:lrise .3s cubic-bezier(.3,.9,.3,1)}
@keyframes lrise{from{transform:translateY(6px);clip-path:inset(0 0 100% 0)}to{transform:none;clip-path:inset(0 0 -10% 0)}}
.lkey{position:absolute;inset:0;pointer-events:none}.lkey>*{pointer-events:auto}
.lclip{position:absolute;top:196px;height:182px;overflow:hidden}
.lclip iframe{position:absolute;top:-196px;width:402px;height:874px;border:0;background:transparent}
.lsec{transform-origin:left top;animation:lopen .5s cubic-bezier(.2,.8,.2,1) both;animation-delay:calc(var(--i)*80ms + var(--d0,0ms))}
@keyframes lopen{from{transform:translateY(10px) scale(.95);filter:blur(3px);clip-path:inset(0 0 100% 0)}to{transform:none;filter:blur(0);clip-path:inset(-40px -40px -40px -40px)}}
.lsec.rm{animation:lfade .15s linear both}
@keyframes lfade{from{opacity:0}to{opacity:1}}
.screen.leave>*:not(.lkey):not(#mosaic){transition:filter .2s,opacity .2s;filter:blur(6px);opacity:0}
.bfact{position:absolute;left:190px;right:24px;top:688px;height:24px;font-size:15px;font-weight:500;color:var(--ink2);white-space:nowrap;overflow:hidden}
.bfact.rise{animation:lrise .3s cubic-bezier(.3,.9,.3,1)}
.screen.onsky .lsw .su,.screen.onsky .lsum .ln{color:inherit}
`;document.head.appendChild(st)}

// opening: sections arrive in order, 80 ms apart
function opening(secs,d0){secs.forEach((e,i)=>{if(!e)return;e.style.setProperty('--i',i);if(d0)e.style.setProperty('--d0',d0+'ms');e.classList.add('lsec');if(RM)e.classList.add('rm');
 e.addEventListener('animationend',function f(ev){if(ev.target!==e)return;e.classList.remove('lsec','rm');e.style.removeProperty('--i');e.removeEventListener('animationend',f)})})}

// the switcher: one element, three places; up and down scroll the room's next things, right is Done, left is Not now
function switcher(host,el,items){let f=0;
 const draw=()=>{host.innerHTML='';if(!items.length){host.appendChild(h('div','su','<span style="color:var(--ink2)">Nothing waiting.</span>'));return}
  [-1,0,1].forEach(o=>{if(items.length<2&&o)return;if(items.length===2&&o===-1)return;const it=items[(f+o+items.length)%items.length];const s=h('div','su',it.h);
   s.style.transform=o?'translateY('+(o*30)+'px) scale(.72)':'none';s.style.filter=o&&!RM?'blur(1.4px)':'none';s.style.opacity=o?.5:1;if(o)s.style.color='var(--ink2)';host.appendChild(s)})};
 let x0=null,y0,dx,dy,ax;
 host.onpointerdown=e=>{x0=e.clientX;y0=e.clientY;dx=dy=0;ax=null;host.setPointerCapture(e.pointerId);e.stopPropagation()};
 host.onpointermove=e=>{if(x0==null)return;dx=(e.clientX-x0)/K;dy=(e.clientY-y0)/K;ax=lockAxis(dx,dy,ax);const s=host.children[items.length>1?1:0];if(!s)return;
  if(ax==='x'){s.style.transition='none';s.style.transform='translateX('+Math.max(-110,Math.min(110,dx))+'px)'}
  else if(ax==='y'){host.querySelectorAll('.su').forEach(q=>{q.style.transition='none';q.style.marginTop=Math.max(-30,Math.min(30,dy*.6))+'px'})}};
 host.onpointerup=e=>{if(x0==null)return;x0=null;const it=items[f];
  if(ax==='x'&&Math.abs(dx)>90&&it){const i=f;items.splice(i,1);if(f>=items.length)f=0;draw();
   receipt(el,it.name+(dx>0?', done.':', not now.'),()=>{items.splice(i,0,it);f=i;draw()});return}
  if(ax==='y'&&Math.abs(dy)>24&&items.length>1){f=(f+(dy<0?1:-1)+items.length)%items.length;draw();return}
  if(!ax&&it&&it.go){go(...it.go);return}draw()};
 draw();return {draw}}

// a room landing, in five sections
function landingV3(el,R){const secs=[];
 const top=h('div');top.style.cssText='position:absolute;inset:0 0 auto 0;height:180px;z-index:6;pointer-events:none';el.appendChild(top);
 const t=h('div','ttl',R.name);t.style.color=R.color;top.appendChild(t);
 const say=h('div','lsay',R.say);say.style.top='0';say.style.position='relative';
 const sayw=h('div');sayw.style.cssText='position:absolute;left:24px;right:24px;top:106px;height:64px';sayw.appendChild(say);top.appendChild(sayw);
 if(stack.length>1){const nb=h('button','lnav',SHIP[SCREENS[stack[stack.length-2].id].title]||SCREENS[stack[stack.length-2].id].title);nb.style.pointerEvents='auto';nb.onclick=()=>back();top.appendChild(nb)}
 const key=h('div','lkey');el.appendChild(key);const stop=R.keystone(key,el);
 const cap=h('div','lcap',R.caption||'');el.appendChild(cap);
 const sw=h('div','lsw');el.appendChild(sw);switcher(sw,el,R.ups.slice());
 const dh=h('div','dial');dh.style.cssText+='left:24px;top:540px;width:180px;z-index:6';el.appendChild(dh);
 const sum=h('div','lsum');el.appendChild(sum);
 dial(dh,R.doors.map(d=>({...d,color:d.color||R.color})),{start:0,slot:48,label:(d,f)=>'<span style="font-size:'+(f?28:21)+'px;font-weight:700;letter-spacing:-.01em">'+d.k+'</span>'+(d.n!=null?'<i>'+d.n+'</i>':''),
  open:d=>d.go?go(...d.go):receipt(el,d.k+' opens here. Inside pages are the next round.'),
  change:d=>{sum.innerHTML=d.sum();sum.classList.remove('rise');void sum.offsetWidth;if(!RM)sum.classList.add('rise')}});
 const f=h('button','foot',R.action[0]);f.style.color=R.color;f.onclick=()=>R.action[1](el);el.appendChild(f);
 // the flip from Bridge brings the keystone in by itself; otherwise it opens with the rest
 opening(el._flip?[top,cap,sw,dh,sum,f]:[top,key,cap,sw,dh,sum,f],el._flip?160:0);
 return stop}
const sum=(lb,lines)=>'<div class="lb">'+lb+'</div>'+lines.map(l=>'<div class="ln">'+l+'</div>').join('');
const o=n=>'<span class="o">'+n+'</span>';
const un=u=>'<span class="u" style="font-size:.6em">'+u+'</span>';

/* ---------- Log (Notes + Lists) ---------- */
SCREENS.notes={title:'Notes',accent:'notes',tess:'You wrote three today. Trip packing is the one you keep opening.',render(el){const timers=[];
 const cut=n=>n.t.replace('Voice: ','');
 return landingV3(el,{name:'Log',color:'var(--notes)',
  say:'<b style="color:var(--notes)">Three new</b> today, <b style="color:var(--tessblue)">one from Tess</b>. <b style="color:var(--lists)">Trip packing</b> has 8 left.',
  keystone:k=>{const wh=h('div','wall');wh.style.top='196px';wh.style.height='182px';k.appendChild(wh);
   const ws=NOTES.filter(n=>!n.priv&&!n.d.includes('archive')).sort((a,b)=>(b.pin||0)-(a.pin||0)||ORDW[a.w]-ORDW[b.w]).slice(0,11).map(n=>({t:cut(n),id:n.id}));
   const W1=wall(wh,ws,{h:182,seed:3,tap:w=>go('note',{id:w.id})});moments(W1.els,timers);return ()=>timers.forEach(clearInterval)},
  caption:'Tap a word to open its note.',
  ups:[{name:'Trip packing',h:'<b style="color:var(--lists)">Trip packing</b>, 8 left, due Friday.',go:['list']},
   {name:'Run plan',h:'<b style="color:var(--tessblue)">Run plan</b>, Tess kept a thought.',go:['note',{id:'n2'}]},
   {name:'Lamp repair',h:'<b>Lamp repair</b>, the store closes at 6.',go:['note',{id:'n8'}]},
   {name:'Book club',h:'<b>Book club</b> is Thursday at Sam’s.',go:['note',{id:'n4'}]}],
  doors:NDOORS.map(d=>({k:d.n,n:NOTES.filter(x=>inDoor(d.k,x)).length,color:'var(--'+d.c+')',go:['door',{k:d.k}],
   sum:()=>{const L=NOTES.filter(x=>inDoor(d.k,x)).sort((a,b)=>ORDW[a.w]-ORDW[b.w]);return d.k==='private'?sum('Locked',[L.length+' private notes']):sum('Newest '+(L[0]?L[0].w.toLowerCase():''),L.slice(0,3).map(cut))}})),
  action:['New note',()=>go('note',{id:'new'})]})}};

/* ---------- Lookout (Weather) ---------- */
SCREENS.weather={title:'Weather',accent:'weather',tess:'Rain from 7 until about midnight. Take the jacket to the gym.',render(el){el.classList.add('onsky');let iv=0;
 const r=landingV3(el,{name:'Lookout',color:'inherit',
  say:'<b>Cloudy</b> now, <b>rain from 7 PM</b> until about midnight.',
  keystone:(k)=>{const s=weatherCenter(k,W_HOUR,wcond,glassInner(wcond));
   iv=setInterval(()=>{const c=k.style.color;if(!c)return;el.style.color=c;el.style.setProperty('--ink',c);el.style.setProperty('--ink2','color-mix(in srgb,'+c+' 78%,transparent)')},120);return s},
  caption:'Rain gathers on the glass from 7.',
  ups:[{name:'Umbrella',h:'<b>Take the umbrella</b> at 7.'},{name:'Balcony plants',h:'<b>Water the balcony plants</b>, no rain till Thursday.'},{name:'Washing',h:'<b>Bring the washing in</b> before 7.'}],
  doors:[{k:'Hours',go:['weatherhour',{h:'7 PM',t:60,w:'Rain'}],sum:()=>sum('Next four hours',['7 PM '+o('60°')+' rain','8 PM '+o('58°')+' rain','9 PM '+o('57°')+' rain','10 PM '+o('56°')+' rain'].map(x=>x))},
   {k:'Tonight',sum:()=>sum('From 7',['Rain until midnight','Low '+o('54°'),'Clear by 1 AM'])},
   {k:'This week',sum:()=>sum('Driest day',['Thursday, '+o('68°'),'Rain again Saturday','Cooler next week'])},
   {k:'Air',sum:()=>sum('Now',['Wind '+o('9')+un('mph')+', gusting','Humidity '+o('58')+un('%'),'Air is clean'])},
   {k:'Sky',sum:()=>sum('Today',['Sunset '+o('6:08')+un('pm'),'Moon waxing, half','Sun '+o('12°')+' high'])}],
  action:['Rain alert',e=>receipt(e,'You’ll hear 30 minutes before rain.')]});
 return ()=>{clearInterval(iv);r&&r()}}};

/* ---------- Deck (Training) ---------- */
SCREENS.training={title:'Training',accent:'training',tess:'Bench opens at 185 tonight. Last time, three fives.',render(el){
 return landingV3(el,{name:'Deck',color:'var(--training)',
  say:'<b style="color:var(--clay)">Push A</b> at 6:30, bench first. <b style="color:var(--training)">Three of six</b> done this week.',
  keystone:k=>boardCenter(k,ck=>{chalk(ck,'Push A at 6:30, bench first',26,244,28,.95,C);chalk(ck,'about 45 min, 4 lifts, start on the rower',26,266,16,.7,C2);ticks(ck,290);chalk(ck,'5 weeks on plan',230,302,18,.8,C2);chalk(ck,'+10 on bench since Oct 1',230,324,17,.8,C2);let x=26;[['Bench',205],['Squat',275],['Deadlift',315],['Row',130]].forEach(([l,v])=>{x+=chalk(ck,l+' '+v,x,356,19,.65,C2)+16})}),
  caption:'Drag to write. Swipe fast left to wipe.',
  ups:[{name:'Push A',h:'<b style="color:var(--clay)">Push A</b> at '+o('6:30')+un('pm')+', bench first.',go:['workout']},
   {name:'Walk',h:'<b>Log yesterday’s walk</b>, '+o('32')+un('min')+'.'},
   {name:'Pull A',h:'<b style="color:var(--teal)">Pull A</b> is tomorrow morning.'}],
  doors:[{k:'Today',go:['workout'],sum:()=>sum('Push A, 4 lifts',['Bench '+o('185')+un('lb'),'Overhead press '+o('95'),'Cable row '+o('110'),'Triceps '+o('40')])},
   {k:'This week',sum:()=>sum('Monday to Saturday',['Push, Pull, Legs done','Push A tonight','Pull A tomorrow'])},
   {k:'Library',n:28,sum:()=>sum('28 workouts in 6 kinds',['<span style="color:var(--gold)">New: hill sprints</span>','Push, Pull, Legs','Runs and rows'])},
   {k:'Bests',sum:()=>sum('Since Oct 1',['Bench '+o('205')+un('lb'),'Squat '+o('275'),'Deadlift '+o('315')])},
   {k:'Plan',sum:()=>sum('Week 5 of the block',['Bench '+o('+10')+' since Oct 1','Deload next week','Then the new block'])}],
  action:['Start Push A',()=>go('workout')]})}};

/* ---------- Galley (Kitchen) ---------- */
SCREENS.kitchen={title:'Kitchen',accent:'kitchen',tess:'Tacos tonight works. You need tortillas, cilantro and limes.',render(el){
 return landingV3(el,{name:'Galley',color:'var(--kitchenText)',
  say:'<b style="color:var(--kitchenText)">Tacos</b> tonight, 25 min. <b style="color:var(--wine)">Rice</b> goes out today.',
  keystone:k=>{passCenter(k,[tacosT(false),getT(false),riceT(),dishT()],openT);return null},
  caption:'Swipe a ticket up for its next page.',
  ups:[{name:'Rice',h:'<b style="color:var(--wine)">Rice</b> goes out today.',go:['leftovers']},
   {name:'Groceries',h:'<b>Get limes, cilantro, tortillas</b> on the way.',go:['groceries']},
   {name:'Dishes',h:'<b>Dishes</b>, '+o('7')+' waiting since lunch.'}],
  doors:[{k:'Tonight',go:['tonight'],sum:()=>sum('Tacos, 25 min',['You have all 8 things','Char the tortillas first','Chicken, 5 minutes'])},
   {k:'Pantry',n:31,go:['pantry'],sum:()=>sum('31 things',PLACES.map(([n,c,s])=>n+', '+s).slice(0,4))},
   {k:'Recipes',go:['recipes'],sum:()=>sum('4 you can make',['Tacos, 25 min','Dal, 40 min','Shakshuka, 30 min'])},
   {k:'Groceries',n:GET.length,go:['groceries'],sum:()=>sum(GET.length+' to get',GET.slice(0,4))},
   {k:'Leftovers',go:['leftovers'],sum:()=>sum('Eat first',['<span style="color:var(--wine)">Rice, today</span>','Dal, by Friday'])}],
  action:['Cook',()=>go('cook')]})}};

/* ---------- Watch (Routines) ---------- */
SCREENS.routines={title:'Routines',accent:'routines',tess:'Journal has been dry since Saturday. One line tonight brings it back.',render(el){
 const DOORS=[{k:'Today',p:{mode:1,open:'To tend'}},{k:'Body',p:{mode:0,open:'Body'}},{k:'Mind',p:{mode:0,open:'Mind'}},{k:'Home',p:{mode:0,open:'Home'}},{k:'Fruit',p:{mode:1,open:'Fruit'}},{k:'Across the lake',p:{mode:0,open:'Across the lake'}}];
 const set=d=>d.k==='Today'?R.filter(r=>['tend','new','care','begin'].includes(r.st)):d.k==='Fruit'?R.filter(r=>r.st==='fruit'):R.filter(r=>r.g===d.k);
 return landingV3(el,{name:'Watch',color:'var(--routines)',
  say:'<b style="color:var(--green)">Three tended,</b> <b style="color:var(--routines)">four to go,</b> <b style="color:var(--wine)">Journal is thirsty.</b>',
  keystone:k=>{const c=h('div','lclip');c.style.cssText+='left:0;width:402px';c.innerHTML='<iframe title="Woodland" scrolling="no" src="watch.html?embed=1&look='+(phone.dataset.look==='black'?'black':'paper')+'"></iframe>';c.firstChild.style.left='0';k.appendChild(c);return null},
  caption:'Hold a tree to water it. Tap to see it.',
  ups:[{name:'Walk',h:'<b>Walk</b> is next, around 6.'},{name:'Journal',h:'<b style="color:var(--wine)">Journal</b> has been dry since Saturday.'},{name:'Stretch',h:'<b>Stretch</b> at 8 pm, nine minutes.'}],
  doors:DOORS.map(d=>({k:d.k,go:['sheaf',d.p],sum:()=>{const p=phrases(set(d)).slice(0,3);const names=set(d).slice(0,2).map(r=>r.n);return p.length?'<div class="lb">'+(names.join(', ')||' ')+'</div>'+p.map(x=>'<div class="ln" style="color:var(--'+x[2]+')">'+W[x[0]]+x[1]+'</div>').join(''):sum('',['Nothing here today.'])}})),
  action:['Plant',e=>receipt(e,'Tap open ground in the woodland to plant.')]})}};

/* ---------- Purse (Money) ---------- */
SCREENS.money={title:'Money',accent:'money',tess:'2,125 still yours. Closing at 179 after rent.',render(el){
 return landingV3(el,{name:'Purse',color:'var(--purse)',
  say:'<b>'+o('2,125')+' still yours.</b> Closing at <b style="color:var(--purse)">'+o('179')+'</b> after rent.',
  keystone:k=>{const c=h('div','lclip');c.style.cssText+='left:24px;width:354px';c.innerHTML='<iframe title="Indices" scrolling="no" src="purse.html?embed=1&look='+(phone.dataset.look==='black'?'black':'paper')+'"></iframe>';c.firstChild.style.left='-24px';k.appendChild(c);return null},
  caption:'Swipe across for a category, up and down for an index.',
  ups:[{name:'Phone',h:'<b style="color:var(--clay)">Phone</b> '+o('45')+' on Monday is the next drop.'},{name:'Groceries',h:'<b>Groceries</b> '+o('86')+' today.'},{name:'Rent',h:'<b>Rent</b> '+o('1,450')+' on Friday.'}],
  doors:[{k:'This month',sum:()=>sum('You are the stock',['Still yours '+o('2,125'),'Closes at '+o('179'),'Pace '+o('74')+', calm'])},
   {k:'Kinds',sum:()=>sum('October so far',['<span style="color:var(--kitchenText)">Food '+o('412')+'</span>','<span style="color:var(--clay)">Home '+o('1,450')+'</span>','<span style="color:var(--slate)">Going out '+o('96')+'</span>'])},
   {k:'Saving',sum:()=>sum('On plan',['<span style="color:var(--gold)">Japan '+o('3,400')+'</span>','Rainy day '+o('2,000'),'Next in '+o('6')+' days'])},
   {k:'Investing',sum:()=>sum('Portfolio',['Index '+o('102.4'),'Above cost since Oct 3','Quiet this week'])},
   {k:'Debts',sum:()=>sum('Car loan',['Left '+o('6,200'),'Paid off by May 2028','Ahead of schedule'])},
   {k:'Mine',sum:()=>sum('Your own indices',['INDIA, 12 months','DEBTS, 4 children','Make one with Tess'])}],
  action:['Log',e=>receipt(e,'Say what you spent. Tess files it.')]})}};
{const ph=document.getElementById('phone');const setP=()=>ph.style.setProperty('--purse',ph.dataset.look==='black'?'#8DBFA7':'#3F7A62');setP();new MutationObserver(setP).observe(ph,{attributes:true,attributeFilter:['data-look']})}

/* ---------- the flip: Bridge's mosaic turns tile by tile into the room's keystone (and back) ---------- */
const ORDERS={// 0 to 1 per tile: when it turns. Each room turns its own way.
 notes:(q,r,C,Rw)=>(r/Rw)*.7+(q/C)*.3,                      // set like type, row by row
 weather:(q,r,C,Rw)=>Math.hypot(q-C/2+.5,(r-Rw/2+.5)*2)/C,   // from the middle out, like a cloud clearing
 training:(q,r,C,Rw)=>q/C,                                  // a sweep left to right, the towel
 kitchen:(q,r,C,Rw)=>(q/C)*.6+(r/Rw)*.4,                     // column by column, top down, like tickets
 routines:(q,r,C,Rw)=>(1-r/Rw)*.8+Math.abs(q/C-.5)*.4,       // from the ground up, like growth
 money:(q,r,C,Rw)=>(q/C)*.85+(1-r/Rw)*.15};                  // left to right, like a line drawing
const AXIS={notes:'x',weather:'x',training:'y',kitchen:'y',routines:'y',money:'x'};
function tiles(src,room,mode,done){// mode 'in': src image flips away, the page under it shows. 'reveal': page-colored tiles open on what is under them.
 const cv=$('#doorway'),c=cv.getContext('2d');const X0=24,Y0=196,Wd=354,Hh=182,C=16,Rw=8,tw=Wd/C,th=Hh/Rw;const ord=ORDERS[room]||ORDERS.notes,ax=AXIS[room]||'x';
 const bg=css('--p-bg');const D=[];for(let r=0;r<Rw;r++)for(let q=0;q<C;q++){const k=ord(q,r,C,Rw);D.push(Math.max(0,Math.min(1,k))*420+Math.random()*40)}
 const dur=mode==='in'?380:300,t0=performance.now();
 const slice=(x,y,s)=>{if(!src)return;const w=ax==='x'?tw*s:tw,hh=ax==='y'?th*s:th;c.drawImage(src,x*2,(y-180)*2,tw*2,th*2,x+(tw-w)/2,y+(th-hh)/2,w,hh)};
 const cover=(x,y,s)=>{c.fillStyle=bg;if(ax==='x'){const w=tw*(1-s)/2;c.fillRect(x,y,w+.5,th+.5);c.fillRect(x+tw-w-.5,y,w+.5,th+.5);c.fillStyle='rgba(0,0,0,'+(.1*(1-s))+')';c.fillRect(x+w,y,tw-2*w,th)}
  else{const hh=th*(1-s)/2;c.fillRect(x,y,tw+.5,hh+.5);c.fillRect(x,y+th-hh-.5,tw+.5,hh+.5);c.fillStyle='rgba(0,0,0,'+(.1*(1-s))+')';c.fillRect(x,y+hh,tw,th-2*hh)}};
 function frame(now){const t=now-t0;c.clearRect(0,0,402,874);let live=false;
  for(let r=0;r<Rw;r++)for(let q=0;q<C;q++){const x=X0+q*tw,y=Y0+r*th,p=(t-D[r*C+q])/dur;
   if(mode==='in'){if(p>=1)continue;live=true;if(p<=0){c.fillStyle=bg;c.fillRect(x,y,tw+.5,th+.5);slice(x,y,1)}else if(p<.5){c.fillStyle=bg;c.fillRect(x,y,tw+.5,th+.5);slice(x,y,Math.cos(Math.PI*p))}else cover(x,y,-Math.cos(Math.PI*p))}
   else{if(p>=1)continue;live=true;cover(x,y,p<=0?0:Math.sin(Math.PI/2*p))}}
  if(live)requestAnimationFrame(frame);else{c.clearRect(0,0,402,874);done&&done()}}
 requestAnimationFrame(frame)}
const LANDS=['notes','weather','training','kitchen','routines','money'];
function flipTo(id){const from=current,fromC=cleanup,mos=from&&$('#mosaic',from);
 if(RM||!mos){go(id);return}
 // snapshot the mosaic as it is now, so the tiles carry exactly what was on screen
 const snap=document.createElement('canvas');snap.width=804;snap.height=440;snap.getContext('2d').drawImage(mos,0,0);
 stack.push({id});const el=h('div','screen');el._flip=1;
 const S=SCREENS[id];phone.style.setProperty('--room','var(--'+(S.accent||'ink')+')');el.dataset.id=id;el.appendChild(h('div','sbar','<span>5:10</span><span></span>'));
 let c=null;try{c=S.render(el,{})}catch(e){window.__showErr&&window.__showErr('screen '+id+': '+e.message)}shipNames(el);stage.appendChild(el);current=el;cleanup=c;
 tiles(snap,id,'in',()=>{});setTimeout(()=>{from.remove();fromC&&fromC()},60);tessCue(S.accent);drawMap()}
// any door into a room landing from Bridge flips; everything else keeps its own transition
const go0=go;go=function(id,params,opts={}){if(current&&current.dataset.id==='home'&&LANDS.includes(id)&&!params?.k)return flipTo(id);return go0(id,params,opts)};
const back0=back;back=function(){const top=stack[stack.length-1],prev=stack[stack.length-2];
 if(!RM&&top&&prev&&prev.id==='home'&&LANDS.includes(top.id)){stack.pop();const old=current,oldC=cleanup;const {el,c}=mount('home');current=el;cleanup=c;
  opening([...el.children].filter(x=>!x.classList.contains('sbar')&&x.id!=='mosaic'),0);old.remove();oldC&&oldC();tiles(null,top.id,'reveal');tessCue(null);drawMap();return}
 back0()};
