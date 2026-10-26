const { chromium } = require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium-1194/chrome-linux/chrome'});
const ctx=await b.newContext({viewport:{width:1920,height:760},deviceScaleFactor:1,recordVideo:{dir:__dirname+'/vidn',size:{width:1920,height:760}}});
const p=await ctx.newPage();p.on('pageerror',e=>console.log('ERR',e.message));
await p.addInitScript('window.ZOOM=1.1');
await p.goto('file://'+__dirname+'/marks3.html');await p.waitForTimeout(14500);await ctx.close();await b.close()})();
