// 304: the first drops are few. Lookout in rain, frames at 0.2 s, 1.5 s and 3.5 s.
const {chromium}=require('/opt/node22/lib/node_modules/playwright');
const look=process.argv[2]||'paper';
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage({viewport:{width:1300,height:1000}});
const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(2000);
if(look==='black'){await p.click('#lk-black')}await p.evaluate(()=>{scrollTo(0,0);reset('home');go('weatherhour',{h:'8 PM',t:58,w:'Rain'})});
const ph=await (await p.$('#phone')).boundingBox();const fs=[];let last=0;
for(const t of [200,1500,3500]){await p.waitForTimeout(t-last);last=t;const f='R'+look[0]+t+'.png';await p.screenshot({path:f,clip:{x:ph.x,y:ph.y,width:ph.width,height:ph.height}});fs.push(f)}
console.log(fs.join(' '));console.error(look,JSON.stringify(errs));await b.close()})();
