const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
for(const sch of ['light','dark']){const p=await b.newPage({viewport:{width:1100,height:900},colorScheme:sch,deviceScaleFactor:1});const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(1200);
await p.locator('#ph').screenshot({path:`c0-${sch}.png`});
await p.keyboard.press('Tab');
const d=await p.$('#dial');if(d){const bb=await d.boundingBox();await p.mouse.click(bb.x+100,bb.y+bb.height*0.32);await p.waitForTimeout(300);await p.mouse.click(bb.x+100,bb.y+bb.height*0.32);await p.waitForTimeout(900)}
await p.locator('#ph').screenshot({path:`c1-${sch}.png`});console.log(sch,errs)}
await b.close()})();
