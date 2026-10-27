const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const pg=await b.newPage({viewport:{width:402,height:874}});const errs=[];pg.on('pageerror',e=>errs.push(e.message));
await pg.goto('file://'+__dirname+'/index.html');await pg.waitForTimeout(600);
await pg.evaluate(()=>go('chart'));await pg.waitForTimeout(800);
const pl=()=>pg.evaluate(()=>[...document.querySelectorAll('.ch-pl')].slice(0,3).map(e=>{const c=getComputedStyle(e);return (+c.opacity).toFixed(2)+' '+c.transform+' '+c.transitionDelay}));
await pg.evaluate(()=>__ch.say());await pg.waitForTimeout(1000);const ghost=await pl();
await pg.waitForTimeout(1150);const mid=await pl();await pg.waitForTimeout(600);const end=await pl();
const u=await pg.evaluate(()=>{const b=document.querySelector('.receipt button').getBoundingClientRect();return [b.x+b.width/2,b.y+b.height/2]});await pg.mouse.click(u[0],u[1]);await pg.waitForTimeout(700);const undone=await pl();
console.log('ghost',ghost,'\nmid',mid,'\nset',end,'\nundo',undone,errs);await b.close()})();
