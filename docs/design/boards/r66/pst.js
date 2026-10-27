const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const pg=await b.newPage({viewport:{width:402,height:874}});const errs=[];pg.on('pageerror',e=>errs.push(e.message));
await pg.goto('file://'+__dirname+'/index.html');await pg.waitForTimeout(600);
await pg.evaluate(()=>go('tend'));await pg.waitForTimeout(900);
const r=await pg.evaluate(()=>{const q=document.querySelector('.dk-pad').getBoundingClientRect();return [q.x,q.y,q.width/402]});
const t=await pg.evaluate(()=>{const e=document.querySelector('[data-a="skip"]').getBoundingClientRect();return [e.x+e.width/2,e.y+e.height/2]});
await pg.mouse.click(t[0],t[1]);await pg.waitForTimeout(900);await pg.evaluate(()=>document.getAnimations().forEach(a=>a.finish()));
await pg.screenshot({path:'ST1.png'});console.log(await pg.evaluate(()=>[...document.querySelectorAll('.dk-steps div')].map(d=>d.textContent).join('|')),errs);await b.close()})();
