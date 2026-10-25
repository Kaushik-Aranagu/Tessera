const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
for(const sch of ['light','dark']){const p=await b.newPage({viewport:{width:1100,height:1000},colorScheme:sch});const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(2500);
await p.locator('#ph').screenshot({path:`b0-${sch}.png`});
for(let k=1;k<3;k++){const m=await (await p.$('#mosW')).boundingBox();await p.mouse.move(m.x+m.width-20,m.y+80);await p.mouse.down();await p.mouse.move(m.x+m.width-160,m.y+82,{steps:6});await p.mouse.up();await p.waitForTimeout(2200);
await p.locator('#ph').screenshot({path:`b${k}-${sch}.png`})}
console.log(sch,errs)}
await b.close()})();
