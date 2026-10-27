// 298: a ticket hangs: the rail makes room, then the ticket drops in at full width.
const {chromium}=require('/opt/node22/lib/node_modules/playwright');
const look=process.argv[2]||'paper';
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage({viewport:{width:1300,height:1000}});
const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(2000);
if(look==='black'){await p.click('#lk-black');await p.evaluate(()=>scrollTo(0,0))}
await p.evaluate(()=>{reset('home');go('kitchen')});await p.waitForTimeout(4000);const ph=await (await p.$('#phone')).boundingBox();
const r=await p.evaluate(()=>{const e=current.querySelector('.pass').getBoundingClientRect();return {y:e.top,h:e.height}});
await p.evaluate(()=>window.__th('galley-you'));const fs=[];let last=0;
for(const t of [100,250,400,550,750,1100]){await p.waitForTimeout(t-last);last=t;const f='H'+look[0]+t+'.png';await p.screenshot({path:f,clip:{x:ph.x,y:r.y,width:ph.width,height:r.h}});fs.push(f)}
console.log(fs.join(' '));console.error(look,JSON.stringify(errs));await b.close()})();
