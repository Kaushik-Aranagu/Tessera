const {chromium}=require('/opt/node22/lib/node_modules/playwright');(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
for(const f of ['old','index']){const p=await b.newPage({viewport:{width:1100,height:860},deviceScaleFactor:2});await p.goto('file://'+__dirname+'/'+f+'.html');await p.waitForTimeout(1200);
for(const l of ['white','paper']){await p.click('[data-l='+l+']');for(let i=0;i<3;i++){await p.waitForTimeout(1300);const h=await p.locator('#hit').boundingBox();await p.screenshot({path:`${__dirname}/lc-${f}-${l}${i}.png`,clip:{x:h.x+h.width/2-80,y:h.y+h.height/2-80,width:160,height:160}})}}await p.close()}
await b.close()})()
