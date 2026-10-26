const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage({viewport:{width:900,height:1000},deviceScaleFactor:2});const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(3500);await p.locator('.row').screenshot({path:'a.png'});
await p.click('[data-f="Archivo"]');await p.waitForTimeout(1500);await p.locator('.row').screenshot({path:'b.png'});
await p.click('[data-f="Bricolage Grotesque"]');await p.waitForTimeout(1500);await p.locator('.row').screenshot({path:'c.png'});console.log(errs);await b.close()})();
