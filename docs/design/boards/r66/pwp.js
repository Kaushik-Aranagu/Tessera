const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const pg=await b.newPage({viewport:{width:402,height:874}});const errs=[];pg.on('pageerror',e=>errs.push(e.message));
await pg.goto('file://'+__dirname+'/index.html');await pg.waitForTimeout(600);
await pg.evaluate(()=>go('workout'));await pg.waitForTimeout(900);
await pg.evaluate(()=>{const w=window.__wo;w.pick(1);w.log()});await pg.waitForTimeout(400);
// freeze clock at mid-wipe
await pg.evaluate(()=>{window.__wo.log();const t=performance.now();performance.now=()=>t+230});await pg.waitForTimeout(300);
await pg.screenshot({path:'WP1.png'});
console.log('phase',await pg.evaluate(()=>window.__wo.S.phase),errs);await b.close()})();
