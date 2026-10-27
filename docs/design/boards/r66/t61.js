// 317: on a door page, swiping to the next item rolls only the facts that changed, and the action names the item shown.
const {chromium}=require('/opt/node22/lib/node_modules/playwright');
const look=process.argv[2]||'paper',room=process.argv[3]||'training';
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage({viewport:{width:1300,height:1000}});
const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(2000);
if(look==='black'){await p.click('#lk-black')}await p.evaluate(r=>{scrollTo(0,0);reset('home');go(r);setTimeout(()=>go('l1_'+r,{door:0}),1200);setTimeout(()=>go('l2_'+r,{door:0}),2600)},room);await p.waitForTimeout(5000);
const ph=await (await p.$('#phone')).boundingBox();const K=ph.width/402;
const st=()=>p.evaluate(()=>{const f=[...current.querySelectorAll('.lfx > div')].map(d=>d.textContent).join(' / ');const a=current.querySelector('.act .ao');return 'item '+JSON.stringify(current.querySelector('.ldt b').textContent)+' facts ['+f+'] act '+JSON.stringify(a&&a.textContent)+' rolling '+current.querySelectorAll('.lfx .nr').length});
const out=['start '+await st()];const t=await (await p.$('#phone .ldt')).boundingBox();const fx=await (await p.$('#phone .lfx')).boundingBox();
const clip={x:ph.x,y:fx.y-8*K,width:ph.width,height:fx.height+16*K};
for(let i=0;i<3;i++){await p.mouse.move(t.x+t.width*.8,t.y+t.height/2);await p.mouse.down();await p.mouse.move(t.x+t.width*.8-80*K,t.y+t.height/2,{steps:6});await p.mouse.up();
 for(const ms of [60,180,700]){await p.waitForTimeout(ms===60?60:ms===180?120:520);await p.screenshot({path:'I'+look[0]+i+'_'+ms+'.png',clip});out.push(i+' +'+ms+' '+await st())}}
await p.click('#phone .act');await p.waitForTimeout(400);out.push('receipt '+await p.evaluate(()=>{const r=current.querySelector('.receipt');return r?JSON.stringify(r.textContent):'none'}));
console.log(out.join('\n'));console.error(look,JSON.stringify(errs));await b.close()})();
