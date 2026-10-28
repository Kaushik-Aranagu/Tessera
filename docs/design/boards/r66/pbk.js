const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const pg=await b.newPage({viewport:{width:402,height:874}});const errs=[];pg.on('pageerror',e=>errs.push(e.message));
await pg.goto('file://'+__dirname+'/index.html');await pg.waitForTimeout(600);
await pg.evaluate(()=>setLook('black'));await pg.waitForTimeout(300);
await pg.evaluate(()=>go('chart'));await pg.waitForTimeout(1600);await pg.screenshot({path:'BK0.png'});
for(let i=0;i<3;i++){await pg.evaluate(()=>__ch.say());await pg.waitForTimeout(2300)}
await pg.screenshot({path:'BK1.png'});
for(let i=0;i<5;i++){await pg.evaluate(()=>__ch.say());await pg.waitForTimeout(2300)}
await pg.screenshot({path:'BK2.png'});
const col=await pg.evaluate(()=>{const g=s=>{const e=document.querySelector(s);return e?getComputedStyle(e).color:null};return {bg:getComputedStyle(document.querySelector('.chart')).backgroundColor,ttl:g('.ch-ttl'),line:g('.ch-line'),th:g('.ch-key .th b'),cap:g('.ch-cap'),wish:g('.ch-wish'),reach:g('.ch-reach'),act:g('.ch-act'),pl:getComputedStyle(document.querySelectorAll('.ch-pl')[5]).borderTopColor}});
console.log(JSON.stringify(col),errs);await b.close()})();
