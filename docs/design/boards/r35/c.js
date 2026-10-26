const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
const p=await b.newPage({viewport:{width:900,height:900},deviceScaleFactor:2});
await p.goto('file://'+process.cwd()+'/index.html');
for(const l of process.argv.slice(2)){await p.click(`[data-l=${l}]`);await p.waitForTimeout(1500);
 const f=await p.locator('figure').all();
 for(let k=8;k<11;k++)await f[k].locator('canvas').screenshot({path:`c${k}-${l}.png`})}
await b.close()})()
