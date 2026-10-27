const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage({viewport:{width:1100,height:900},colorScheme:'dark'});
await p.goto('file://'+process.cwd()+'/index.html',{waitUntil:'networkidle'});await p.waitForTimeout(1200);
// get into mid workout with sets done
await p.click('#start');await p.waitForTimeout(800);await p.click('#go');await p.waitForTimeout(800);
const ev=async()=>p.evaluate(()=>0);
for(let k=0;k<3;k++){await p.click('#go');await p.waitForTimeout(2600);if(k<2){await p.click('#go');await p.waitForTimeout(900)}}
await p.waitForTimeout(1200);await p.click('#go');await p.waitForTimeout(2600);
await p.keyboard.press('Escape');await p.waitForTimeout(900);
for(const k of ['soft','moon','deep','now']){await p.click(`#dk [data-p="${k}"]`);await p.waitForTimeout(300);await p.locator('#ph').screenshot({path:`p-${k}.png`})}
await p.click('#start');await p.waitForTimeout(900);await p.click('#dk [data-p="soft"]');await p.waitForTimeout(300);await p.locator('#ph').screenshot({path:'p-work.png'});
await p.click('#tw');await p.waitForTimeout(300);await p.locator('#ph').screenshot({path:'p-light.png'});
await b.close()})();
