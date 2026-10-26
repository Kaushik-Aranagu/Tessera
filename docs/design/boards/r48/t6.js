const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
for(const sch of ['light','dark']){const p=await b.newPage({viewport:{width:1100,height:900},colorScheme:sch});const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(1000);
const s=async(n,w=700)=>{await p.waitForTimeout(w);await p.locator('#ph').screenshot({path:`g${n}-${sch}.png`})};
await s(0);
const r=await (await p.$('#wheel')).boundingBox();await p.mouse.move(r.x+150,r.y+180);await p.mouse.down();await p.mouse.move(r.x+150,r.y+140,{steps:8});await p.mouse.up();await s(1);
await p.mouse.move(r.x+150,r.y+180);await p.mouse.down();await p.mouse.move(r.x+150,r.y+120,{steps:8});await p.mouse.up();await s(2);
// tap focused lens -> full
const d=await (await p.$('#dial')).boundingBox();await p.mouse.click(d.x+80,d.y+98);await s(3);
await p.keyboard.press('Escape');await p.waitForTimeout(500);
await p.click('#act');await s(4);await p.click('#cGo');await s(5);
console.log(sch,errs)}await b.close()})();
