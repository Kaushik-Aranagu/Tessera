const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
for(const sch of ['light','dark']){const p=await b.newPage({viewport:{width:1100,height:900},colorScheme:sch});const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(1200);
const s=async n=>{await p.waitForTimeout(700);await p.locator('#ph').screenshot({path:`U${n}-${sch}.png`})};
await p.click('#dLib');await s(0);
const c=await (await p.$('#cats')).boundingBox();await p.mouse.move(c.x+c.width-40,c.y+c.height/2);await p.mouse.down();await p.mouse.move(c.x+c.width-40,c.y-30,{steps:8});await p.mouse.up();await s(1);
await p.keyboard.press('Escape');await p.waitForTimeout(500);await p.click('#dWeek');await s(2);await p.keyboard.press('Escape');await p.waitForTimeout(500);
await p.click('#hNow');await p.waitForTimeout(600);await p.click('#bestL');await s(3);
console.log(sch,errs,await p.evaluate(()=>document.querySelectorAll('.wu').length))}
await b.close()})();
