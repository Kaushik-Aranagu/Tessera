const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
for(const sch of ['light','dark']){const p=await b.newPage({viewport:{width:1100,height:900},colorScheme:sch});const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html',{waitUntil:'networkidle'});await p.waitForTimeout(1000);
await p.click('#start');await p.waitForTimeout(800);await p.click('#go');await p.waitForTimeout(800);
for(let k=0;k<3;k++){await p.click('#go');await p.waitForTimeout(2600);if(k<2){await p.click('#go');await p.waitForTimeout(900)}}
await p.waitForTimeout(1200);
const bb=await (await p.$('#go')).boundingBox();await p.mouse.move(bb.x+20,bb.y+12);await p.mouse.down();await p.mouse.move(bb.x-80,bb.y+12,{steps:10});await p.mouse.up();await p.waitForTimeout(1400);
await p.keyboard.press('Escape');await p.waitForTimeout(900);await p.locator('#ph').screenshot({path:`sk-${sch}.png`});console.log(sch,errs)}
await b.close()})();
