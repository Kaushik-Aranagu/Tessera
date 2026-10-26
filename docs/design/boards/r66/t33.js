const {chromium}=require('/opt/node22/lib/node_modules/playwright');
const look=process.argv[2]||'paper';
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage({viewport:{width:1300,height:1000}});
const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(2500);
if(look==='black')await p.click('#lk-black');await p.evaluate(()=>scrollTo(0,0));await p.waitForTimeout(600);
const ph=await p.$('#phone');const one=await p.evaluate(()=>{const r=current.querySelector('.one').getBoundingClientRect();return {x:r.left,y:r.top,w:r.width,h:r.height}});
// drag the Bridge's one thing across, hold mid-drag, then release
const sx=one.x+one.w*.6,sy=one.y+one.h*.85;await p.mouse.move(sx,sy);await p.mouse.down();
for(let i=1;i<=10;i++){await p.mouse.move(sx-i*18,sy);await p.waitForTimeout(16)}
await p.waitForTimeout(80);await ph.screenshot({path:'E'+look[0]+'1.png'});
console.log('mid-drag',await p.evaluate(()=>[...current.querySelectorAll('.one > .blk')].map(b=>b.style.scale+'|'+b.style.rotate+'|'+b.style.filter).join(' / ')));
for(let i=11;i<=16;i++){await p.mouse.move(sx-i*18,sy);await p.waitForTimeout(16)}await p.mouse.up();
await p.waitForTimeout(150);await ph.screenshot({path:'E'+look[0]+'2.png'});await p.waitForTimeout(600);await ph.screenshot({path:'E'+look[0]+'3.png'});
console.log('settled',await p.evaluate(()=>{const H=current.querySelector('.one').getBoundingClientRect();return [...current.querySelectorAll('.one > .blk')].map(b=>{const r=b.getBoundingClientRect();return '['+b.style.scale+'|'+b.style.transform+'|'+getComputedStyle(b).transform+'|'+Math.round(r.left-H.left)+','+Math.round(r.top-H.top)+' '+Math.round(r.width)+'x'+Math.round(r.height)+' host '+Math.round(H.width)+'x'+Math.round(H.height)+']'}).join(' ')}));
console.log(look,JSON.stringify(errs));await b.close()})();
