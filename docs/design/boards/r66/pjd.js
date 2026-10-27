const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const pg=await b.newPage({viewport:{width:402,height:874}});const errs=[];pg.on('pageerror',e=>errs.push(e.message));
await pg.goto('file://'+__dirname+'/index.html');await pg.waitForTimeout(600);
await pg.evaluate(()=>go('cook'));await pg.waitForTimeout(900);
await pg.evaluate(()=>window.__ck.next());await pg.waitForTimeout(30);
const a=await pg.evaluate(()=>{const d=document.querySelector('.tk-steps .jd');return d?d.textContent:null});
await pg.evaluate(()=>document.getAnimations().forEach(x=>{x.pause();x.currentTime=Math.min(x.effect.getTiming().duration+ (x.effect.getTiming().delay||0),x.effect.target&&x.effect.pseudoElement?250:5000)}));await pg.screenshot({path:'JD1.png'});
await pg.waitForTimeout(900);const after=await pg.evaluate(()=>document.querySelectorAll('.tk-steps .jd').length);
console.log('jd',a,'after',after,errs);await b.close()})();
