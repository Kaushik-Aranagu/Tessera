const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const pg=await b.newPage({viewport:{width:402,height:874}});const errs=[];pg.on('pageerror',e=>errs.push(e.message));
await pg.goto('file://'+__dirname+'/index.html');await pg.waitForTimeout(600);
const hit=()=>pg.evaluate(()=>{const b=[...document.querySelectorAll('.receipt button')].find(x=>x.offsetParent);if(!b)return 'no receipt';const r=b.getBoundingClientRect();const e=document.elementFromPoint(r.x+r.width/2,r.y+r.height/2);return b.textContent+' on top: '+(e===b)});
for(const [m,act] of [['workout',()=>__wo.log()],['cook',()=>__ck.next()],['shop',()=>__sh.got()],['tend',()=>__rt.next()]]){
 await pg.evaluate(m=>go(m),m);await pg.waitForTimeout(900);await pg.evaluate(act);await pg.waitForTimeout(500);console.log(m,await hit())}
console.log(errs);await b.close()})();
