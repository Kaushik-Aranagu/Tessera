const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
for(const sch of ['light','dark']){const p=await b.newPage({viewport:{width:1100,height:900},colorScheme:sch});const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(1200);
const s=async n=>{await p.waitForTimeout(700);await p.locator('#ph').screenshot({path:`h${n}-${sch}.png`})};
await s(0);
await p.click('#dWeek');await s(1);await p.mouse.wheel(0,-100);await p.waitForTimeout(100);
const ww=await (await p.$('#wkW')).boundingBox();await p.mouse.move(ww.x+100,ww.y+100);await p.mouse.wheel(0,-200);await s(2);
await p.keyboard.press('Escape');await p.waitForTimeout(500);
await p.click('#dLib');await s(3);await p.click('#libW');await p.waitForTimeout(200);
await p.keyboard.press('Enter');await s(4);await p.keyboard.press('Escape');await p.waitForTimeout(400);await p.keyboard.press('Escape');await p.waitForTimeout(500);
await p.click('#hNow');await s(5);
await p.click('#start');await p.waitForTimeout(1200);await p.click('#go');await p.waitForTimeout(1500);
await p.keyboard.press('Escape');await s(6);
await p.click('#hPause');await s(7);
await p.click('#hNow');await s(8);
console.log(sch,errs,await p.evaluate(()=>document.getElementById('what').textContent))}
await b.close()})();
