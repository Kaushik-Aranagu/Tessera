const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const shots=[];
for(const sch of ['light','dark']){const p=await b.newPage({viewport:{width:1100,height:860},colorScheme:sch});const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html',{waitUntil:'networkidle'});
await p.click('#rr');await p.waitForTimeout(1500);await p.locator('#phone').screenshot({path:`r-${sch}-0.png`});
await p.click('#rq');await p.waitForTimeout(1300);const bb=await (await p.$('#lin')).boundingBox();await p.mouse.move(bb.x+60,bb.y+120);await p.mouse.down();await p.waitForTimeout(150);await p.locator('#phone').screenshot({path:`r-${sch}-1.png`});await p.mouse.up();
console.log(sch,errs)}await b.close()})();
