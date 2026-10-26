const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage({viewport:{width:1100,height:900}});p.on('pageerror',e=>console.log('ERR',e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(800);
const r=await (await p.$('#pan .row2')).boundingBox();console.log(r);const top=await p.evaluate(([x,y])=>{const e=document.elementFromPoint(x,y);return e.id+'|'+e.className+'|'+e.textContent.slice(0,20)},[r.x+5,r.y+12]);console.log(top);await b.close()})();
