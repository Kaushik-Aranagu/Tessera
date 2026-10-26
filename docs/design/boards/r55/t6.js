const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
const p=await b.newPage({viewport:{width:1100,height:1000},colorScheme:'light',deviceScaleFactor:3});
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(1200);
for(const [k,n] of [['wind',3],['cloud',5]]){await p.evaluate(n=>{for(let i=0;i<n;i++)document.getElementById('wxB').click()},k=='wind'?2:2);
await p.waitForTimeout(1300);const ph=await (await p.$('#ph')).boundingBox();await p.screenshot({path:`z-${k}.png`,clip:{x:ph.x+150,y:ph.y+95,width:250,height:40}})}
await b.close()})();
