const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
for(const sch of ['light','dark']){const p=await b.newPage({viewport:{width:1100,height:900},colorScheme:sch});const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(1200);
const c=await (await p.$('#cats')).boundingBox();await p.mouse.move(c.x+c.width-40,c.y+19);await p.mouse.down();await p.mouse.move(c.x+c.width-200,c.y+19,{steps:10});await p.mouse.up();await p.waitForTimeout(900);
await p.locator('#ph').screenshot({path:`c2-${sch}.png`});
const d=await (await p.$('#dial')).boundingBox();await p.keyboard.press('Tab');await p.focus('#dial');await p.keyboard.press('ArrowDown');await p.waitForTimeout(700);await p.keyboard.press('ArrowDown');await p.waitForTimeout(900);
await p.locator('#ph').screenshot({path:`c3-${sch}.png`});console.log(sch,errs)}
await b.close()})();
