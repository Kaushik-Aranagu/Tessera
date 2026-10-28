// 303: a new note joins the Log wall. Frames of the wall making room, then a check that no two words overlap,
// that nothing leaves the wall, and that Undo takes it back out.
const {chromium}=require('/opt/node22/lib/node_modules/playwright');
const look=process.argv[2]||'paper';
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage({viewport:{width:1300,height:1000}});
const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(2000);
if(look==='black'){await p.click('#lk-black')}await p.evaluate(()=>{scrollTo(0,0);reset('home');go('notes')});await p.waitForTimeout(3500);
const ph=await (await p.$('#phone')).boundingBox();const r=await p.evaluate(()=>{const e=current.querySelector('.wall').getBoundingClientRect();return {y:e.top,h:e.height}});
const clip={x:ph.x,y:r.y-6,width:ph.width,height:r.h+12};const fs=[];
await p.screenshot({path:'L'+look[0]+'0.png',clip});fs.push('L'+look[0]+'0.png');
await p.evaluate(()=>window.__th('log-add'));let last=0;
for(const t of [150,300,450,700,1200]){await p.waitForTimeout(t-last);last=t;const f='L'+look[0]+t+'.png';await p.screenshot({path:f,clip});fs.push(f)}
const check=()=>p.evaluate(()=>{const H=current.querySelector('.wall'),B=H.getBoundingClientRect();/* words in the middle of the wall's own moments (a flip or a scramble) are skipped */
 const R=[...H.querySelectorAll('.wd')].filter(e=>!e.classList.contains('flip')&&!e.classList.contains('dis')&&!e.style.scale).map(e=>{const q=e.getBoundingClientRect();return {t:e.textContent,l:q.left,r:q.right,y:q.top+q.height*.18,b:q.bottom-q.height*.18}});
 const bad=[];R.forEach((a,i)=>{if(a.l<B.left-1||a.r>B.right+1||a.y<B.top-1||a.b>B.bottom+1)bad.push('out '+a.t);R.slice(i+1).forEach(c=>{if(Math.min(a.r,c.r)-Math.max(a.l,c.l)>1&&Math.min(a.b,c.b)-Math.max(a.y,c.y)>1)bad.push(a.t+' x '+c.t)})});return R.length+' words '+(bad.join(', ')||'clean')});
const after=await check();await p.evaluate(()=>{const u=current.querySelector('.undoline button');u&&u.click()});await p.waitForTimeout(1200);const undone=await check();
console.log(fs.join(' '));console.error(look,'after add:',after,'| after undo:',undone,JSON.stringify(errs));await b.close()})();
