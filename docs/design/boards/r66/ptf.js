const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const pg=await b.newPage({viewport:{width:402,height:874}});const errs=[];pg.on('pageerror',e=>errs.push(e.message));
await pg.goto('file://'+__dirname+'/index.html');await pg.waitForTimeout(600);
await pg.evaluate(()=>go('shop'));await pg.waitForTimeout(900);
const out=[];for(let i=0;i<10;i++){await pg.evaluate(()=>window.__sh.got());out.push(await pg.evaluate(()=>document.querySelector('.tk-top span:last-child').textContent))}
await pg.screenshot({path:'TF1.png',clip:{x:0,y:60,width:402,height:120}});await pg.waitForTimeout(2500);out.push(await pg.evaluate(()=>document.querySelector('.tk-top span:last-child').textContent));
console.log(out.join(' / '),errs);await b.close()})();
