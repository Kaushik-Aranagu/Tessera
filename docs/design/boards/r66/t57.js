// 313: the routine's header counts down. Check each step; frames of the header; ends whole; no stops.
const {chromium}=require('/opt/node22/lib/node_modules/playwright');
const look=process.argv[2]||'paper',id=process.argv[3]||'stretch';
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage({viewport:{width:1300,height:1000}});
const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(2000);
if(look==='black'){await p.click('#lk-black')}await p.evaluate(id=>{scrollTo(0,0);reset('home');go('routine',{id})},id);await p.waitForTimeout(2500);
const ph=await (await p.$('#phone')).boundingBox();
const hdr=()=>p.evaluate(()=>{const e=current.querySelector('.pane').firstElementChild;const r=e.getBoundingClientRect();return {t:e.textContent,n:e.querySelectorAll('.nr').length,x:r.x,y:r.y,w:r.width}});
const out=[];let k=0;
for(let i=0;i<6;i++){const h0=await hdr();if(/^All/.test(h0.t))break;const K=ph.width/402;const clip={x:h0.x-4,y:h0.y-14*K,width:260*K,height:44*K};
 await p.click('#phone .foot');await p.waitForTimeout(640);for(const t of [0,90,200,500]){if(t)await p.waitForTimeout(t-(t===500?200:t===200?90:0));const f='C'+look[0]+i+'_'+t+'.png';await p.screenshot({path:f,clip});const h1=await hdr();out.push(i+' +'+t+': "'+h1.t+'" rolling='+h1.n)}}
out.push('end "'+(await hdr()).t+'"');console.log(out.join('\n'));console.error(look,JSON.stringify(errs));await b.close()})();
