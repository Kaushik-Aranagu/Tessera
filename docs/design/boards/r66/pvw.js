const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const theme=process.argv[2]||'paper';const pg=await b.newPage({viewport:{width:402,height:874}});const errs=[];pg.on('pageerror',e=>errs.push(e.message));
await pg.goto('file://'+__dirname+'/index.html');await pg.waitForTimeout(600);
await pg.evaluate(()=>go('chart'));await pg.waitForTimeout(800);
for(let i=0;i<3;i++){await pg.evaluate(()=>__ch.say());await pg.waitForTimeout(2300)}
const ctr=async s=>pg.evaluate(s=>{const r=document.querySelector(s).getBoundingClientRect();return [r.x+r.width/2,r.y+r.height/2]},s);
const drag=async(dx,hold)=>{const c=await ctr('.ch-key');await pg.mouse.move(c[0],c[1]);await pg.mouse.down();for(let i=1;i<=10;i++){await pg.mouse.move(c[0]+dx*i/10,c[1]);await pg.waitForTimeout(16)}
 const mid=await pg.evaluate(()=>({lens:!!document.querySelector('.shlens'),tr:document.querySelector('.ch-key').style.translate}));if(hold)await hold();await pg.mouse.up();await pg.waitForTimeout(650);return mid};
// fit: every child of the keystone stays inside the keystone place, nothing overlaps another
const fit=()=>pg.evaluate(()=>{const R=document.querySelector('.ch-key').getBoundingClientRect(),P={l:R.left,t:R.top,r:R.right,b:R.bottom};const els=[...document.querySelectorAll('.ch-key b,.ch-key span,.ch-key em')].map(e=>{const r=e.getBoundingClientRect();return {t:e.textContent,l:r.left,tp:r.top,r:r.right,b:r.bottom}});
 const out=els.filter(e=>e.l<P.l-.5||e.r>P.r+.5||e.tp<P.t-.5||e.b>P.b+.5).map(e=>e.t);const ov=[];for(let i=0;i<els.length;i++)for(let j=i+1;j<els.length;j++){const a=els[i],c=els[j];if(a.l<c.r-1&&c.l<a.r-1&&a.tp<c.b-1&&c.tp<a.b-1)ov.push(a.t+'/'+c.t)}return {out,ov}});
const st=()=>pg.evaluate(()=>({way:__ch.way,wv:__ch.wv,sel:__ch.sel,cls:document.querySelector('.ch-key').className,act:document.querySelector('.ch-act').textContent,tess:document.querySelector('.ch-tess')?.textContent||'',keyPl:document.querySelectorAll('.ch-pl')[2].className,rc:document.querySelector('.receipt')?.textContent||''}));
const r={};r.row=await fit();
r.m1=await drag(-90);r.s1=await st();r.f1=await fit();await pg.screenshot({path:'VW1-'+theme+'.png'});
r.m2=await drag(-90);r.s2=await st();r.f2=await fit();await pg.screenshot({path:'VW2-'+theme+'.png'});
r.m3=await drag(-90);r.s3=await st();
r.short=await drag(-24);r.s4=await st();
r.m5=await drag(90);r.s5=await st();
let c=await ctr('.ch-act');await pg.mouse.click(c[0],c[1]);await pg.waitForTimeout(2400);r.s6=await st();r.f6=await fit();await pg.screenshot({path:'VW3-'+theme+'.png'});
c=await ctr('.receipt button');await pg.mouse.click(c[0],c[1]);await pg.waitForTimeout(700);r.s7=await st();
// voice path: pick the keystone, calmer, pick again, other ways
c=await ctr('.ch-key');await pg.mouse.click(c[0],c[1]);await pg.waitForTimeout(200);c=await ctr('.ch-act');await pg.mouse.click(c[0],c[1]);await pg.waitForTimeout(2400);
c=await ctr('.ch-key');await pg.mouse.click(c[0],c[1]);await pg.waitForTimeout(200);r.selAgain=(await st()).sel;c=await ctr('.ch-act');await pg.mouse.click(c[0],c[1]);await pg.waitForTimeout(300);r.heard=await pg.evaluate(()=>document.querySelector('.ch-heard')?.textContent);await pg.waitForTimeout(1200);r.s8=await st();
// big numbers then the one way: 80 pt only in the row
await pg.evaluate(()=>{});
console.log(JSON.stringify(r,null,0),errs);await b.close()})();
