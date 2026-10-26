const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
for(const sch of ['light','dark']){const p=await b.newPage({viewport:{width:1100,height:1000},colorScheme:sch,deviceScaleFactor:2});const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(1500);const ph=await (await p.$('#ph')).boundingBox();await p.screenshot({path:`v6-${sch}.png`,clip:ph});
await p.click('#kGrid .kd:nth-child(2)');await p.waitForTimeout(700);console.log(sch,errs,'kind opens',!(await p.$eval('#cat',e=>e.hidden)))}
await b.close()})();
