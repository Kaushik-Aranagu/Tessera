const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const pg=await b.newPage({viewport:{width:402,height:874}});const errs=[];pg.on('pageerror',e=>errs.push(e.message));
await pg.goto('file://'+__dirname+'/index.html');await pg.waitForTimeout(600);
await pg.evaluate(()=>go('chart'));await pg.waitForTimeout(1500);
for(let i=0;i<6;i++){await pg.evaluate(()=>__ch.say());await pg.waitForTimeout(2300)}
const ctr=async s=>pg.evaluate(s=>{const r=document.querySelector(s).getBoundingClientRect();return [r.x+r.width/2,r.y+r.height/2]},s);
const st=()=>pg.evaluate(()=>({at:__ch.at,tmw:__ch.tmw,wish:document.querySelector('.ch-wish')?.className||'',key:[...document.querySelectorAll('.ch-key b')].map(b=>b.textContent).join(' '),cap:document.querySelector('.ch-cap')?.textContent,tess:document.querySelector('.ch-tess')?.textContent||'',act:document.querySelector('.ch-act').textContent,gh:[...document.querySelectorAll('.ch-c.gh')].map(e=>e.dataset.p).join(','),rc:document.querySelector('.receipt')?.textContent||'',pls:[...document.querySelectorAll('.ch-pl')].map(p=>p.className.replace('ch-pl','').trim()||'-').join('|')}));
const r={};let c=await ctr('.ch-act');await pg.mouse.click(c[0],c[1]);await pg.waitForTimeout(900);r.mid=await st();await pg.waitForTimeout(1500);r.set=await st();await pg.screenshot({path:'WI1.png'});
c=await ctr('.ch-wish');await pg.mouse.click(c[0],c[1]);await pg.waitForTimeout(600);r.tmw=await st();await pg.screenshot({path:'WI2.png'});
// boxes: wish, tess and reach lines never overlap inside the widget place
r.boxes=await pg.evaluate(()=>['.ch-tess','.ch-wish','.ch-reach'].map(s=>{const e=document.querySelector(s);if(!e)return null;const b=e.getBoundingClientRect();return [s,Math.round(b.top),Math.round(b.bottom)]}));
c=await ctr('.ch-act');await pg.mouse.click(c[0],c[1]);await pg.waitForTimeout(500);r.back=await st();
// then the reach sentence, allow, and the wish stays with the reach line above it
await pg.evaluate(()=>__ch.say());await pg.waitForTimeout(2300);r.reach=await st();r.boxes2=await pg.evaluate(()=>['.ch-tess','.ch-wish','.ch-reach'].map(s=>{const e=document.querySelector(s);if(!e)return null;const b=e.getBoundingClientRect();return [s,Math.round(b.top),Math.round(b.bottom)]}));await pg.screenshot({path:'WI3.png'});
console.log(JSON.stringify(r),errs);await b.close()})();
