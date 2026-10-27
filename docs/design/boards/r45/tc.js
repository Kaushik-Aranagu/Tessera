const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage({viewport:{width:1100,height:900},colorScheme:'dark'});const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html',{waitUntil:'networkidle'});await p.waitForTimeout(1000);
await p.click('#start');await p.waitForTimeout(800);await p.click('#go');await p.waitForTimeout(800);await p.click('#go');await p.waitForTimeout(2300);
await p.locator('#ph').screenshot({path:'cf0.png'});await p.click('#cfM');await p.waitForTimeout(600);await p.locator('#ph').screenshot({path:'cf1.png'});
await p.waitForTimeout(5300);await p.locator('#ph').screenshot({path:'cf2.png'});await p.keyboard.press('Escape');await p.waitForTimeout(900);await p.locator('#ph').screenshot({path:'cf3.png'});console.log(errs);await b.close()})();
