// 308: the Layout mode swipe-through. Doors follow the finger held back; the next look's word warms; short swipes spring home.
const {chromium}=require('/opt/node22/lib/node_modules/playwright');
const look=process.argv[2]||'paper';
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage({viewport:{width:1300,height:1000}});
const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(2000);
if(look==='black'){await p.click('#lk-black')}await p.evaluate(()=>{scrollTo(0,0);reset('home');go('training')});await p.waitForTimeout(3000);
await p.evaluate(()=>window.__th('shape-deck'));await p.waitForTimeout(1200);
const pane=await (await p.$('#phone .shp[data-k=dial]')).boundingBox();const ph=await (await p.$('#phone')).boundingBox();const K=ph.width/402;
const clip={x:ph.x,y:ph.y+620*K,width:ph.width,height:240*K};const cx=pane.x+pane.width*.7,cy=pane.y+pane.height/2;
const st=()=>p.evaluate(()=>{const d=current.querySelector(':scope > .dlook')||current.querySelector(':scope > .dial');const w=[...current.querySelectorAll('.shapebar [data-f]')].map(x=>x.dataset.f+':'+x.style.color.replace(/\s+/g,' ')).join(' | ');return (window.__looks.training||'reel')+' tr='+d.style.translate+' op='+d.style.opacity+' '+w});
const out=[];const shot=async n=>{await p.screenshot({path:'S'+look[0]+n+'.png',clip});out.push(n+': '+await st())};
// short swipe: 30 pt left, release, spring home
await p.mouse.move(cx,cy);await p.mouse.down();for(let i=1;i<=6;i++){await p.mouse.move(cx-i*5*K,cy);await p.waitForTimeout(16)}await shot('short');
await p.mouse.up();await p.waitForTimeout(100);await shot('short+100');await p.waitForTimeout(400);await shot('short+500');
// long swipe: 90 pt left, live frames, release, look changes
await p.mouse.move(cx,cy);await p.mouse.down();for(let i=1;i<=18;i++){await p.mouse.move(cx-i*5*K,cy);await p.waitForTimeout(16);if(i===9)await shot('long45')}await shot('long90');
await p.mouse.up();await p.waitForTimeout(80);await shot('long+80');await p.waitForTimeout(900);await shot('long+980');
// back the other way: right swipe returns to reel
await p.mouse.move(cx-60*K,cy);await p.mouse.down();for(let i=1;i<=18;i++){await p.mouse.move(cx-60*K+i*5*K,cy);await p.waitForTimeout(16)}await p.mouse.up();await p.waitForTimeout(1000);await shot('right+1000');
console.log(out.join('\n'));console.error(look,JSON.stringify(errs));await b.close()})();
