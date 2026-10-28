// 302: the back pull resists over its last 8 pt. Drag from the left edge and read the nav word's growth per point.
const {chromium}=require('/opt/node22/lib/node_modules/playwright');
const look=process.argv[2]||'paper';
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage({viewport:{width:1300,height:1000}});
const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(2000);
if(look==='black'){await p.click('#lk-black')}await p.evaluate(()=>{scrollTo(0,0);reset('home');go('kitchen')});await p.waitForTimeout(2500);
const ph=await (await p.$('#phone')).boundingBox();const K=ph.width/402;const y=ph.y+ph.height*.5;
await p.mouse.move(ph.x+10*K,y);await p.mouse.down();const out=[];
for(const dx of [40,60,68,72,76,80,84,90]){await p.mouse.move(ph.x+(10+dx)*K,y);await p.waitForTimeout(30);
 out.push(dx+':'+await p.evaluate(()=>{const n=current.querySelector('.lnav,.backw');return n?n.style.transform:'none'}))}
await p.mouse.move(ph.x+(10+78)*K,y);await p.mouse.up();await p.waitForTimeout(600);const stayed=await p.evaluate(()=>stack[stack.length-1].id);
console.log(look,out.join(' | '),'| let go at 78:',stayed,JSON.stringify(errs));await b.close()})();
