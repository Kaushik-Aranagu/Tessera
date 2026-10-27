const {chromium}=require('/opt/node22/lib/node_modules/playwright');(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
const p=await b.newPage({viewport:{width:1100,height:900},deviceScaleFactor:2});const e=[];p.on('pageerror',x=>e.push(x.message));await p.goto('file://'+__dirname+'/index.html');await p.waitForTimeout(1200);
for(const pl of ['lagoon','dusk','ember']){await p.click('[data-p='+pl+']');for(const l of ['white','black']){await p.click('[data-l='+l+']');for(let i=0;i<2;i++){await p.waitForTimeout(1400);const h=await p.locator('#hit').boundingBox();await p.screenshot({path:`${__dirname}/pc-${pl}-${l}${i}.png`,clip:{x:h.x+h.width/2-80,y:h.y+h.height/2-80,width:160,height:160}})}}}
console.log(e);await b.close()})()
