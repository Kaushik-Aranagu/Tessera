const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage({viewport:{width:1100,height:900}});const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html',{waitUntil:'networkidle'});await p.waitForTimeout(1200);
const bb=await (await p.$$('#list .rc'))[0].boundingBox();await p.mouse.click(bb.x+20,bb.y+22);await p.waitForTimeout(800);await p.locator('#ph').screenshot({path:'b0.png'});
await p.click('#putGo');await p.waitForTimeout(1200);await p.locator('#ph').screenshot({path:'b1.png'});
const b2=await (await p.$$('#list .rc'))[0].boundingBox();await p.mouse.move(b2.x+20,b2.y+22);await p.mouse.down();await p.mouse.move(b2.x+160,b2.y+22,{steps:8});await p.mouse.up();await p.waitForTimeout(900);await p.locator('#ph').screenshot({path:'b2.png'});
console.log(errs);await b.close()})();
