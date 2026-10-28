const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const pg=await b.newPage({viewport:{width:402,height:874}});const errs=[];pg.on('pageerror',e=>errs.push(e.message));
await pg.goto('file://'+__dirname+'/index.html');await pg.waitForTimeout(600);
await pg.evaluate(()=>go('chart'));await pg.waitForTimeout(1500);
const n=await pg.evaluate(()=>__ch.n);for(let i=0;i<n;i++){await pg.evaluate(()=>__ch.say());await pg.waitForTimeout(2300)}
const ctr=async s=>pg.evaluate(s=>{const r=document.querySelector(s).getBoundingClientRect();return [r.x+r.width/2,r.y+r.height/2]},s);
const st=()=>pg.evaluate(()=>({at:__ch.at,reach:!!document.querySelector('.ch-reach'),rc:document.querySelector('.receipt')?.textContent||'',act:document.querySelector('.ch-act').textContent}));
const r={};r.waiting=await st();
// Not now takes the change back
let c=await ctr('.receipt button');await pg.mouse.click(c[0],c[1]);await pg.waitForTimeout(800);r.notNow=await st();
// say it again, Allow, then Undo takes back the change and the grant
await pg.evaluate(()=>__ch.say());await pg.waitForTimeout(2300);c=await ctr('[data-a="allow"]');await pg.mouse.click(c[0],c[1]);await pg.waitForTimeout(200);r.allowed=await st();
c=await ctr('.receipt button');await pg.mouse.click(c[0],c[1]);await pg.waitForTimeout(800);r.undone=await st();
console.log(JSON.stringify(r),errs);await b.close()})();
