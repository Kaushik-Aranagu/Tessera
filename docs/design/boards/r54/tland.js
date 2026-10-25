const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
for(const sch of ['light','dark']){const p=await b.newPage({viewport:{width:1100,height:950},colorScheme:sch});const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(1200);
const s=async n=>{await p.waitForTimeout(700);await p.locator('#ph').screenshot({path:`L${n}-${sch}.png`})};
await s(0);await p.click('#another');await s(1);
const k=await (await p.$('#kinds')).boundingBox();await p.mouse.move(k.x+k.width-30,k.y+36);await p.mouse.down();await p.mouse.move(k.x+k.width-200,k.y+36,{steps:8});await p.mouse.up();await s(2);
await p.mouse.click(k.x+k.width-60,k.y+30);await s(3);
console.log(sch,errs,await p.evaluate(()=>[...document.querySelectorAll('#ph > div:not([hidden])')].map(e=>e.id).join(',')))}
await b.close()})();
