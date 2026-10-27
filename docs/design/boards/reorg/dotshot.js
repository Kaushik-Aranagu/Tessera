const { chromium } = require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium-1194/chrome-linux/chrome'});
const p=await b.newPage({viewport:{width:1620,height:640}});p.on('pageerror',e=>console.log('ERR',e.message));
for(const t of [1.6,3.4]){await p.addInitScript(`window.FREEZE=${t}`);await p.goto('file://'+__dirname+'/dots.html');await p.waitForTimeout(200);await p.screenshot({path:__dirname+'/d_'+t+'.png'});}
await b.close()})();
