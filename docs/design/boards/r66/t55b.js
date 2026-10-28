// 311 frames: pause every pane animation and seek, so each frame is exact.
const {chromium}=require('/opt/node22/lib/node_modules/playwright');
const look=process.argv[2]||'paper',room=process.argv[3]||'training';
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage({viewport:{width:1300,height:1000}});
const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(2000);
if(look==='black'){await p.click('#lk-black')}await p.evaluate(r=>{scrollTo(0,0);reset('home');go(r)},room);await p.waitForTimeout(3000);
const ph=await (await p.$('#phone')).boundingBox();
const seek=t=>p.evaluate(t=>{const ps=[...current.querySelectorAll(':scope > .shp')];ps.forEach(e=>e.getAnimations().forEach(a=>{a.pause();a.currentTime=t}));
 return ps.sort((a,b)=>a._d-b._d).map(e=>e.dataset.k+'='+(+getComputedStyle(e).opacity).toFixed(2)).join(' ')},t);
const out=[];await p.evaluate(r=>__shape.on(r),room);
for(const t of [0,80,160,260,420]){out.push('on'+t+': '+await seek(t));await p.screenshot({path:'G'+look[0]+'on'+t+'.png',clip:ph})}
await seek(2000);await p.evaluate(()=>current.querySelectorAll(':scope > .shp').forEach(e=>e.getAnimations().forEach(a=>a.finish())));
await p.evaluate(r=>__shape.off(r),room);
for(const t of [0,60,120,200]){out.push('off'+t+': '+await seek(t));await p.screenshot({path:'G'+look[0]+'off'+t+'.png',clip:ph})}
console.log(out.join('\n'));console.error(look,JSON.stringify(errs));await b.close()})();
