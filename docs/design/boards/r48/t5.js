const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
for(const sch of ['light','dark']){const p=await b.newPage({viewport:{width:1100,height:900},colorScheme:sch});const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(1000);
await p.locator('#ph').screenshot({path:`e0-${sch}.png`});
const r=await (await p.$('#wheel')).boundingBox();await p.mouse.move(r.x+150,r.y+160);await p.mouse.down();await p.mouse.move(r.x+150,r.y+80,{steps:10});await p.mouse.up();await p.waitForTimeout(700);await p.locator('#ph').screenshot({path:`e1-${sch}.png`});
await p.mouse.move(r.x+150,r.y+150);await p.mouse.down();await p.mouse.move(r.x+150,r.y+125,{steps:5});await p.waitForTimeout(50);await p.locator('#ph').screenshot({path:`e2-${sch}.png`});await p.mouse.up();
await p.click('#mT');await p.waitForTimeout(600);await p.locator('#ph').screenshot({path:`e3-${sch}.png`});
console.log(sch,errs)}await b.close()})();
