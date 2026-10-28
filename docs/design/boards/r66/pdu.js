const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const pg=await b.newPage({viewport:{width:402,height:874}});const errs=[];pg.on('pageerror',e=>errs.push(e.message));
await pg.goto('file://'+__dirname+'/index.html');await pg.waitForTimeout(600);
await pg.evaluate(()=>go('chart'));await pg.waitForTimeout(1500);
for(let i=0;i<2;i++){await pg.evaluate(()=>__ch.say());await pg.waitForTimeout(2300)}
const ctr=async s=>pg.evaluate(s=>{const r=document.querySelector(s).getBoundingClientRect();return [r.x+r.width/2,r.y+r.height/2]},s);
const st=()=>pg.evaluate(()=>({at:__ch.at,gh:[...document.querySelectorAll('.ch-c.gh')].map(e=>e.dataset.p).join(','),dry:document.querySelectorAll('.ch-dry').length,key:!!document.querySelector('.ch-key'),pl:[...document.querySelectorAll('.ch-pl')].slice(2,4).map(p=>p.className).join('|'),rc:document.querySelector('.receipt')?.textContent||''}));
const r={};r.s0=await st();
let c=await ctr('.receipt button');await pg.mouse.click(c[0],c[1]);await pg.waitForTimeout(300);r.mid=await st();await pg.screenshot({path:'DU1.png'});
await pg.waitForTimeout(700);r.end=await st();
// a new sentence takes the last receipt down, so an Undo can't land on the wrong change while it dries
await pg.evaluate(()=>__ch.say());await pg.waitForTimeout(2300);await pg.evaluate(()=>__ch.say());await pg.waitForTimeout(300);
r.during=await st();r.noUndoWhileDrying=await pg.evaluate(()=>!document.querySelector('.receipt button'));await pg.waitForTimeout(2300);r.after=await st();
console.log(JSON.stringify(r),errs);await b.close()})();
