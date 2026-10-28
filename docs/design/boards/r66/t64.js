// 322: cooking and shopping modes. Next moves the step and starts its pan timer; Got takes things off aisle by aisle.
const {chromium}=require('/opt/node22/lib/node_modules/playwright');const look=process.argv[2]||'paper';
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage({viewport:{width:1300,height:1000}});
const errs=[];p.on('pageerror',e=>{if(!/setPointerCapture/.test(e.message))errs.push(e.message)});let bad=0;const ok=(c,m)=>{console.log((c?'ok   ':'FAIL ')+m);if(!c)bad++};
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(1500);await p.evaluate(l=>{phone.dataset.look=l},look);
const tap=async sel=>{await p.evaluate(s=>{const e=current.querySelector(s);const r=e.getBoundingClientRect();const o={bubbles:true,clientX:r.left+20,clientY:r.top+10,pointerId:1};e.dispatchEvent(new PointerEvent('pointerdown',o));e.dispatchEvent(new PointerEvent('pointerup',o))},sel)};
const txt=()=>p.evaluate(()=>({big:current.querySelector('.one .wt,.one .wn').textContent,hdr:current.querySelector('.one .wh').textContent,sum:current.querySelector('.lsum .sx:not(.gone) .lb').textContent,cut:[...current.querySelectorAll('.one .wt,.one .w1,.one .w2')].some(e=>e.scrollWidth>e.clientWidth+1),over:current.querySelector('.lsum').getBoundingClientRect().bottom>current.querySelector('.act').getBoundingClientRect().top+1}));
await p.evaluate(()=>{scrollTo(0,0);reset('home');go('kitchen')});await p.waitForTimeout(1000);await p.evaluate(()=>go('cook'));await p.waitForTimeout(2500);
let s=await txt();ok(s.big==='Char the tortillas'&&!s.cut,'cook opens on step 1, whole: '+s.big);
await tap('.act');await p.waitForTimeout(1500);s=await txt();const ck=await p.evaluate(()=>({i:__ck.S.i,T:__ck.S.T.Brown}));ok(ck.i===1&&ck.T>0&&s.big==='Brown the chicken'&&!s.cut,'Next turns to Brown and starts its timer: '+s.big+' '+ck.T);
ok(/Brown/.test(s.sum)&&!s.over,'summary is the step, above the action: '+s.sum);
await p.evaluate(()=>{scrollTo(0,0);reset('home');go('kitchen')});await p.waitForTimeout(1000);await p.evaluate(()=>go('shop'));await p.waitForTimeout(2500);
s=await txt();ok(/^Limes/.test(s.big),'shop starts with limes: '+s.big);
for(let k=0;k<3;k++){await tap('.act');await p.waitForTimeout(500)}await p.waitForTimeout(400);s=await txt();ok(/all got/.test(s.hdr),'produce done: '+s.hdr+' / '+s.big);
await tap('.act');await p.waitForTimeout(1500);s=await txt();ok(/^Feta/.test(s.big)&&/Dairy/.test(s.sum)&&!s.over,'Got turns to Dairy: '+s.big+' / '+s.sum);
const st=await p.evaluate(()=>[...current.querySelectorAll('.one div,.swn .ln,.lcap,.act .ao')].map(e=>e.textContent.trim()).filter(t=>/\.$/.test(t)));ok(!st.length,'no full stops '+st.join('|'));
ok(!errs.length,'no page errors '+errs.join('|'));console.log(bad?'FAILED '+bad:'All green');await b.close()})();
