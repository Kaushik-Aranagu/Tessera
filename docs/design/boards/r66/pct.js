const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const pg=await b.newPage({viewport:{width:402,height:874}});const errs=[];pg.on('pageerror',e=>errs.push(e.message));
await pg.goto('file://'+__dirname+'/index.html');await pg.waitForTimeout(600);
await pg.evaluate(()=>go('workout'));await pg.waitForTimeout(900);
await pg.evaluate(()=>{window.__wo.finish();const t=performance.now();performance.now=()=>t+300});await pg.waitForTimeout(200);
await pg.screenshot({path:'CT1.png',clip:{x:0,y:320,width:402,height:50}});
await pg.evaluate(()=>{delete performance.now});await pg.waitForTimeout(1200);await pg.screenshot({path:'CT2.png',clip:{x:0,y:320,width:402,height:50}});
console.log(errs);await b.close()})();
