const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage({viewport:{width:1100,height:900}});const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(1200);await p.click('#dLib');await p.waitForTimeout(700);
const vis=()=>p.evaluate(()=>[...document.querySelectorAll('#ph > div:not([hidden])')].map(e=>e.id).join(','));
await p.getByText('Push B',{exact:true}).first().click();await p.waitForTimeout(700);console.log('after 1 tap',await vis());
await p.getByText('Push B',{exact:true}).first().click();await p.waitForTimeout(900);console.log('after 2 taps',await vis());await p.locator('#ph').screenshot({path:'L5.png'});
await p.keyboard.press('Escape');await p.waitForTimeout(600);
await p.getByText('Push A',{exact:true}).first().click();await p.waitForTimeout(900);console.log('push A',await vis(),errs);
await b.close()})();
