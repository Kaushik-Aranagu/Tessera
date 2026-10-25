const { chromium } = require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium-1194/chrome-linux/chrome'});
const p=await b.newPage({viewport:{width:1100,height:760}});p.on('pageerror',e=>console.log('ERR',e.message));
for(const t of [1.5,3.4,5.4,6.2,11,16,21,24.5]){await p.addInitScript(`window.FREEZE=${t}`);await p.goto('file://'+__dirname+'/swarm4.html');await p.waitForTimeout(150);await p.screenshot({path:__dirname+'/z_'+t+'.png',clip:{x:0,y:0,width:440,height:760}});}
await b.close()})();
