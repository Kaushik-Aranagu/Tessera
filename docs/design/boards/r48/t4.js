const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
for(const sch of ['light','dark']){const p=await b.newPage({viewport:{width:1100,height:900},colorScheme:sch});const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(1000);
await p.locator('#ph').screenshot({path:`d0-${sch}.png`});await p.click('#list [data-r]');await p.waitForTimeout(600);await p.locator('#ph').screenshot({path:`d1-${sch}.png`});
await p.click('#haveB');await p.waitForTimeout(400);await p.click('#haveB');await p.waitForTimeout(400);await p.locator('#ph').screenshot({path:`d2-${sch}.png`});
await p.click('#list [data-c]');await p.waitForTimeout(500);await p.click('#list .rw .nm span');await p.waitForTimeout(600);await p.locator('#ph').screenshot({path:`d3-${sch}.png`});
console.log(sch,errs)}await b.close()})();
