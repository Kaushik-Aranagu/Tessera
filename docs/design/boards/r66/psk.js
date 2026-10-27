const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const pg=await b.newPage({viewport:{width:402,height:874}});const errs=[];pg.on('pageerror',e=>errs.push(e.message));
await pg.goto('file://'+__dirname+'/index.html');await pg.waitForTimeout(700);
await pg.evaluate(()=>go('chart'));const t0=Date.now();const r={};
for(const t of [250,520,800,1300]){await pg.waitForTimeout(Math.max(0,t-(Date.now()-t0)));r['t'+t]=await pg.evaluate(()=>[...document.querySelectorAll('.ch-pl')].map(p=>{const a=p.getAnimations()[0];return a?Math.round((a.effect.getComputedTiming().progress??0)*100):'done'}));await pg.screenshot({path:'SK'+t+'.png'})}
// reduced motion: no animations at all
const pg2=await b.newPage({viewport:{width:402,height:874},reducedMotion:'reduce'});await pg2.goto('file://'+__dirname+'/index.html');await pg2.waitForTimeout(700);await pg2.evaluate(()=>go('chart'));await pg2.waitForTimeout(100);
r.rm=await pg2.evaluate(()=>[...document.querySelectorAll('.ch-pl')].map(p=>p.getAnimations().length).join(''));
console.log(JSON.stringify(r),errs);await b.close()})();
