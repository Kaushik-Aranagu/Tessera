const {chromium}=require('/opt/node22/lib/node_modules/playwright');(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
const p=await b.newPage({viewport:{width:1100,height:860},deviceScaleFactor:2});const e=[];p.on('pageerror',x=>e.push(x.message));
await p.goto('file://'+__dirname+'/index.html');await p.waitForTimeout(1500);const h=await p.locator('#hit').boundingBox();
for(let k=0;k<6;k++){await p.screenshot({path:__dirname+`/l${k}.png`,clip:{x:h.x-30,y:h.y-30,width:h.width+60,height:h.height+60}});await p.waitForTimeout(700)}
await p.click('[data-d=tap]');await p.waitForTimeout(400);await p.locator('#sugg button').first().click();await p.waitForTimeout(1500);
const h2=await p.locator('#hit').boundingBox();await p.screenshot({path:__dirname+'/l6.png',clip:{x:h2.x-30,y:h2.y-30,width:h2.width+60,height:h2.height+60}});
console.log(e);await b.close()})()
