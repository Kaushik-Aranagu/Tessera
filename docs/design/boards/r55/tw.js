const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
for(const sch of ['light','dark']){const p=await b.newPage({viewport:{width:1100,height:1000},colorScheme:sch,deviceScaleFactor:2});const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(2000);await p.locator('#wxG').scrollIntoViewIfNeeded();
for(const [i,d] of [[0,0],[1,1300],[2,2600]]){await p.waitForTimeout(d?1300:300);await p.locator('#wxG').screenshot({path:`g${i}-${sch}.png`})}
console.log(sch,errs)}
await b.close()})();
