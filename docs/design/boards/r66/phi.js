const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const pg=await b.newPage({viewport:{width:402,height:874}});const errs=[];pg.on('pageerror',e=>errs.push(e.message));
await pg.goto('file://'+__dirname+'/index.html');await pg.waitForTimeout(600);
await pg.evaluate(()=>go('chart'));await pg.waitForTimeout(800);
for(let i=0;i<7;i++){await pg.evaluate(()=>__ch.say());await pg.waitForTimeout(2300)}
await pg.evaluate(()=>__ch.allow());await pg.waitForTimeout(200);
const ctr=async s=>pg.evaluate(s=>{const r=document.querySelector(s).getBoundingClientRect();return [r.x+r.width/2,r.y+r.height/2]},s);
let c=await ctr('.ch-ttl');await pg.mouse.move(c[0],c[1]);await pg.mouse.down();await pg.waitForTimeout(600);await pg.mouse.up();await pg.waitForTimeout(250);
const h1=await pg.evaluate(()=>({hist:__ch.hist,sel:__ch.sel,rows:[...document.querySelectorAll('.ch-hist button')].map(b=>b.textContent),on:document.querySelector('.ch-hist .on')?.textContent,act:document.querySelector('.ch-act').textContent}));
await pg.screenshot({path:'HI1.png'});
c=await ctr('.ch-hist button[data-v="2"]');await pg.mouse.click(c[0],c[1]);await pg.waitForTimeout(400);
const h2=await pg.evaluate(()=>({at:__ch.at,realAt:__ch.realAt,ghosts:document.querySelectorAll('.ch-c.gh').length,act:document.querySelector('.ch-act').textContent,big:!!document.querySelector('.ch-key.big')}));
await pg.screenshot({path:'HI2.png'});
c=await ctr('.ch-act');await pg.mouse.click(c[0],c[1]);await pg.waitForTimeout(400);
const h3=await pg.evaluate(()=>({at:__ch.at,hist:__ch.hist,rc:document.querySelector('.receipt').textContent,act:document.querySelector('.ch-act').textContent,ghosts:document.querySelectorAll('.ch-c.gh').length}));
c=await ctr('.receipt button');await pg.mouse.click(c[0],c[1]);await pg.waitForTimeout(300);
const h4=await pg.evaluate(()=>({at:__ch.at,act:document.querySelector('.ch-act').textContent}));
// fit of history in widget place
const fit=await pg.evaluate(()=>1);
console.log(JSON.stringify({h1,h2,h3,h4}),errs);await b.close()})();
