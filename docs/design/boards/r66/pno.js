const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const pg=await b.newPage({viewport:{width:402,height:874}});const errs=[];pg.on('pageerror',e=>errs.push(e.message));
await pg.goto('file://'+__dirname+'/index.html');await pg.waitForTimeout(600);
await pg.evaluate(()=>go('chart'));await pg.waitForTimeout(800);
for(let i=0;i<3;i++){await pg.evaluate(()=>__ch.say());await pg.waitForTimeout(2300)}
const before=await pg.evaluate(()=>document.querySelector('.ch-key').outerHTML);
await pg.evaluate(()=>__ch.say());await pg.waitForTimeout(400);const mid=await pg.evaluate(()=>document.querySelector('.ch-heard')?.textContent);
await pg.waitForTimeout(1100);
const r1=await pg.evaluate(()=>({tess:document.querySelector('.ch-tess')?.textContent,rc:document.querySelector('.receipt').textContent,ghosts:document.querySelectorAll('.ch-c.gh').length}));
const same=await pg.evaluate(b=>document.querySelector('.ch-key').outerHTML===b,before);
await pg.screenshot({path:'NO1.png'});
const c=await pg.evaluate(()=>{const r=document.querySelector('.receipt button').getBoundingClientRect();return [r.x+r.width/2,r.y+r.height/2]});await pg.mouse.click(c[0],c[1]);await pg.waitForTimeout(700);
const g=await pg.evaluate(()=>[document.querySelectorAll('.ch-c.gh').length,__ch.big]);await pg.waitForTimeout(1600);
const r2=await pg.evaluate(()=>({big:__ch.big,fs:getComputedStyle(document.querySelector('.ch-key b')).fontSize,rc:document.querySelector('.receipt').textContent}));
await pg.evaluate(()=>__ch.say());await pg.waitForTimeout(1500);
const r3=await pg.evaluate(()=>({tess:document.querySelector('.ch-tess')?.textContent,q:__ch.queued,rc:document.querySelector('.receipt').textContent,act:document.querySelector('.ch-act').textContent}));
await pg.screenshot({path:'NO2.png'});
// fit: tess line inside widget place
const fit=await pg.evaluate(()=>{const scr=document.querySelector('.chart'),r0=scr.getBoundingClientRect(),k=r0.width/402,e=document.querySelector('.ch-tess').getBoundingClientRect();return [(e.left-r0.left)/k,(e.top-r0.top)/k,(e.right-r0.left)/k,(e.bottom-r0.top)/k].map(Math.round)});
console.log(JSON.stringify({mid,r1,keystoneUnchanged:same,ghostAfterYes:g,r2,r3,tessBox:fit}),errs);await b.close()})();
