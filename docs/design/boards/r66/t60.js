// 316: on a doors page the action's object follows the door ("Add to Today" -> "Add to Body"), letter by letter; the receipt names the new door.
const {chromium}=require('/opt/node22/lib/node_modules/playwright');
const look=process.argv[2]||'paper',room=process.argv[3]||'training';
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage({viewport:{width:1300,height:1000}});
const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(2000);
if(look==='black'){await p.click('#lk-black')}await p.evaluate(r=>{scrollTo(0,0);reset('home');go(r);setTimeout(()=>go('l1_'+r,{door:0}),1500)},room);await p.waitForTimeout(4000);
const ph=await (await p.$('#phone')).boundingBox();const K=ph.width/402;
const st=()=>p.evaluate(()=>{const a=current.querySelector('.act');return JSON.stringify(a.querySelector('.av').textContent)+' '+JSON.stringify(a.querySelector('.ao').textContent)+' door '+JSON.stringify(current.querySelector('.ldt b').textContent)});
const out=['start '+await st()];const t=await (await p.$('#phone .ldt')).boundingBox();const ab=await (await p.$('#phone .act')).boundingBox();
const clip={x:ab.x-4,y:ab.y-6*K,width:240*K,height:ab.height+12*K};
for(let i=0;i<2;i++){await p.mouse.move(t.x+t.width*.8,t.y+t.height/2);await p.mouse.down();await p.mouse.move(t.x+t.width*.8-80*K,t.y+t.height/2,{steps:6});await p.mouse.up();
 for(const ms of [60,200,700]){await p.waitForTimeout(ms===60?60:ms===200?140:500);await p.screenshot({path:'A'+look[0]+i+'_'+ms+'.png',clip});out.push(i+' +'+ms+' '+await st())}}
await p.click('#phone .act');await p.waitForTimeout(400);out.push('receipt '+await p.evaluate(()=>{const r=current.querySelector('.receipt');return r?JSON.stringify(r.textContent):'none'}));
console.log(out.join('\n'));console.error(look,JSON.stringify(errs));await b.close()})();
