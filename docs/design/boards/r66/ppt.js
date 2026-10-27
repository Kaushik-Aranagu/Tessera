const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const pg=await b.newPage({viewport:{width:402,height:874}});const errs=[];pg.on('pageerror',e=>errs.push(e.message));
await pg.goto('file://'+__dirname+'/index.html');await pg.waitForTimeout(600);
await pg.evaluate(()=>go('chart'));await pg.waitForTimeout(800);
for(let i=0;i<3;i++){await pg.evaluate(()=>__ch.say());await pg.waitForTimeout(2300)}
const ctr=async s=>pg.evaluate(s=>{const r=document.querySelector(s).getBoundingClientRect();return [r.x+r.width/2,r.y+r.height/2]},s);
let c=await ctr('.ch-key');await pg.mouse.click(c[0],c[1]);await pg.waitForTimeout(300);
const s1=await pg.evaluate(()=>({sel:__ch.sel,pt:[...document.querySelectorAll('.ch-pl.pt')].length,act:document.querySelector('.ch-act').textContent,b:getComputedStyle(document.querySelector('.ch-pl.pt')).borderTopStyle}));
await pg.screenshot({path:'PT1.png'});
c=await ctr('.ch-act');await pg.mouse.click(c[0],c[1]);await pg.waitForTimeout(800);
const s2=await pg.evaluate(()=>({heard:document.querySelector('.ch-heard')?.textContent,ghost:document.querySelectorAll('.ch-c.gh').length}));
await pg.waitForTimeout(1600);
const s3=await pg.evaluate(()=>({calm:__ch.calm,rc:document.querySelector('.receipt').textContent,dur:getComputedStyle(document.querySelector('.ch-key .th b')).animationDuration}));
c=await ctr('.receipt button');await pg.mouse.click(c[0],c[1]);await pg.waitForTimeout(300);
const s4=await pg.evaluate(()=>__ch.calm);
c=await ctr('.ch-ttl');await pg.mouse.click(c[0],c[1]);await pg.waitForTimeout(200);const s5=await pg.evaluate(()=>document.querySelector('.ch-act').textContent);
c=await ctr('.ch-act');await pg.mouse.click(c[0],c[1]);await pg.waitForTimeout(200);const s6=await pg.evaluate(()=>[__ch.sel,document.querySelector('.receipt').textContent]);
console.log(JSON.stringify({s1,s2,s3,undoCalm:s4,s5,s6}),errs);await b.close()})();
