const {chromium}=require('/opt/node22/lib/node_modules/playwright');(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
const p=await b.newPage({viewport:{width:1100,height:860},deviceScaleFactor:1});await p.goto('file://'+__dirname+'/index.html');await p.waitForTimeout(1800);
const ph=p.locator('#phone');const bb=await ph.boundingBox();
await p.click('[data-d=tap]');const t0=Date.now();for(const ms of [40,120,220,380,600,1000]){while(Date.now()-t0<ms)await p.waitForTimeout(5);await p.screenshot({path:`${__dirname}/op${ms}.png`,clip:{x:bb.x,y:bb.y+bb.height-330,width:bb.width,height:330}})}
await b.close()})()
