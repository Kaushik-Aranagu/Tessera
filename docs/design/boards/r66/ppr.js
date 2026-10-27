const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const pg=await b.newPage({viewport:{width:402,height:874}});const errs=[];pg.on('pageerror',e=>errs.push(e.message));
await pg.goto('file://'+__dirname+'/index.html'+(process.argv[2]==='black'?'?theme=black':''));await pg.waitForTimeout(600);
await pg.evaluate(()=>go('workout'));await pg.waitForTimeout(900);
await pg.evaluate(()=>{const w=window.__wo;w.pick(1);w.log()});await pg.waitForTimeout(1200);
const pr=await pg.evaluate(()=>JSON.stringify(window.__wo.S.pr&&window.__wo.S.pr.v));await pg.screenshot({path:'PR1.png'});
await pg.evaluate(()=>window.__wo.finish());await pg.waitForTimeout(500);await pg.screenshot({path:'PR2.png'});
console.log('pr',pr,'bench best',await pg.evaluate(()=>window.__wo.LIFTS[1].newBest),errs);await b.close()})();
