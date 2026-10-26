const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
for(const sch of ['light','dark']){const p=await b.newPage({viewport:{width:1100,height:900},colorScheme:sch});const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(1200);
const s=async n=>{await p.waitForTimeout(600);await p.locator('#ph').screenshot({path:`r${n}-${sch}.png`})};
await s(0);
const W=await (await p.$('#wheel')).boundingBox();await p.mouse.move(W.x+100,W.y+150);await p.mouse.wheel(0,120);await p.waitForTimeout(700);await s(1);
await p.click('#act');await s(2);
const r=await p.$$('#steps .ir');let bb=await r[0].boundingBox();await p.mouse.click(bb.x+40,bb.y+20);await p.waitForTimeout(300);await s(3);
await p.waitForTimeout(1600);await s(4);
bb=await (await p.$$('#steps .ir'))[1].boundingBox();await p.mouse.move(bb.x+40,bb.y+20);await p.mouse.down();await p.mouse.move(bb.x-60,bb.y+20,{steps:6});await p.mouse.up();await s(5);
const g=await (await p.$('#pGo')).boundingBox();await p.mouse.move(g.x+20,g.y+15);await p.mouse.down();await p.mouse.move(g.x+100,g.y+15,{steps:6});await s(6);await p.mouse.up();await s(7);
for(let i=0;i<6;i++){await p.click('#pGo');await p.waitForTimeout(150)}await p.waitForTimeout(1800);await s(8);
await p.keyboard.press('Escape');await s(9);
console.log(sch,errs,await p.evaluate(()=>document.getElementById('brief').textContent))}
await b.close()})();
