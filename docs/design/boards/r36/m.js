const {chromium}=require('/opt/node22/lib/node_modules/playwright');(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
const p=await b.newPage({viewport:{width:1100,height:860},deviceScaleFactor:3});const e=[];p.on('pageerror',x=>e.push(x.message));await p.goto('file://'+__dirname+'/index.html');await p.waitForTimeout(1800);
const shot=async n=>{const h=await p.locator('#hit').boundingBox();await p.screenshot({path:`${__dirname}/m-${n}.png`,clip:{x:h.x+h.width/2-45,y:h.y+h.height/2-45,width:90,height:90}})};
await shot('idle');await p.click('[data-d=tap]');await p.waitForTimeout(650);await shot('talk');await p.waitForTimeout(3500);
await p.locator('#sugg button').first().click();await p.waitForTimeout(420);await shot('think');await p.waitForTimeout(700);await shot('talk2');await p.waitForTimeout(500);await shot('smile');
const h=await p.locator('#hit').boundingBox();await p.mouse.move(h.x+42,h.y+42);await p.mouse.down();await p.waitForTimeout(140);await shot('oh');await p.mouse.up();
console.log(e);await b.close()})()
