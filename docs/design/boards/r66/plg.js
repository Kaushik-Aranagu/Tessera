const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
for(const look of ['paper','black']){const pg=await b.newPage({viewport:{width:402,height:874}});const errs=[];pg.on('pageerror',e=>errs.push(e.message));
await pg.goto('file://'+__dirname+'/index.html');await pg.waitForTimeout(600);await pg.evaluate(l=>setLook(l),look);await pg.waitForTimeout(200);
await pg.evaluate(()=>go('notes'));await pg.waitForTimeout(1800);await pg.screenshot({path:'LG-'+look+'.png'});
const c=await pg.evaluate(()=>{const t=[...document.querySelectorAll('.screen:last-child *')].find(e=>e.children.length===0&&e.textContent.trim()==='Log');return t?getComputedStyle(t).color:null});
console.log(look,c,errs);await pg.close()}
await b.close()})();
