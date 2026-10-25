const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
const p=await b.newPage({viewport:{width:1100,height:1000},colorScheme:'light',deviceScaleFactor:2});
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(2500);const ph=await (await p.$('#ph')).boundingBox();
await p.screenshot({path:'mlight.png',clip:{x:ph.x,y:ph.y+40,width:ph.width,height:ph.height*.55}});await b.close()})();
