const { chromium } = require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium-1194/chrome-linux/chrome'});
const ctx=await b.newContext({viewport:{width:1280,height:900},recordVideo:{dir:__dirname+'/vids3',size:{width:1280,height:900}}});
const p=await ctx.newPage();p.on('pageerror',e=>console.log('ERR',e.message));
await p.addInitScript('window.ZOOM=1.15');
await p.goto('file://'+__dirname+'/swarm3.html');await p.waitForTimeout(30500);await ctx.close();await b.close()})();
