// 319: the Deck's door summary while the dial turns. Counts summary blocks on screen and checks they never reach the foot.
const {chromium}=require('/opt/node22/lib/node_modules/playwright');
const look=process.argv[2]||'paper',room=process.argv[3]||'training',steps=+(process.argv[4]||4),gap=+(process.argv[5]||300);
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage({viewport:{width:1300,height:1000}});
const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(2000);
if(look==='black'){await p.click('#lk-black')}await p.evaluate(r=>{scrollTo(0,0);reset('home');go(r)},room);await p.waitForTimeout(3500);
const ph=await (await p.$('#phone')).boundingBox();const K=ph.width/402;const d=await (await p.$('#phone .dial')).boundingBox();
const probe=()=>p.evaluate(()=>{const P=document.querySelector('#phone').getBoundingClientRect(),k=P.width/402;const act=current.querySelector('.act');const ar=act&&act.getBoundingClientRect();
 const sx=[...current.querySelectorAll('.lsum .sx')];let bad=[];
 sx.forEach(s=>{[...s.querySelectorAll('*')].filter(e=>!e.children.length&&e.textContent.trim()).forEach(e=>{const r=e.getBoundingClientRect();let o=1,v=e;while(v&&v!==current){o*=+getComputedStyle(v).opacity;v=v.parentElement}
  if(o>.05&&ar&&r.bottom>ar.top+2&&r.top<ar.bottom&&r.right>ar.left&&r.left<ar.right)bad.push(e.textContent.trim()+'@'+o.toFixed(2)+' y'+Math.round((r.top-P.top)/k))})});
 return sx.length+' summaries'+(bad.length?' OVER FOOT: '+bad.join(', '):'')});
const out=[];let worst=0;
for(let i=0;i<steps;i++){await p.mouse.move(d.x+d.width/2,d.y+d.height/2);await p.mouse.down();await p.mouse.move(d.x+d.width/2,d.y+d.height/2-44*K,{steps:4});await p.mouse.up();
 for(let t=0;t<gap;t+=40){const s=await probe();if(/OVER/.test(s)){worst++;out.push(i+' +'+t+' '+s);await p.screenshot({path:'O'+look[0]+i+'_'+t+'.png',clip:ph})}await p.waitForTimeout(25)}}
out.push('end '+await probe());console.log(out.join('\n'));console.error(look,room,'overlap frames',worst,JSON.stringify(errs));await b.close()})();
