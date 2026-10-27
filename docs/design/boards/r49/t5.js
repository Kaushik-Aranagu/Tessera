const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
for(const sch of ['light','dark']){const p=await b.newPage({viewport:{width:1100,height:900},colorScheme:sch});const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html',{waitUntil:'networkidle'});await p.waitForTimeout(1200);
await p.click('#tg');await p.waitForTimeout(500);await p.locator('#ph').screenshot({path:`e0-${sch}.png`});await p.waitForTimeout(700);await p.locator('#ph').screenshot({path:`e1-${sch}.png`});
let r=await (await p.$('#dial')).boundingBox();for(let k=0;k<3;k++){await p.mouse.move(r.x+150,r.y+140);await p.mouse.down();await p.mouse.move(r.x+150,r.y+76,{steps:8});await p.mouse.up();await p.waitForTimeout(500)}
await p.waitForTimeout(600);await p.locator('#ph').screenshot({path:`e2-${sch}.png`});
console.log(sch,errs)}await b.close()})();
