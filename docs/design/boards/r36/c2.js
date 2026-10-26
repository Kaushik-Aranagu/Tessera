const {chromium}=require('/opt/node22/lib/node_modules/playwright');(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
const p=await b.newPage({viewport:{width:1100,height:860},deviceScaleFactor:2});const e=[];p.on('pageerror',x=>e.push(x.message));
await p.goto('file://'+__dirname+'/index.html');await p.waitForTimeout(1500);
for(const l of ['white','black']){await p.click('[data-l='+l+']');for(let i=0;i<5;i++){await p.waitForTimeout(700);const h=await p.locator('#hit').boundingBox();await p.screenshot({path:`${__dirname}/c-b-${l}${i}.png`,clip:{x:h.x+h.width/2-90,y:h.y+h.height/2-90,width:180,height:180}})}}
console.log(e);await b.close()})()
