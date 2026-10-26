const {chromium}=require('/opt/node22/lib/node_modules/playwright');(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
const p=await b.newPage({viewport:{width:1100,height:1000},deviceScaleFactor:2});const e=[];p.on('pageerror',x=>e.push(x.message));await p.goto('file://'+__dirname+'/index.html');await p.waitForTimeout(1000);
for(const l of ['white','black']){await p.click('[data-l='+l+']');for(const c of ['','training','kitchen','notes','money']){await p.click(`[data-c="${c}"]`);await p.waitForTimeout(c==='kitchen'?600:1500);const h=await p.locator('#hit').boundingBox();await p.screenshot({path:`${__dirname}/cu-${l}-${c||'home'}.png`,clip:{x:h.x+h.width/2-70,y:h.y+h.height/2-70,width:140,height:140}})}}
console.log(e);await b.close()})()
