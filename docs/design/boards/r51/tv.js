const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
for(const sch of ['light','dark']){const p=await b.newPage({viewport:{width:1100,height:900},colorScheme:sch,deviceScaleFactor:2});const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(1200);
const s=async(n,w=500)=>{await p.waitForTimeout(w);await p.locator('#ph').screenshot({path:`v${n}-${sch}.png`})};
await s(0);
const c=await (await p.$('#cats')).boundingBox();await p.mouse.move(c.x+250,c.y+19);await p.mouse.down();await s(1,400);await p.mouse.move(c.x+200,c.y+19,{steps:10});await s(2,250);await p.mouse.up();await s(3,800);
await p.mouse.move(c.x+250,c.y+19);await p.mouse.down();await p.mouse.move(c.x+252,c.y-1,{steps:8});await s(4,150);await p.mouse.up();await s(5,800);
console.log(sch,errs,await p.evaluate(()=>document.querySelector('[aria-selected="true"]').textContent))}
await b.close()})();
