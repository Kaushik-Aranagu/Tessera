// 309: the Nav word morphs to Done and back. Frames of the masthead corner; text ends clean.
const {chromium}=require('/opt/node22/lib/node_modules/playwright');
const look=process.argv[2]||'paper',room=process.argv[3]||'training';
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage({viewport:{width:1300,height:1000}});
const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(2000);
if(look==='black'){await p.click('#lk-black')}await p.evaluate(r=>{scrollTo(0,0);reset('home');go(r)},room);await p.waitForTimeout(3000);
const ph=await (await p.$('#phone')).boundingBox();const K=ph.width/402;const clip={x:ph.x+250*K,y:ph.y+50*K,width:152*K,height:56*K};
const st=()=>p.evaluate(()=>{const n=current.querySelector('.lnav');return JSON.stringify(n.textContent)+' spans='+n.children.length});
const out=[],fs=[];const shot=async n=>{const f='N'+look[0]+room[0]+n+'.png';await p.screenshot({path:f,clip});fs.push(f);out.push(n+': '+await st())};
await shot('0');await p.evaluate(r=>__shape.on(r),room);let t0=0;
for(const t of [40,100,170,260,600]){await p.waitForTimeout(t-t0);t0=t;await shot('on'+t)}
// quick toggle mid-morph must not leak ghost letters
await p.evaluate(r=>__shape.off(r),room);await p.waitForTimeout(60);await p.evaluate(r=>__shape.on(r),room);await p.waitForTimeout(40);await p.evaluate(r=>__shape.off(r),room);
t0=0;for(const t of [100,200,700]){await p.waitForTimeout(t-t0);t0=t;await shot('off'+t)}
console.log(out.join('\n'));console.error(look,room,JSON.stringify(errs));await b.close()})();
