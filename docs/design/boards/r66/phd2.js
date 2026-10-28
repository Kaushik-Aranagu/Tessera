const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const pg=await b.newPage({viewport:{width:402,height:874}});
await pg.goto('file://'+__dirname+'/index.html');await pg.waitForTimeout(600);
await pg.evaluate(()=>go('workout'));await pg.waitForTimeout(900);
const r=await pg.evaluate(()=>{const q=document.querySelector('.fbpad').getBoundingClientRect();return [q.x,q.y,q.width/402]});
await pg.mouse.move(r[0]+340*r[2],r[1]+104*r[2]);await pg.mouse.down();await pg.waitForTimeout(200);const h=await pg.evaluate(()=>window.__wo.S.hold0>0);await pg.waitForTimeout(700);await pg.mouse.up();
console.log('holding',h,'phase',await pg.evaluate(()=>window.__wo.S.phase),'hold0',await pg.evaluate(()=>window.__wo.S.hold0));await b.close()})();
