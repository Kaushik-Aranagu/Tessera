const { chromium } = require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium-1194/chrome-linux/chrome'});
const p=await b.newPage({viewport:{width:1740,height:640}});p.on('pageerror',e=>console.log('ERR',e.message));
for(const t of [1.8,4.6,6.9,10.2]){await p.addInitScript(`window.FREEZE=${t}`);await p.goto('file://'+__dirname+'/marks3.html');await p.waitForTimeout(200);await p.screenshot({path:__dirname+'/m_'+t+'.png'});}
await b.close()})();
