// G13 tap tests: every tap target, its hit size (44 min) and what a tap does; then the same under reducedMotion
const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});let fails=0;
for(const rm of ['no-preference','reduce'])for(const sch of ['light','dark']){const p=await b.newPage({viewport:{width:1100,height:900},colorScheme:sch,reducedMotion:rm});const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(900);const W=rm==='reduce'?150:700;
const ok=(c,m)=>{if(!c){fails++;console.log('FAIL',rm,sch,m)}};
const size=async(sel,name)=>{const bb=await (await p.$(sel)).boundingBox();ok(bb.height>=44&&bb.width>=44,`${name} hit ${Math.round(bb.width)}x${Math.round(bb.height)}`);return bb};
const front=()=>p.evaluate(()=>[...document.querySelectorAll('#wheel .wr')].find(r=>r.querySelector('.dt')&&!r.querySelector('.dt').hidden)?.querySelector('.tt').textContent);
// landing doors: each 44+ and opens its place
for(let i=0;i<3;i++)await size(`#nums button:nth-child(${i+1})`,'number '+i);await size('#another','another');await size('#reel','reel');await size('#kindR button','kind');
await size('#hGo','Start (landing)');
{const r0=await p.$eval('#reelN',e=>e.textContent);await p.click('#another');await p.waitForTimeout(W);ok((await p.$eval('#reelN',e=>e.textContent))!==r0,'another rolls the reel')}
await p.click('#nums button');await p.waitForTimeout(W);ok(!(await p.$eval('#day',e=>e.hidden)),'Today door opens Today');
// wheel rows: tap a back row -> it comes to the front
await size('#wheel .wr[data-i="3"]','wheel row');const f0=await front();
await p.click('#wheel .wr[data-i="3"]',{force:true});await p.waitForTimeout(W);ok(await front()==='Evening stretch',`row tap -> front (${f0} -> ${await front()})`);
// tap the front row -> opens the routine
await p.click('#wheel .wr[data-i="3"]',{force:true});await p.waitForTimeout(W);ok(!(await p.$eval('#page',e=>e.hidden)),'front row tap opens routine');
await p.keyboard.press('Escape');await p.waitForTimeout(W);
// action word on today: tap -> opens front routine, started
await size('#act','action word (today)');await p.click('#act');await p.waitForTimeout(W);ok(await p.textContent('#pGo')==='Next step','Start opens and starts');
// step row: tap -> strike shows, drops to Done after the wait
await size('#steps .ir','step row');const bb=await (await p.$('#steps .ir')).boundingBox();await p.mouse.click(bb.x+40,bb.y+20);
ok(await p.$eval('#steps .ir .sk',e=>e.style.visibility!=='hidden'),'step tap strikes');await p.waitForTimeout(rm==='reduce'?800:1800);
ok((await p.textContent('#steps')).includes('Done'),'step drops to Done');
// Undo in receipt
await size('#pRc .un','Undo');await p.click('#pRc .un');await p.waitForTimeout(200);ok(!(await p.textContent('#steps')).includes('Done'),'Undo restores step');
// action word on routine: Next step checks the next one
await size('#pGo','action word (routine)');await p.click('#pGo');await p.waitForTimeout(rm==='reduce'?800:1800);ok((await p.textContent('#pRc')).includes('done'),'Next step checks one');
// Restart by keyboard right (same as drag right)
await p.focus('#pGo');await p.keyboard.press('ArrowRight');await p.waitForTimeout(200);ok((await p.textContent('#pRc')).startsWith('Evening stretch, restarted.'),'Restart receipt');
await p.click('#pRc .un');await p.waitForTimeout(200);ok((await p.textContent('#steps')).includes('Done'),'Restart Undo restores checked steps');
// Skip today (drag left)
await p.focus('#pGo');await p.keyboard.press('ArrowLeft');await p.waitForTimeout(W+300);ok((await p.textContent('#receipt')).startsWith('Skipped today.'),'Skip receipt');
ok(await p.$eval('#receipt',e=>getComputedStyle(e).color)===await p.$eval('#brief',e=>getComputedStyle(document.querySelector('#receipt')).color),'skip ink2');
await size('.tess','Tess');
// kinds: door -> category wheel; a one-thing routine has no step count; tap a row brings it front; tap front opens
await p.keyboard.press('Escape');await p.waitForTimeout(W);
await p.click('#kindR button',{position:{x:200,y:30}});await p.waitForTimeout(W);ok(!(await p.$eval('#cat',e=>e.hidden)),'Mornings door opens kind');
await size('#cWheel .wr[data-i="1"]','kind row');await p.click('#cWheel .wr[data-i="1"]',{force:true});await p.waitForTimeout(W);
const d1=await p.$eval('#cWheel .wr[data-i="1"] .d1',e=>e.textContent);ok(!/steps?\b/.test(d1),'one-thing row has no step count: '+d1);
await p.click('#cWheel .wr[data-i="1"]',{force:true});await p.waitForTimeout(W);ok(await p.textContent('#pTitle')==='Vitamins','front kind row opens routine');
await p.keyboard.press('Escape');await p.waitForTimeout(W);
// New routine: tap -> making one; kind word cycles; shape choices; Save -> on its kind's wheel, receipt with Undo
await size('#cGo','New routine (kind)');await p.click('#cGo');await p.waitForTimeout(W);ok(!(await p.$eval('#mk',e=>e.hidden)),'New routine opens making');
await size('#mkCat','kind word');const k0=await p.textContent('#mkCat');await p.click('#mkCat');ok(await p.textContent('#mkCat')!==k0,'kind word cycles');await p.click('#mkCat');await p.click('#mkCat');await p.click('#mkCat');await p.click('#mkCat');await p.click('#mkCat');
await size('.mkS[data-s="one"]','Keep it one thing');await size('.mkS[data-s="steps"]','Add steps');
await p.click('#mkName');await p.keyboard.type('Sunday plan');await p.click('.mkS[data-s="steps"]');await p.keyboard.type('Look at the week');await p.keyboard.press('Enter');
await size('#mkGo','Save');await p.click('#mkGo');await p.waitForTimeout(W*2+200);ok((await p.textContent('#rcCat')).startsWith('Sunday plan, saved.'),'Save receipt');
ok(await p.$eval('#cWheel',e=>[...e.querySelectorAll('.wr')].some(r=>r.querySelector('.dt')&&!r.querySelector('.dt').hidden&&r.textContent.includes('Sunday plan'))),'saved routine in front');
// From another room (drag right) -> pick one -> Borrowed, front, source named
await p.focus('#cGo');await p.keyboard.press('ArrowRight');await p.waitForTimeout(W);ok(!(await p.$eval('#br',e=>e.hidden)),'From another room opens');
await size('.brr','borrow row');await p.click('.brr');await p.waitForTimeout(W*2+200);ok((await p.textContent('#rcCat')).includes('borrowed from'),'borrow receipt');ok(await p.textContent('#cTitle')==='Borrowed','lands in Borrowed');
console.log(rm,sch,'errors',errs.length?errs:'none');await p.close()}
console.log(fails?`${fails} failed`:'All tap tests pass');await b.close()})();
