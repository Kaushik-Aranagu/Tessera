
(()=>{
const RM=matchMedia('(prefers-reduced-motion: reduce)').matches;
const cs=()=>getComputedStyle(document.documentElement);const hex=h=>{h=h.trim().replace('#','');return[0,2,4].map(k=>parseInt(h.slice(k,k+2),16))};
const clamp=x=>Math.max(0,Math.min(1,x));const col=v=>hex(cs().getPropertyValue('--'+v));
function lum(c){const f=v=>{v/=255;return v<=.03928?v/12.92:Math.pow((v+.055)/1.055,2.4)};return .2126*f(c[0])+.7152*f(c[1])+.0722*f(c[2])}
const phone=document.getElementById('phone'),ov=document.getElementById('ov'),hit=document.getElementById('hit'),say=document.getElementById('say'),picks=document.getElementById('picks'),room=document.getElementById('room');
const dpr=Math.min(2,devicePixelRatio||1);let W=360,Hh=740;
function size(){W=phone.clientWidth;Hh=phone.clientHeight;ov.width=W*dpr;ov.height=Hh*dpr}size();addEventListener('resize',size);
const LS=140,lay=document.createElement('canvas');lay.width=lay.height=LS*dpr;
// ---- her state
const S={mode:'idle',x:0,y:0,tx:0,ty:0,sc:1,tsc:1,sp:0,tsp:0,lv:0,eye:[0,0],teye:null,closed:0,blinkAt:performance.now()+2600,blinks:0,spin:0};
const home=()=>[W-48,Hh-48];[S.x,S.y]=home();[S.tx,S.ty]=home();
const DABS=[[-9,-4,0],[9,-4,1],[0,8,2],[-14,7,0],[13,8,1],[3,-13,2]];
function draw(now){const t=RM?0:now/1000,L=lum(col('phone')),dark=L<.18;
  const P=dark?['#FF5B3A','#86B4FF','#FFC23D']:['#D2502F','#3561C8','#E0A21E'],A=dark?[.86,.64]:[.8,.52];
  // springs
  const k=RM?1:.16;S.x+=(S.tx-S.x)*k;S.y+=(S.ty-S.y)*k;S.sc+=(S.tsc-S.sc)*.14;S.sp+=(S.tsp-S.sp)*.12;
  if(S.mode==='talk'){S.lv=.5+.5*Math.abs(Math.sin(t*7.3)*Math.sin(t*2.1+1));S.spin+=RM?0:.03+.05*S.lv}else S.lv*=.9;
  const quiet=S.mode==='quiet',br=1+(quiet?.04*Math.sin(t*.45):.06*Math.sin(t*.98))+.12*S.lv;
  const x=lay.getContext('2d');x.setTransform(1,0,0,1,0,0);x.clearRect(0,0,lay.width,lay.height);x.setTransform(dpr,0,0,dpr,0,0);
  x.globalCompositeOperation=dark?'screen':'source-over';const C=LS/2;
  const order=dark?[0,1,2,3,4,5]:[1,4,0,3,2,5];
  order.forEach(n=>{const [dx0,dy0,p]=DABS[n];const a=S.spin*(n<3?1:-1.4),ca=Math.cos(a),sa=Math.sin(a);const f=1+.35*S.sp;
    const dx=(dx0*ca-dy0*sa)*f,dy=(dx0*sa+dy0*ca)*f;const r=(n<3?20:12)*br,rgb=hex(P[p]).join(',');
    const g=x.createRadialGradient(0,0,0,0,0,r);g.addColorStop(0,`rgba(${rgb},${A[0]})`);g.addColorStop(.45,`rgba(${rgb},${A[1]})`);g.addColorStop(1,`rgba(${rgb},0)`);
    x.save();x.filter='blur(3px)';x.translate(C+dx+(n>2&&!quiet?2*Math.sin(t*.7+n):0),C+dy+(n<3&&!quiet?-1.5*Math.max(0,Math.sin(t*.6+n)):0));x.fillStyle=g;x.beginPath();x.ellipse(0,0,r,r*.92,0,0,7);x.fill();x.restore()});
  const o=ov.getContext('2d');o.setTransform(1,0,0,1,0,0);o.clearRect(0,0,ov.width,ov.height);o.setTransform(dpr,0,0,dpr,0,0);
  o.save();o.translate(S.x,S.y);o.scale(S.sc,S.sc);o.drawImage(lay,-C,-C,LS,LS);if(!dark){o.globalCompositeOperation='multiply';o.globalAlpha=.3;o.drawImage(lay,-C,-C,LS,LS);o.globalAlpha=1;o.globalCompositeOperation='source-over'}
  // eyes: wander when idle, look where she is attending otherwise
  const want=S.teye||[1.2*Math.sin(t*.41)+.8*Math.sin(t*1.13),.7*Math.sin(t*.29+1)];S.eye[0]+=(want[0]-S.eye[0])*.12;S.eye[1]+=(want[1]-S.eye[1])*.12;
  let open=1;if(!RM&&now>S.blinkAt&&!quiet){const u=(now-S.blinkAt)/160;open=u<1?Math.max(.12,Math.abs(Math.cos(u*Math.PI))):1;if(u>=1){if(S.blinks>0){S.blinks--;S.blinkAt=now+120}else S.blinkAt=now+3000+Math.random()*5000}}
  o.fillStyle=dark?'rgba(21,21,23,.82)':'rgba(30,24,30,.86)';o.strokeStyle=o.fillStyle;o.lineWidth=1.3;o.lineCap='round';
  for(const sg of[-1,1]){const ex=sg*4.2+S.eye[0],ey=-4+S.eye[1];if(quiet){o.beginPath();o.moveTo(ex-1.9,ey+.4);o.quadraticCurveTo(ex,ey+1.5,ex+1.9,ey+.4);o.stroke()}else{o.beginPath();o.ellipse(ex,ey,1.6,Math.max(.25,1.75*open),0,0,7);o.fill()}}
  o.restore();
  hit.style.left=(S.x-42)+'px';hit.style.top=(S.y-42)+'px';requestAnimationFrame(draw)}
requestAnimationFrame(draw);
// ---- her words: departure flips, names are doors
const AL=" abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789:,.'?";
let sayT=null,flipT=[];
function speak(parts,{hold=6000,cls=''}={}){flipT.forEach(clearTimeout);flipT=[];clearTimeout(sayT);say.innerHTML='';const line=document.createElement('div');if(cls)line.className=cls;say.appendChild(line);let n=0;
  parts.forEach(p=>{const [txt,c]=typeof p==='string'?[p,null]:p;let host=line;if(c){host=document.createElement('span');host.className='k'+(c==='sky'?' sky':'');if(c!=='sky')host.style.color=`var(--${c})`;line.appendChild(host)}
    for(const ch of txt){const s=document.createElement('span');s.className='c';s.textContent=RM?ch:' ';host.appendChild(s);if(RM)continue;const ti=AL.indexOf(ch);let steps=ti<0?1:Math.min(9,1+(ti%9));const d=n++*14;
      for(let q=0;q<steps;q++)flipT.push(setTimeout(()=>{s.textContent=q===steps-1?ch:AL[(ti-steps+q+1+AL.length)%AL.length]||ch;s.classList.remove('flip');void s.offsetWidth;s.classList.add('flip')},d+q*52))}});
  if(hold)sayT=setTimeout(()=>{say.innerHTML='';if(S.mode==='answer')settle()},hold)}
function setPicks(list){picks.innerHTML='';list.forEach(([w,fn])=>{const b=document.createElement('button');b.textContent=w;b.onclick=e=>{e.stopPropagation();fn()};picks.appendChild(b)});if(list.length)picks.classList.add('rise')}
function settle(){S.mode='idle';S.tsc=1;S.tsp=0;S.teye=null;[S.tx,S.ty]=home();setPicks([]);const a=document.getElementById('ask');if(a)a.remove()}
const ANS={date:[['Friday, October 23. Three things today; the next is '],['Push day','training'],'.'],
  push:[['Push day','training'],': 4 lifts, about 1 hr 10 min. Bench is first.'],
  sunset:[['Sunset','sky'],' at 6:34 pm, clear and 64°. A walk fits after.'],
  notes:['3 notes this week. One is ',['a private note','notes'],'.'],
  kitchen:[['Tacos','kitchen'],' tonight. ',['Groceries','kitchen'],' has 4 to get.'],
  training:['Your last session was Tuesday, with a new best on bench.']};
// ---- tap: ask
function listen(){S.mode='listen';S.tsp=.5;S.tsc=1.06;S.teye=[-2.4,-.6];say.innerHTML='';
  setPicks([["What's next",()=>answer([["Push day",'training'],' at 6:30 pm, then ',["Stretch",'routines'],' at 8.'])],
    ['Log a set',()=>answer(['Bench, set 4. Say the weight and reps when you are ready.'])],
    ['Add to groceries',()=>answer(['Added limes to ',['Groceries','kitchen'],'. ',['Tacos','kitchen'],' still needs 3 things.'])]]);
  const i=document.createElement('input');i.id='ask';i.placeholder='Ask Tess';i.setAttribute('aria-label','Ask Tess');say.appendChild(i);
  i.addEventListener('input',()=>{S.teye=[-3.2+Math.min(3,i.value.length*.09),-.6]});
  i.addEventListener('keydown',e=>{if(e.key==='Enter'&&i.value.trim()){const v=i.value.trim();answer(['Noted. I will put "'+v.slice(0,30)+'" where it belongs.'])}});
  setTimeout(()=>i.focus({preventScroll:true}),60)}
function answer(parts){S.mode='answer';S.tsp=.15;S.tsc=1;S.teye=[-2,-.4];setPicks([]);speak(parts)}
// ---- hold: talk
const HEARD="is there time to lift before dinner";let heardT=null,cancelArmed=false;
function talkStart(){S.mode='talk';S.tsc=1.25;S.tsp=.25;S.teye=[0,-1.6];setPicks([]);cancelArmed=false;let w=0;const words=HEARD.split(' ');say.innerHTML='';
  const tick=()=>{if(S.mode!=='talk')return;w++;speak([words.slice(0,w).join(' ')],{hold:0,cls:'you'});if(w<words.length)heardT=setTimeout(tick,330)};heardT=setTimeout(tick,250)}
function talkEnd(){clearTimeout(heardT);if(cancelArmed){say.innerHTML='';settle();return}
  answer(['Yes. ',['Push day','training'],' takes about 1 hr 10 min, and dinner is at 7:45 pm.'])}
// ---- drag: ask about this
let hot=null;
function targetAt(x,y){const r=phone.getBoundingClientRect();ov.style.display='none';hit.style.pointerEvents='none';const el=document.elementFromPoint(r.left+x,r.top+y);ov.style.display='';hit.style.pointerEvents='';return el&&el.closest('[data-ask]')}
function markHot(el){if(hot===el)return;if(hot){hot.querySelectorAll('.k').forEach(k=>k.classList.remove('hot'));hot.classList.remove('hot');if(hot.classList.contains('k'))hot.classList.remove('hot')}hot=el;if(el){if(el.classList.contains('k'))el.classList.add('hot');el.querySelectorAll('.k').forEach(k=>k.classList.add('hot'));el.classList.add('hot')}}
function drop(){const el=hot;markHot(null);if(!el){settle();return}const key=el.dataset.ask;S.tsc=.8;S.teye=[-1.5,0];
  answer(ANS[key]||['That one has nothing new.']);setTimeout(()=>{if(RM){[S.x,S.y]=home()}[S.tx,S.ty]=home();S.tsc=1},1300)}
// ---- room
function openRoom(){settle();room.classList.add('on');S.teye=[-1,-1.4]}
function closeRoom(){room.classList.remove('on');S.teye=null}
document.getElementById('back').onclick=closeRoom;
room.querySelectorAll('[data-undo]').forEach(u=>u.onclick=()=>{u.textContent='Reversed';u.style.textDecoration='none';u.style.color='var(--ink3)'});
// ---- quiet
function quiet(){settle();S.mode='quiet';S.tsc=.94;speak(['Quiet until 1:30 pm.'],{hold:3000})}
function wake(){S.mode='idle';S.tsc=1;S.blinks=1;S.blinkAt=performance.now()}
// ---- gestures on her
let g=null,lastTap=0;
hit.addEventListener('pointerdown',e=>{hit.setPointerCapture(e.pointerId);const r=phone.getBoundingClientRect();g={x0:e.clientX,y0:e.clientY,t0:performance.now(),r,kind:null,hold:setTimeout(()=>{if(!g.kind){g.kind='talk';talkStart()}},350)}});
hit.addEventListener('pointermove',e=>{if(!g)return;const dx=e.clientX-g.x0,dy=e.clientY-g.y0,dt=performance.now()-g.t0;
  if(g.kind==='talk'){cancelArmed=dx<-60;S.teye=cancelArmed?[-3,0]:[0,-1.6];S.tsc=cancelArmed?1.05:1.25;return}
  if(!g.kind&&Math.hypot(dx,dy)>10){clearTimeout(g.hold);if(dy<-40&&dt<260&&Math.abs(dx)<30){g.kind='up';openRoom();return}g.kind='drag';S.mode='drag';setPicks([]);say.innerHTML='';S.tsc=.78}
  if(g.kind==='drag'){const x=e.clientX-g.r.left,y=e.clientY-g.r.top-44;S.tx=x;S.ty=y;if(RM){S.x=x;S.y=y}S.teye=[Math.max(-3,Math.min(3,dx*.02)),Math.max(-2,Math.min(2,dy*.02))];markHot(targetAt(x,y))}});
hit.addEventListener('pointerup',e=>{if(!g)return;clearTimeout(g.hold);const kind=g.kind;g=null;
  if(kind==='talk')return talkEnd();if(kind==='drag')return drop();if(kind==='up')return;
  const now=performance.now();if(S.mode==='quiet'){wake();return}
  if(now-lastTap<300){lastTap=0;quiet();return}lastTap=now;if(S.mode==='listen')settle();else listen()});
hit.addEventListener('keydown',e=>{if(e.key==='Enter'||e.key===' '){e.preventDefault();S.mode==='listen'?settle():listen()}});
phone.addEventListener('pointerdown',e=>{if(e.target===hit||hit.contains(e.target)||picks.contains(e.target)||e.target.id==='ask'||room.contains(e.target))return;if(S.mode==='listen'||S.mode==='answer'){say.innerHTML='';settle()}});
let rY=null;room.addEventListener('pointerdown',e=>rY=e.clientY);room.addEventListener('pointerup',e=>{if(rY!=null&&e.clientY-rY>60)closeRoom();rY=null});
// ---- she speaks first, once, when something changes
setTimeout(()=>{if(S.mode==='idle'){S.teye=[-2,-.5];speak([['Stretch','routines'],' can move to 9 if ',['Push day','training'],' runs late.']]);setTimeout(()=>{if(S.mode==='idle')S.teye=null},6000)}},1800);
// ---- demo buttons
const wait=ms=>new Promise(r=>setTimeout(r,ms));
document.getElementById('demo').addEventListener('click',async e=>{const d=e.target.dataset&&e.target.dataset.d;if(!d)return;closeRoom();if(S.mode==='quiet')wake();settle();say.innerHTML='';
  if(d==='tap')listen();
  if(d==='hold'){talkStart();await wait(3200);talkEnd()}
  if(d==='drag'){const t=phone.querySelector('.one .k').getBoundingClientRect(),r=phone.getBoundingClientRect();S.mode='drag';S.tsc=.78;const tx=t.left-r.left+t.width/2,ty=t.top-r.top+t.height/2-44;
    for(let i=1;i<=30;i++){const u=i/30;const[hx,hy]=home();S.tx=hx+(tx-hx)*u;S.ty=hy+(ty-hy)*u-Math.sin(u*Math.PI)*30;if(RM){S.x=S.tx;S.y=S.ty}markHot(targetAt(S.tx,S.ty+0));await wait(22)}markHot(phone.querySelector('.one .k'));await wait(500);drop()}
  if(d==='up')openRoom();
  if(d==='quiet')quiet()});
// ---- looks
const root=document.documentElement;document.getElementById('looks').addEventListener('click',e=>{const l=e.target.dataset&&e.target.dataset.l;if(!l)return;
  document.querySelectorAll('#looks button').forEach(b=>b.setAttribute('aria-pressed',b===e.target));root.removeAttribute('data-look');
  if(l==='black'){root.dataset.look='black';root.dataset.theme='dark'}else if(l==='white'){root.dataset.look='white';root.dataset.theme='light'}else if(l==='paper')root.dataset.theme='light';else root.removeAttribute('data-theme')});
})();
