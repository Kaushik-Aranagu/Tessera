const { chromium } = require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium-1194/chrome-linux/chrome'});
const ctx=await b.newContext({viewport:{width:780,height:1688},deviceScaleFactor:1,recordVideo:{dir:__dirname+'/vid',size:{width:780,height:1688}}});
const p=await ctx.newPage();p.on('pageerror',e=>console.log('ERR',e.message));
await p.addInitScript('window.ZOOM=2');
await p.goto('file://'+__dirname+'/sample2.html');await p.waitForTimeout(9500);await ctx.close();await b.close()})();
