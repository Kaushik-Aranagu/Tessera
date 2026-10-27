const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
for(const sch of ['light','dark']){const p=await b.newPage({viewport:{width:1100,height:900},colorScheme:sch});const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html',{waitUntil:'networkidle'});await p.waitForTimeout(1200);
const rows=await p.$$('#list .rc');let tgt;for(const r of rows){if((await r.textContent()).startsWith('Butter'))tgt=r}
const bb=await tgt.boundingBox();await p.mouse.click(bb.x+20,bb.y+bb.height/2);await p.waitForTimeout(600);await p.locator('#ph').screenshot({path:`f0-${sch}.png`});
await p.click('#receipt .ex');await p.waitForTimeout(900);await p.locator('#ph').screenshot({path:`f1-${sch}.png`});
console.log(sch,errs)}await b.close()})();
