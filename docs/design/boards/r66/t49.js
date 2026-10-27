// 305: chalk dust as a line is written on the Deck. Frames of the writing tip.
const {chromium}=require('/opt/node22/lib/node_modules/playwright');
const look=process.argv[2]||'paper';
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage({viewport:{width:1300,height:1000},deviceScaleFactor:2});
const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(2000);
if(look==='black'){await p.click('#lk-black')}await p.evaluate(()=>{scrollTo(0,0);reset('home');go('training')});await p.waitForTimeout(3000);
const ph=await (await p.$('#phone')).boundingBox();const K=ph.width/402;const clip={x:ph.x+14*K,y:ph.y+312*K,width:250*K,height:32*K};
await p.evaluate(()=>window.__th('deck-you'));const fs=[];let last=0;
for(const t of [300,500,700,900,1400]){await p.waitForTimeout(t-last);last=t;const f='D'+look[0]+t+'.png';await p.screenshot({path:f,clip});fs.push(f)}
console.log(fs.join(' '));console.error(look,JSON.stringify(errs));await b.close()})();
