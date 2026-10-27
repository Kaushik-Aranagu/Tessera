// 300: the drawn tick. Check "The adapter" on Trip packing and grab frames; then uncheck it.
const {chromium}=require('/opt/node22/lib/node_modules/playwright');
const look=process.argv[2]||'paper';
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage({viewport:{width:1300,height:1000},deviceScaleFactor:2});
const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(2000);
if(look==='black'){await p.click('#lk-black')}await p.evaluate(()=>{scrollTo(0,0);reset('home');go('notes');setTimeout(()=>go('l2_notes',{door:0,row:'Trip packing'}),1500)});await p.waitForTimeout(4200);
const r=await p.evaluate(()=>{const e=[...current.querySelectorAll('.lbc')].find(x=>x.textContent==='The adapter');if(!e)return null;const q=e.getBoundingClientRect();return {x:q.left,y:q.top,w:q.width,h:q.height}});
if(!r){console.log('no row',JSON.stringify(errs));await b.close();return}
const clip={x:r.x-6,y:r.y-4,width:60,height:r.h+8};const fs=[];
await p.evaluate(()=>{const e=[...current.querySelectorAll('.lbc')].find(x=>x.textContent==='The adapter');e.click();document.getAnimations().forEach(a=>{if(a.effect&&a.effect.target&&a.effect.target.closest&&a.effect.target.closest('.lbc'))a.pause()})});
for(const t of [0,40,80,120,160]){await p.evaluate(t=>document.getAnimations().forEach(a=>{if(a.playState==='paused')a.currentTime=Math.min(t,a.effect.getComputedTiming().endTime-1)}),t);const f='C'+look[0]+t+'.png';await p.screenshot({path:f,clip});fs.push(f)}
await p.evaluate(()=>document.getAnimations().forEach(a=>{if(a.playState==='paused')a.play()}));await p.waitForTimeout(300);
await p.mouse.click(r.x+40,r.y+r.h/2);await p.waitForTimeout(80);await p.screenshot({path:'C'+look[0]+'u80.png',clip});await p.waitForTimeout(300);await p.screenshot({path:'C'+look[0]+'u380.png',clip});fs.push('C'+look[0]+'u80.png','C'+look[0]+'u380.png');
console.log(fs.join(' '));console.error(look,JSON.stringify(errs));await b.close()})();
