// 315: turning the door title on a doors page eases the caption instead of swapping it.
const {chromium}=require('/opt/node22/lib/node_modules/playwright');
const look=process.argv[2]||'paper',room=process.argv[3]||'training';
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage({viewport:{width:1300,height:1000}});
const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(2000);
if(look==='black'){await p.click('#lk-black')}await p.evaluate(r=>{scrollTo(0,0);reset('home');go(r);setTimeout(()=>go('l1_'+r,{door:0}),1500)},room);await p.waitForTimeout(4000);
const ph=await (await p.$('#phone')).boundingBox();const K=ph.width/402;
const caps=()=>p.evaluate(()=>[...current.querySelectorAll('.lcap')].map(c=>JSON.stringify(c.textContent)+'@'+(+getComputedStyle(c).opacity).toFixed(2)).join(' | '));
const out=['start '+await caps()];const t=await (await p.$('#phone .ldt')).boundingBox();const c=await (await p.$('#phone .lcap')).boundingBox();
const clip={x:ph.x,y:c.y-6*K,width:ph.width,height:c.height+12*K};
for(let i=0;i<2;i++){await p.mouse.move(t.x+t.width*.8,t.y+t.height/2);await p.mouse.down();await p.mouse.move(t.x+t.width*.8-80*K,t.y+t.height/2,{steps:6});await p.mouse.up();
 for(const ms of [40,160,400]){await p.waitForTimeout(ms===40?40:ms===160?120:240);await p.screenshot({path:'P'+look[0]+i+'_'+ms+'.png',clip});out.push(i+' +'+ms+' '+await caps())}}
console.log(out.join('\n'));console.error(look,JSON.stringify(errs));await b.close()})();
