const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const pg=await b.newPage({viewport:{width:402,height:874}});const errs=[];pg.on('pageerror',e=>errs.push(e.message));
await pg.goto('file://'+__dirname+'/index.html');await pg.waitForTimeout(600);
await pg.evaluate(()=>go('workout'));await pg.waitForTimeout(900);
await pg.evaluate(()=>{window.__wo.pick(2,-1);const t=performance.now();performance.now=()=>t+230});await pg.waitForTimeout(300);await pg.screenshot({path:'PK1.png'});
await pg.evaluate(()=>{delete performance.now});await pg.waitForTimeout(700);console.log('li',await pg.evaluate(()=>window.__wo.S.li),errs);await b.close()})();
