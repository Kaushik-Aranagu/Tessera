const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const pg=await b.newPage({viewport:{width:402,height:874}});const errs=[];pg.on('pageerror',e=>errs.push(e.message));
await pg.goto('file://'+__dirname+'/index.html');await pg.waitForTimeout(600);
await pg.evaluate(()=>go('cook'));await pg.waitForTimeout(900);
const t=await pg.evaluate(()=>{const e=document.querySelector('[data-a="ig0"]').getBoundingClientRect();return [e.x+30,e.y+e.height/2]});
await pg.mouse.click(t[0],t[1]);await pg.waitForTimeout(600);
const got=await pg.evaluate(()=>document.querySelector('[data-a="ig0"]').className);await pg.screenshot({path:'MP1.png'});
await pg.mouse.click(t[0],t[1]);await pg.waitForTimeout(300);
console.log(got,'|',await pg.evaluate(()=>document.querySelector('[data-a="ig0"]').className),errs);await b.close()})();
