// 299: ink goes last. Frames of a look change: the ground turns first, the ink follows.
const {chromium}=require('/opt/node22/lib/node_modules/playwright');
const [,,room='kitchen',to='black']=process.argv;
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage({viewport:{width:1300,height:1000}});
const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(2000);
if(to==='paper'){await p.click('#lk-black')}await p.evaluate(r=>{scrollTo(0,0);reset('home');if(r!=='home')go(r)},room);await p.waitForTimeout(3500);
const ph=await p.$('#phone');const fs=[];await p.click('#lk-'+to);let last=0;
for(const t of [20,70,130,200,300,600]){await p.waitForTimeout(t-last);last=t;const f='I'+room+to[0]+t+'.png';await ph.screenshot({path:f});fs.push(f)}
const n=await p.evaluate(()=>document.querySelectorAll('#phone .screen').length);
console.log(fs.join(' '));console.error(room,to,'screens',n,JSON.stringify(errs));await b.close()})();
