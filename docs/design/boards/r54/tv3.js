const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
for(const sch of ['light','dark']){const p=await b.newPage({viewport:{width:1100,height:900},colorScheme:sch});const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(1200);
const s=async n=>{await p.waitForTimeout(700);await p.locator('#ph').screenshot({path:`v${n}-${sch}.png`})};
await s(0);
await p.click('.door[data-d="today"]');await s(1);await p.keyboard.press('Escape');await p.waitForTimeout(500);
await p.click('.door[data-d="Mornings"]');await s(2);await p.click('#cWheel .wr[data-i="1"]',{force:true});await s(3);await p.keyboard.press('Escape');await p.waitForTimeout(500);
await p.click('.door[data-d="Borrowed"]');await s(4);
await p.click('#cGo');await s(5);await p.click('.brr');await s(6);await p.keyboard.press('Escape');await p.waitForTimeout(500);
await p.click('#hGo');await p.waitForTimeout(600);await p.keyboard.type('Sunday plan');await p.click('.mkS[data-s="steps"]');await p.keyboard.type('Look at the week');await p.keyboard.press('Enter');await p.keyboard.type('Pick three things');await s(7);
await p.click('#mkGo');await s(8);
console.log(sch,errs)}
await b.close()})();
