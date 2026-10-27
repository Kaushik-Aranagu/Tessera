const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage({viewport:{width:1100,height:900},colorScheme:'light'});const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html',{waitUntil:'networkidle'});await p.waitForTimeout(1000);
const wi=(await p.$$('#plan button .wi'))[2];await wi.click();await p.waitForTimeout(800);await p.locator('#ph').screenshot({path:'ex0.png'});
await p.click('#exSet [data-k="reps"][data-d="1"]');await p.waitForTimeout(400);await p.locator('#ph').screenshot({path:'ex1.png'});
await p.keyboard.press('Escape');await p.waitForTimeout(600);await p.click('#start');await p.waitForTimeout(900);await p.click('#go');await p.waitForTimeout(900);
const w2=(await p.$$('#rest button .wi'))[1];await w2.click();await p.waitForTimeout(800);await p.click('#exSet [data-k="w"][data-d="1"]');await p.waitForTimeout(400);await p.locator('#ph').screenshot({path:'ex2.png'});
await p.keyboard.press('Escape');await p.waitForTimeout(600);await p.locator('#ph').screenshot({path:'ex3.png'});console.log(errs);await b.close()})();
