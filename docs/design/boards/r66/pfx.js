const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const pg=await b.newPage({viewport:{width:402,height:874}});const errs=[];pg.on('pageerror',e=>errs.push(e.message));
await pg.goto('file://'+__dirname+'/index.html');await pg.waitForTimeout(600);
await pg.evaluate(()=>go('workout'));await pg.waitForTimeout(900);
await pg.evaluate(()=>{const w=window.__wo;w.pick(1);w.log()});await pg.waitForTimeout(200);
const ws=[];const W=()=>pg.evaluate(()=>window.__wo.LIFTS[1].sets.map(x=>x.w).join(','));
await pg.evaluate(()=>window.__wo.feel('Easy'));ws.push(await W());await pg.evaluate(()=>window.__wo.feel('Hard'));ws.push(await W());await pg.evaluate(()=>window.__wo.feel('Right'));ws.push(await W());
await pg.evaluate(()=>window.__wo.feel('Easy'));ws.push(await W());await pg.waitForTimeout(1000);await pg.screenshot({path:'FX1.png'});
console.log(ws.join(' / '),await pg.evaluate(()=>JSON.stringify(window.__wo.S.fix&&window.__wo.S.fix.from)),errs);await b.close()})();
