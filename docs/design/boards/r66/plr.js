const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const pg=await b.newPage({viewport:{width:402,height:874}});const errs=[];pg.on('pageerror',e=>errs.push(e.message));
await pg.goto('file://'+__dirname+'/index.html');await pg.waitForTimeout(600);
await pg.evaluate(()=>go('lock'));await pg.waitForTimeout(900);await pg.evaluate(()=>window.__lk.set(1));await pg.waitForTimeout(400);
await pg.evaluate(()=>window.__lk.t2(1));await pg.waitForTimeout(1300);
const n=await pg.evaluate(()=>document.querySelector('.lk-island').getAnimations().length);await pg.evaluate(()=>document.getAnimations().forEach(a=>a.finish()));
await pg.screenshot({path:'LR1.png'});
console.log('island anims',n,await pg.evaluate(()=>document.querySelector('.lk-la .la1').textContent+' | '+document.querySelector('.lk-island').textContent),errs);await b.close()})();
