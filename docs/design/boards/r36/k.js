const {chromium}=require('/opt/node22/lib/node_modules/playwright');(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
const p=await b.newPage({viewport:{width:1100,height:900},deviceScaleFactor:2});const e=[];p.on('pageerror',x=>e.push(x.message));await p.goto('file://'+__dirname+'/index.html');await p.waitForTimeout(1200);
await p.click('[data-d=tap]');await p.waitForTimeout(900);await p.keyboard.type('add eggs');await p.keyboard.down('Shift');await p.keyboard.press('Enter');await p.keyboard.up('Shift');await p.keyboard.type('and milk');await p.waitForTimeout(200);
console.log(JSON.stringify(await p.locator('#fask').inputValue()));await p.locator('#phone').screenshot({path:__dirname+'/k-type.png'});
await p.keyboard.press('Enter');await p.waitForTimeout(300);console.log(JSON.stringify(await p.locator('#fask').inputValue()));
await p.click('[data-d=hold]');await p.waitForTimeout(1300);const h=await p.locator('#hit').boundingBox();await p.screenshot({path:__dirname+'/k-hear.png',clip:{x:h.x+h.width/2-90,y:h.y+h.height/2-90,width:180,height:180}});
for(const t of ['bright','light','evening','night']){await p.click('[data-t='+t+']');await p.waitForTimeout(500);const h=await p.locator('#hit').boundingBox();await p.screenshot({path:`${__dirname}/k-${t}.png`,clip:{x:h.x+h.width/2-90,y:h.y+h.height/2-90,width:180,height:180}})}
console.log(e);await b.close()})()
