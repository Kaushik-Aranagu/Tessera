const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
for(const sch of ['light','dark']){const p=await b.newPage({viewport:{width:1100,height:900},colorScheme:sch});const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(1200);
const s=async n=>{await p.waitForTimeout(700);await p.locator('#ph').screenshot({path:`L${n}-${sch}.png`})};
await p.click('#dLib');await s(0);
const c=await (await p.$('#cats')).boundingBox();await p.mouse.move(c.x+c.width-30,c.y+c.height/2);await p.mouse.down();await p.mouse.move(c.x+c.width-200,c.y+c.height/2,{steps:8});await p.mouse.up();await s(1);
await p.click('#dimW');await s(2);
const d=await (await p.$('#ldial')).boundingBox();await p.mouse.move(d.x+d.width/2,d.y+d.height/2);await p.mouse.wheel(0,120);await s(3);
await p.mouse.wheel(0,-120);await p.waitForTimeout(600);await p.click('#dimW');await p.click('#dimW');await p.waitForTimeout(500);
const w=await (await p.$('#libW')).boundingBox();await p.mouse.click(w.x+w.width/2,w.y+40);await s(4);
console.log(sch,errs,await p.evaluate(()=>[...document.querySelectorAll('#ph > div:not([hidden])')].map(e=>e.id).join(',')))}
await b.close()})();
