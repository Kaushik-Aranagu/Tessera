// 307: Undo rewinds its own line. Frames after tapping Undo, then the action word is back and the line is empty.
const {chromium}=require('/opt/node22/lib/node_modules/playwright');
const look=process.argv[2]||'paper',demo=process.argv[3]||'galley-you',room=process.argv[4]||'kitchen';
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage({viewport:{width:1300,height:1000}});
const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(2000);
if(look==='black'){await p.click('#lk-black')}await p.evaluate(r=>{scrollTo(0,0);reset('home');go(r)},room);await p.waitForTimeout(3000);
await p.evaluate(d=>window.__th(d),demo);await p.waitForTimeout(2200);
const ph=await (await p.$('#phone')).boundingBox();const K=ph.width/402;const clip={x:ph.x,y:ph.y+780*K,width:ph.width,height:60*K};
await p.screenshot({path:'U'+look[0]+'0.png',clip});const fs=['U'+look[0]+'0.png'];
await p.evaluate(()=>current.querySelector('.undoline button').click());let last=0;
for(const t of [60,130,200,320,600]){await p.waitForTimeout(t-last);last=t;const f='U'+look[0]+t+'.png';await p.screenshot({path:f,clip});fs.push(f)}
const st=await p.evaluate(()=>{const u=current.querySelector('.undoline'),a=current.querySelector('.act');return 'line "'+u.textContent+'" act '+(a?getComputedStyle(a).visibility+' '+getComputedStyle(a).opacity:'none')});
console.log(fs.join(' '));console.error(look,demo,st,JSON.stringify(errs));await b.close()})();
