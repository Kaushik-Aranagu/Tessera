// 311: shape mode spreads from the held Nav word and gathers back to it. Pane opacities by frame, nearest first.
const {chromium}=require('/opt/node22/lib/node_modules/playwright');
const look=process.argv[2]||'paper',room=process.argv[3]||'training';
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage({viewport:{width:1300,height:1000}});
const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(2000);
if(look==='black'){await p.click('#lk-black')}await p.evaluate(r=>{scrollTo(0,0);reset('home');go(r)},room);await p.waitForTimeout(3000);
const ph=await (await p.$('#phone')).boundingBox();
const st=()=>p.evaluate(()=>[...current.querySelectorAll(':scope > .shp')].sort((a,b)=>a._d-b._d).map(e=>e.dataset.k+'('+Math.round(e._d)+')='+(+getComputedStyle(e).opacity).toFixed(2)).join(' '));
const out=[];const shot=async n=>{await p.screenshot({path:'G'+look[0]+n+'.png',clip:ph});out.push(n+': '+await st())};
await p.evaluate(r=>__shape.on(r),room);let t0=0;for(const t of [60,150,260,700]){await p.waitForTimeout(t-t0);t0=t;await shot('on'+t)}
await p.evaluate(r=>__shape.off(r),room);t0=0;for(const t of [30,90,160,600]){await p.waitForTimeout(t-t0);t0=t;await shot('off'+t)}
console.log(out.join('\n'));console.error(look,JSON.stringify(errs));await b.close()})();
