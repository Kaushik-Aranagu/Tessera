const {chromium}=require('/opt/node22/lib/node_modules/playwright');(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
const p=await b.newPage({viewport:{width:1100,height:900},deviceScaleFactor:2});const e=[];p.on('pageerror',x=>e.push(x.message));await p.goto('file://'+__dirname+'/index.html');await p.click('[data-l=white]');
for(const ms of [2000,6500,7500,9000,16000]){await p.waitForTimeout(ms-(await p.evaluate(()=>performance.now())));const h=await p.locator('#hit').boundingBox();await p.screenshot({path:`${__dirname}/v-${ms}.png`,clip:{x:h.x+h.width/2-80,y:h.y+h.height/2-80,width:160,height:160}})}
console.log(e);await b.close()})()
