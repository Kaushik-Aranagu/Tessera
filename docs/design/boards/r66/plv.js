const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const pg=await b.newPage({viewport:{width:402,height:874}});const errs=[];pg.on('pageerror',e=>errs.push(e.message));
await pg.goto('file://'+__dirname+'/index.html');await pg.waitForTimeout(600);
await pg.evaluate(()=>go('chart'));await pg.waitForTimeout(800);
for(let i=0;i<6;i++){await pg.evaluate(()=>__ch.say());await pg.waitForTimeout(2300)}
await pg.evaluate(()=>__ch.allow());await pg.waitForTimeout(200);
const ctr=async s=>pg.evaluate(s=>{const r=document.querySelector(s).getBoundingClientRect();return [r.x+r.width/2,r.y+r.height/2]},s);
const st=()=>pg.evaluate(()=>({order:[...document.querySelectorAll('.ch-key b[data-k]')].map(b=>b.dataset.k+b.textContent),th:document.querySelector('.ch-key .th span')?.textContent||'',line:document.querySelector('.ch-line').textContent,cap:document.querySelector('.ch-cap').textContent,act:document.querySelector('.ch-act').textContent,rc:document.querySelector('.receipt')?.textContent||''}));
const fit=()=>pg.evaluate(()=>{const R=document.querySelector('.ch-key').getBoundingClientRect();const els=[...document.querySelectorAll('.ch-key b,.ch-key span,.ch-key em')].map(e=>{const r=e.getBoundingClientRect();return {t:e.textContent,l:r.left,tp:r.top,r:r.right,b:r.bottom}});
 const out=els.filter(e=>e.l<R.left-.5||e.r>R.right+.5||e.tp<R.top-.5||e.b>R.bottom+.5).map(e=>e.t);const ov=[];for(let i=0;i<els.length;i++)for(let j=i+1;j<els.length;j++){const a=els[i],c=els[j];if(a.l<c.r-1&&c.l<a.r-1&&a.tp<c.b-1&&c.tp<a.b-1)ov.push(a.t+'/'+c.t)}return {out,ov}});
const r={};r.s0=await st();
let c=await ctr('.ch-act');await pg.mouse.click(c[0],c[1]);await pg.waitForTimeout(150);
r.mid=await pg.evaluate(()=>{const o=document.querySelector('.ch-key b[data-k="Orchid"]');return {txt:o.textContent,anims:o.getAnimations().length,tr:getComputedStyle(o).transform!=='none',monCol:getComputedStyle(document.querySelector('.ch-key b[data-k="Monstera"]')).color}});
await pg.screenshot({path:'LV1.png'});
await pg.waitForTimeout(700);r.s1=await st();r.f1=await fit();r.monColEnd=await pg.evaluate(()=>getComputedStyle(document.querySelector('.ch-key b[data-k="Monstera"]')).color);await pg.screenshot({path:'LV2.png'});
c=await ctr('.receipt button');await pg.mouse.click(c[0],c[1]);await pg.waitForTimeout(800);r.s2=await st();
for(let i=0;i<4;i++){c=await ctr('.ch-act');await pg.mouse.click(c[0],c[1]);await pg.waitForTimeout(800)}
r.s3=await st();r.f3=await fit();await pg.screenshot({path:'LV3.png'});
console.log(JSON.stringify(r),errs);await b.close()})();
