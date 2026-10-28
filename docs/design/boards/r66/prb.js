// 372: the room keeps itself while he is away; brought back after a take-down it rebuilds the way he made it, once;
// a tap finishes it at once without acting; Reduce Motion shows it whole.
const {chromium}=require('/opt/node22/lib/node_modules/playwright');
async function run(rm){const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
 const pg=await b.newPage({viewport:{width:402,height:874},reducedMotion:rm?'reduce':'no-preference'});const errs=[];pg.on('pageerror',e=>errs.push(e.message));
 await pg.goto('file://'+__dirname+'/index.html');await pg.waitForTimeout(600);
 await pg.evaluate(()=>go('chart'));await pg.waitForTimeout(1500);
 const n=await pg.evaluate(()=>__ch.n);for(let i=0;i<n;i++){await pg.evaluate(()=>__ch.say());await pg.waitForTimeout(2300)}
 await pg.evaluate(()=>__ch.allow());await pg.waitForTimeout(300);await pg.click('.ch-act');await pg.waitForTimeout(900);// water the orchid
 const st=()=>pg.evaluate(()=>({id:current.dataset.id,at:window.__ch&&__ch.at,rp:__ch.rp,reach:__ch.reach,tline:__ch.tline,heard:document.querySelector('.ch-heard')?.textContent||'',d:__ch.plants().map(p=>p.d).join(''),rc:document.querySelector('.chart .receipt')?.textContent||''}));
 const r={rm};r.before=await st();
 // leave and come back: kept, no replay
 await pg.evaluate(()=>back());await pg.waitForTimeout(800);await pg.evaluate(()=>go('chart'));await pg.waitForTimeout(rm?200:1500);r.kept=await st();
 // take down, Undo, open: the replay
 await pg.evaluate(()=>__ch.down());await pg.waitForTimeout(rm?200:1800);await pg.click('.undoline button');await pg.waitForTimeout(rm?200:900);
 await pg.evaluate(()=>go('chart'));
 if(!rm){await pg.waitForTimeout(1100);r.mid=await st();await pg.waitForTimeout(2600)}else await pg.waitForTimeout(200);
 r.end=await st();
 // once: leave and return, no replay
 await pg.evaluate(()=>back());await pg.waitForTimeout(800);await pg.evaluate(()=>go('chart'));await pg.waitForTimeout(rm?200:900);r.once=await st();
 if(!rm){// skip: a tap during the replay finishes it and does nothing else
  await pg.evaluate(()=>__ch.down());await pg.waitForTimeout(1800);await pg.click('.undoline button');await pg.waitForTimeout(900);
  await pg.evaluate(()=>go('chart'));await pg.waitForTimeout(1000);await pg.click('.ch-act');await pg.waitForTimeout(200);r.skip=await st();
  await pg.waitForTimeout(600);await pg.click('.ch-act');await pg.waitForTimeout(300);r.afterSkipTap=await st()}
 r.errs=errs;console.log(JSON.stringify(r));await b.close()}
(async()=>{await run(false);await run(true)})();
