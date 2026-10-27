const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage({viewport:{width:1100,height:900},colorScheme:'light'});const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html',{waitUntil:'networkidle'});await p.waitForTimeout(1000);
for(const k of ['soft','moon','deep','now']){await p.click(`#dk [data-p="${k}"]`);await p.waitForTimeout(300);await p.locator('#ph').screenshot({path:`k-${k}.png`})}
await p.click('#tw');await p.waitForTimeout(300);await p.locator('#ph').screenshot({path:'k-paper.png'});console.log(errs);await b.close()})();
