// 312: a room's door pages keep the masthead; only the Nav word changes its letters. Exact frames via paused animations.
const {chromium}=require('/opt/node22/lib/node_modules/playwright');
const look=process.argv[2]||'paper',room=process.argv[3]||'training';
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage({viewport:{width:1300,height:1000}});
const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(2000);
if(look==='black'){await p.click('#lk-black')}await p.evaluate(r=>{scrollTo(0,0);reset('home');go(r)},room);await p.waitForTimeout(3000);
const ph=await (await p.$('#phone')).boundingBox();const K=ph.width/402;const clip={x:ph.x,y:ph.y+44*K,width:ph.width,height:64*K};
const st=()=>p.evaluate(()=>{const t=[...document.querySelectorAll('#phone .ltop')];return t.length+' masthead(s); title '+t.map(x=>{const a=x.getAnimations().length+[...x.querySelectorAll('.ttl')].reduce((n,e)=>n+e.getAnimations().length,0);return JSON.stringify(x.querySelector('.ttl').textContent)+(a?' MOVES':' still')}).join(',')+'; nav '+[...document.querySelectorAll('#phone .lnav')].map(n=>JSON.stringify(n.textContent)).join(',')});
const out=[];const step=async(n,f)=>{await p.evaluate(f);await p.waitForTimeout(30);out.push(n+' +30: '+await st());await p.screenshot({path:'M'+look[0]+n+'.png',clip});await p.waitForTimeout(1500);out.push(n+' end: '+await st())};
await step('open',()=>go('l1_'+current.dataset.id,{door:0}));
await step('deeper',()=>go('l2_'+current.dataset.id.slice(3),{door:0}));
await step('back1',()=>back());await step('back2',()=>back());
await step('room',()=>{reset('home');go('kitchen')});
console.log(out.join('\n'));console.error(look,JSON.stringify(errs));await b.close()})();
