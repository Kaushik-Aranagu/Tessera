const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
for(const sch of ['light','dark']){const p=await b.newPage({viewport:{width:1100,height:1000},colorScheme:sch});const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(2000);
await p.locator('#ph').screenshot({path:`c0-${sch}.png`});await p.waitForTimeout(6000);await p.locator('#ph').screenshot({path:`c1-${sch}.png`});await p.waitForTimeout(7000);await p.locator('#ph').screenshot({path:`c2-${sch}.png`});
const m=await (await p.$('#mosW')).boundingBox();await p.mouse.move(m.x+m.width-20,m.y+80);await p.mouse.down();await p.mouse.move(m.x+m.width-160,m.y+82,{steps:6});await p.mouse.up();await p.waitForTimeout(1500);
await p.locator('#ph').screenshot({path:`c3-${sch}.png`});await p.waitForTimeout(9000);await p.locator('#ph').screenshot({path:`c4-${sch}.png`});await p.waitForTimeout(9000);await p.locator('#ph').screenshot({path:`c5-${sch}.png`});
console.log(sch,errs)}
await b.close()})();
