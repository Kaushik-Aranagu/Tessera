const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
for(const sch of ['light','dark']){const p=await b.newPage({viewport:{width:1100,height:1000},colorScheme:sch,deviceScaleFactor:2});const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(1500);
for(let i=0;i<4;i++){await p.click('#wxB');await p.waitForTimeout(900);const ph=await (await p.$('#ph')).boundingBox();await p.screenshot({path:`w${i}-${sch}.png`,clip:{x:ph.x+150,y:ph.y+70,width:250,height:130}})}
console.log(sch,errs)}
await b.close()})();
