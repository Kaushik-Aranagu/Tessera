const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const pg=await b.newPage({viewport:{width:402,height:874}});const errs=[];pg.on('pageerror',e=>errs.push(e.message));
await pg.goto('file://'+__dirname+'/index.html');await pg.waitForTimeout(600);
await pg.evaluate(()=>go('shop'));await pg.waitForTimeout(900);
for(let i=0;i<3;i++)await pg.evaluate(()=>window.__sh.got());
console.log('jd',await pg.evaluate(()=>{const d=document.querySelector('.tk-steps .jd');return d&&d.textContent}),errs);await b.close()})();
