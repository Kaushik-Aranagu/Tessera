// 323: routine mode. Moves step through Tidy, tends it, the dial turns to Stretch and the countdown runs.
const {chromium}=require('/opt/node22/lib/node_modules/playwright');const look=process.argv[2]||'paper';
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage({viewport:{width:1300,height:1000}});
const errs=[];p.on('pageerror',e=>{if(!/setPointerCapture/.test(e.message))errs.push(e.message)});let bad=0;const ok=(c,m)=>{console.log((c?'ok   ':'FAIL ')+m);if(!c)bad++};
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(1500);await p.evaluate(l=>{phone.dataset.look=l},look);
const tap=async sel=>{await p.evaluate(s=>{const e=current.querySelector(s);const r=e.getBoundingClientRect();const o={bubbles:true,clientX:r.left+20,clientY:r.top+10,pointerId:1};e.dispatchEvent(new PointerEvent('pointerdown',o));e.dispatchEvent(new PointerEvent('pointerup',o))},sel)};
const txt=()=>p.evaluate(()=>({big:current.querySelector('.one .big').textContent,hdr:current.querySelector('.one .hdr').textContent,sml:current.querySelector('.one .sml').textContent,sum:current.querySelector('.lsum .sx:not(.gone) .lb').textContent,i:__rt.S.i,over:current.querySelector('.lsum').getBoundingClientRect().bottom>current.querySelector('.act').getBoundingClientRect().top+1}));
await p.evaluate(()=>{scrollTo(0,0);reset('home');go('routines')});await p.waitForTimeout(1000);await p.evaluate(()=>go('tend'));await p.waitForTimeout(2500);
let s=await txt();ok(s.big==='Counter'&&/Tidy, 1 of 3/i.test(s.hdr),'opens on Tidy, Counter: '+s.hdr);
for(let k=0;k<3;k++){await tap('.act');await p.waitForTimeout(400)}await p.waitForTimeout(1800);s=await txt();ok(s.i===1&&s.big==='Hamstrings'&&/Stretch/.test(s.sum)&&!s.over,'Tidy tended, turns to Stretch: '+s.big+' / '+s.sum);
const t0=s.sml;await p.waitForTimeout(2200);s=await txt();ok(s.sml!==t0,'countdown runs: '+t0+' to '+s.sml);
await p.evaluate(()=>{__rt.S.left=1});await p.waitForTimeout(2300);s=await txt();ok(s.big==='Hips','the next move comes by itself: '+s.big);
const st=await p.evaluate(()=>[...current.querySelectorAll('.one div,.swn .ln,.lcap,.act .ao')].map(e=>e.textContent.trim()).filter(t=>/\.$/.test(t)));ok(!st.length,'no full stops '+st.join('|'));
ok(!errs.length,'no page errors '+errs.join('|'));console.log(bad?'FAILED '+bad:'All green');await b.close()})();
