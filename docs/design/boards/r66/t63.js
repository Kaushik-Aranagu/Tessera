// 321: workout mode. Logs the warm up, rests, moves to Bench by itself, logs a set, drags the weight, finishes.
const {chromium}=require('/opt/node22/lib/node_modules/playwright');const look=process.argv[2]||'paper';
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage({viewport:{width:1300,height:1000}});
const errs=[];p.on('pageerror',e=>{if(!/setPointerCapture/.test(e.message))errs.push(e.message)});let bad=0;const ok=(c,m)=>{console.log((c?'ok   ':'FAIL ')+m);if(!c)bad++};
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(1500);await p.evaluate(l=>{phone.dataset.look=l},look);
await p.evaluate(()=>{scrollTo(0,0);reset('home');go('training')});await p.waitForTimeout(1200);await p.evaluate(()=>go('workout'));await p.waitForTimeout(2500);
const tap=async sel=>{await p.evaluate(s=>{const e=current.querySelector(s);const r=e.getBoundingClientRect();const o={bubbles:true,clientX:r.left+20,clientY:r.top+10,pointerId:1};e.dispatchEvent(new PointerEvent('pointerdown',o));e.dispatchEvent(new PointerEvent('pointerup',o))},sel)};
const st=()=>p.evaluate(()=>({...__wo.S,sum:current.querySelector('.lsum .sx:not(.gone) .lb').textContent,hdr:current.querySelector('.one .hdr').textContent,obj:current.querySelector('.act .ao').textContent,band:current.querySelector('.swn').textContent}));
let s=await st();ok(s.hdr==='Warm up'&&/warm up/.test(s.obj),'opens on the warm up: '+s.hdr+' / '+s.obj);
await tap('.act');await p.waitForTimeout(900);s=await st();ok(s.phase==='rest'&&s.restOf===30&&s.hdr==='Rest','Done starts a 30 s rest');
await p.evaluate(()=>__wo.tickRest(999));await p.waitForTimeout(2200);s=await st();ok(s.phase==='lift'&&s.li===1&&s.hdr==='Set 1 of 3','after the rest the dial turns to Bench: '+s.hdr);
ok(/Bench press/.test(s.sum),'summary is the Bench ledger: '+s.sum);ok(/4 of 5/.test(s.band),'band counts lifts: '+s.band);
await p.evaluate(()=>{const w=current.querySelector('.one.wo'),r=w.getBoundingClientRect(),x=r.left+60,y=r.top+100;w.dispatchEvent(new PointerEvent('pointerdown',{bubbles:true,clientX:x,clientY:y,pointerId:2}));for(let k=1;k<=6;k++)w.dispatchEvent(new PointerEvent('pointermove',{bubbles:true,clientX:x,clientY:y-k*9*(document.querySelector('#phone').getBoundingClientRect().width/402),pointerId:2}));w.dispatchEvent(new PointerEvent('pointerup',{bubbles:true,clientX:x,clientY:y,pointerId:2}))});
await p.waitForTimeout(1200);const w=await p.evaluate(()=>__wo.LIFTS[1].sets.map(x=>x.w).join());ok(/^(\d+),\1,\1$/.test(w)&&+w.split(',')[0]>185,'drag up adds weight to the sets left: '+w);
await tap('.act');await p.waitForTimeout(900);s=await st();ok(s.phase==='rest'&&s.done[1]===1,'set 1 logged, resting');
const o=await p.evaluate(()=>{const a=current.querySelector('.lsum').getBoundingClientRect(),f=current.querySelector('.act').getBoundingClientRect();return a.bottom<=f.top+1});ok(o,'summary stays above the action');
await p.evaluate(()=>__wo.finish());await p.waitForTimeout(1500);s=await st();ok(s.phase==='done'&&s.hdr==='Finished'&&/Deck/.test(s.obj),'finish: '+s.hdr+' / '+s.obj);
const stops=await p.evaluate(()=>[...current.querySelectorAll('.one div,.swn .ln,.lcap,.act .ao')].map(e=>e.textContent.trim()).filter(t=>/\.$/.test(t)));ok(!stops.length,'no full stops: '+stops.join('|'));
ok(!errs.length,'no page errors '+errs.join('|'));console.log(bad?'FAILED '+bad:'All green');await b.close()})();
