const { chromium } = require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium-1194/chrome-linux/chrome'});
const p=await b.newPage({viewport:{width:390,height:844}});p.on('pageerror',e=>console.log('ERR',e.message));
for(const [n,t] of [['a',0],['b',1.9],['c',2.9]]){await p.addInitScript(`window.FREEZE=${t}`);await p.goto('file://'+__dirname+'/sample2.html');await p.waitForTimeout(300);await p.screenshot({path:__dirname+'/s_'+n+'.png'});}
await b.close()})();
