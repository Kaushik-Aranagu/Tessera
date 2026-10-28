// 373: touching his words while a change dries stops it. The line holds, runs back from where it got to, the ghost
// lets go, no receipt, Tess says "Stopped, nothing changed", the same sentence is offered again. Also a refusal while
// it waits, and a take-down half way (the room stays). Reduce Motion stops at once.
const {chromium}=require('/opt/node22/lib/node_modules/playwright');
async function run(rm){const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
 const pg=await b.newPage({viewport:{width:402,height:874},reducedMotion:rm?'reduce':'no-preference'});const errs=[];pg.on('pageerror',e=>errs.push(e.message));
 await pg.goto('file://'+__dirname+'/index.html');await pg.waitForTimeout(600);
 await pg.evaluate(()=>go('chart'));await pg.waitForTimeout(1500);
 const st=()=>pg.evaluate(()=>({at:__ch.at,dry:__ch.dry,tline:__ch.tline,heard:document.querySelector('.ch-heard')?.textContent||'',tess:document.querySelector('.ch-tess')?.textContent||'',act:document.querySelector('.ch-act').textContent,rc:document.querySelector('.chart .receipt')?.textContent||'',gh:document.querySelectorAll('.ch-c.gh').length,lines:document.querySelectorAll('.ch-dry').length,big:__ch.big,id:current.dataset.id}));
 const tapWords=async()=>{const c=await pg.evaluate(()=>{const r=document.querySelector('.ch-heard').getBoundingClientRect();return [r.x+r.width/2,r.y+r.height/2]});await pg.mouse.click(c[0],c[1])};
 const r={rm};
 // first sentence: stop at 1 s
 await pg.click('.ch-act');await pg.waitForTimeout(1000);r.drying=await st();
 r.lineAt=await pg.evaluate(()=>{const l=document.querySelector('.ch-dry');return l?l.getBoundingClientRect().width:0});
 await tapWords();await pg.waitForTimeout(rm?50:200);r.holding=await st();
 r.lineHeld=await pg.evaluate(()=>{const l=document.querySelector('.ch-dry');return l?l.getBoundingClientRect().width:0});
 await pg.waitForTimeout(rm?100:700);r.stopped=await st();
 // say it again, let it set
 await pg.click('.ch-act');await pg.waitForTimeout(2300);r.setAgain=await st();
 // walk to the box refusal and stop it while it waits
 await pg.click('.ch-act');await pg.waitForTimeout(2300);await pg.click('.ch-act');await pg.waitForTimeout(2300);
 await pg.click('.ch-act');await pg.waitForTimeout(400);r.refusing=await st();await tapWords();await pg.waitForTimeout(rm?100:400);r.refusalStopped=await st();
 // let the refusal come and take its offer
 await pg.click('.ch-act');await pg.waitForTimeout(1500);r.offer=await st();
 await pg.click('.chart .receipt button');await pg.waitForTimeout(2300);r.grown=await st();
 // the rest of the sentences, then take it down and stop half way
 for(let i=0;i<10&&await pg.evaluate(()=>__ch.at<__ch.n);i++){await pg.evaluate(()=>__ch.say());await pg.waitForTimeout(2300)}
 await pg.evaluate(()=>__ch.allow());await pg.waitForTimeout(300);
 await pg.evaluate(()=>__ch.down());await pg.waitForTimeout(rm?0:800);
 if(!rm){await tapWords();await pg.waitForTimeout(1200);r.downStopped=await st();r.apps=await pg.evaluate(()=>APPS.includes('chart'));
  r.places=await pg.evaluate(()=>[...document.querySelectorAll('.chart .ch-pl')].map(p=>p.getAnimations().length+':'+getComputedStyle(p).clipPath.slice(0,12)).join(' '));
  r.parts=await pg.evaluate(()=>[...document.querySelectorAll('.chart .ch-c')].map(c=>getComputedStyle(c).opacity).join(' '))}
 r.errs=errs;console.log(JSON.stringify(r));await b.close()}
(async()=>{await run(false);await run(true)})();
