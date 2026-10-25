const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
const p=await b.newPage({viewport:{width:1100,height:900},colorScheme:'light'});
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(2500);
const ph=await (await p.$('#ph')).boundingBox();
console.log(await p.evaluate(([x,y])=>document.elementsFromPoint(x,y).slice(0,4).map(e=>e.id+'.'+e.className+' '+getComputedStyle(e).backgroundColor),[ph.x+60,ph.y+130]));
await p.locator('#ph').screenshot({path:'c4.png'});await b.close()})();
