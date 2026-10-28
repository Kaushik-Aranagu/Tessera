// 371: taking the room down. Outlines come back up and fold to their corners, the room goes back to Bridge, its row
// closes up, the foot reads "Room taken down, not the plants" with Undo, and Undo puts the row back. Reduce Motion too.
const {chromium}=require('/opt/node22/lib/node_modules/playwright');
async function run(rm){const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
 const pg=await b.newPage({viewport:{width:402,height:874},reducedMotion:rm?'reduce':'no-preference'});const errs=[];pg.on('pageerror',e=>errs.push(e.message));
 await pg.goto('file://'+__dirname+'/index.html');await pg.waitForTimeout(600);
 await pg.evaluate(()=>go('chart'));await pg.waitForTimeout(1500);
 const n=await pg.evaluate(()=>__ch.n);for(let i=0;i<n;i++){await pg.evaluate(()=>__ch.say());await pg.waitForTimeout(2300)}
 await pg.evaluate(()=>__ch.allow());await pg.waitForTimeout(300);
 // water all four, then the action word offers taking the room down
 for(let i=0;i<4;i++){await pg.click('.ch-act');await pg.waitForTimeout(900)}
 const r={rm};r.act=await pg.evaluate(()=>document.querySelector('.ch-act').textContent);
 r.appsBefore=await pg.evaluate(()=>APPS.join(','));
 await pg.click('.ch-act');
 if(!rm){await pg.waitForTimeout(700);r.mid=await pg.evaluate(()=>[...document.querySelectorAll('.chart .ch-pl')].map(p=>+getComputedStyle(p).opacity.slice(0,4)));
  r.heard=await pg.evaluate(()=>document.querySelector('.ch-heard')?.textContent);await pg.waitForTimeout(1300)}else await pg.waitForTimeout(150);
 r.screen=await pg.evaluate(()=>current.dataset.id);r.apps=await pg.evaluate(()=>APPS.join(','));
 r.focus=await pg.evaluate(()=>{const d=[...current.querySelector('.dial').children].find(x=>x.style.opacity==='1');return d&&d.textContent});
 r.undo=await pg.evaluate(()=>current.querySelector('.undoline').textContent);
 // nothing overlaps the foot line
 r.overlap=await pg.evaluate(()=>{const u=current.querySelector('.undoline'),ur=u.getBoundingClientRect();const tr=u.firstChild;const rg=document.createRange();rg.selectNodeContents(u);const R=rg.getBoundingClientRect();
  const hits=[];current.querySelectorAll('*').forEach(e=>{if(u.contains(e)||e.contains(u))return;const s=getComputedStyle(e);if(s.visibility==='hidden'||+s.opacity===0||!e.offsetParent&&s.position!=='fixed')return;
   if(![...e.childNodes].some(c=>c.nodeType===3&&c.textContent.trim()))return;const q=e.getBoundingClientRect();if(q.width&&q.height&&q.left<R.right&&q.right>R.left&&q.top<R.bottom&&q.bottom>R.top)hits.push(e.className||e.tagName)});
  const t=document.querySelector('#tess').getBoundingClientRect();if(t.left<R.right&&t.top<R.bottom&&t.bottom>R.top&&t.right>R.left)hits.push('tess');return hits});
 await pg.click('.undoline button');await pg.waitForTimeout(rm?150:900);
 r.after={apps:await pg.evaluate(()=>APPS.join(',')),focus:await pg.evaluate(()=>{const d=[...current.querySelector('.dial').children].find(x=>x.style.opacity==='1');return d&&d.textContent}),undo:await pg.evaluate(()=>current.querySelector('.undoline').textContent)};
 if(!rm){await pg.screenshot({path:__dirname+'/DN.png'})}
 r.errs=errs;console.log(JSON.stringify(r));await b.close()}
(async()=>{await run(false);await run(true)})();
