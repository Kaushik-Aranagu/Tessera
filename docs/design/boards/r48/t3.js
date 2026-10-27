const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage({viewport:{width:1100,height:900}});const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(1000);
await p.locator('#ph').screenshot({path:'c0.png'});
const r=await (await p.$('#dial')).boundingBox();await p.mouse.move(r.x+150,r.y+120);await p.mouse.down();await p.mouse.move(r.x+150,r.y+50,{steps:8});await p.mouse.up();await p.waitForTimeout(800);
await p.locator('#ph').screenshot({path:'c1.png'});await p.click('#list [data-r]');await p.waitForTimeout(600);await p.click('#planL');await p.waitForTimeout(600);await p.locator('#ph').screenshot({path:'c2.png'});console.log(errs);await b.close()})();
