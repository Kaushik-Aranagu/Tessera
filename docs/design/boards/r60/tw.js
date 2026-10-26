const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
for(const sch of ['light','dark']){const p=await b.newPage({viewport:{width:1000,height:1000},colorScheme:sch});const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(1600);const ph=await p.$$('#walls .phone');await ph[0].scrollIntoViewIfNeeded();await ph[0].screenshot({path:`wmid-${sch}.png`});await p.waitForTimeout(3500);
for(let i=0;i<ph.length;i++){await ph[i].scrollIntoViewIfNeeded();await p.waitForTimeout(300);await ph[i].screenshot({path:`w${i}-${sch}.png`})}console.log(sch,errs)}
await b.close()})();
