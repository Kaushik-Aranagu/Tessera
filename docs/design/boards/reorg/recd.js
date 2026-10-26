const { chromium } = require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium-1194/chrome-linux/chrome'});
const ctx=await b.newContext({viewport:{width:1900,height:760},recordVideo:{dir:__dirname+'/vidd',size:{width:1900,height:760}}});
const p=await ctx.newPage();p.on('pageerror',e=>console.log('ERR',e.message));
await p.addInitScript('window.ZOOM=1.17');
await p.goto('file://'+__dirname+'/dots.html');await p.waitForTimeout(13500);await ctx.close();await b.close()})();
