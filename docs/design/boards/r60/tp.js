const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage({viewport:{width:1000,height:1000}});
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(1500);const ph=(await p.$$('.phone'))[4];await ph.scrollIntoViewIfNeeded();
await p.click('#away');await p.waitForTimeout(500);await ph.screenshot({path:'pile0.png'});await p.waitForTimeout(700);await ph.screenshot({path:'pile1.png'});await p.waitForTimeout(1500);await ph.screenshot({path:'pile2.png'});
const sk=await p.$$('.sk');await sk[0].scrollIntoViewIfNeeded();await p.waitForTimeout(300);for(let i=0;i<8;i++){await sk[i].scrollIntoViewIfNeeded();await p.waitForTimeout(400);await sk[i].screenshot({path:`s${i}.png`})}await b.close()})();
