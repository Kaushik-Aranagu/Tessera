// 382: one Undo everywhere. The word Undo thins over its 10 s, the line fades when they run out, and tapping Undo winds
// the line back from the right while the change reverses. On a plant page's receipt and on Bridge's "Room taken down"
// line. Reduce Motion: no thinning, no wind. Paper and black.
const {chromium}=require('/opt/node22/lib/node_modules/playwright');
async function run(look,rm){const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
 const pg=await b.newPage({viewport:{width:402,height:874},reducedMotion:rm?'reduce':'no-preference'});const errs=[];pg.on('pageerror',e=>errs.push(e.message));
 await pg.goto('file://'+__dirname+'/index.html');await pg.waitForTimeout(600);await pg.evaluate(l=>setLook(l),look);
 await pg.evaluate(()=>{ROOMS.chart.saved={at:6,plants:[{n:'Orchid',d:6},{n:'Monstera',d:4},{n:'Fern',d:2},{n:'Basil',d:1}],reach:false,way:0,calm:false,big:false,queued:false};go('plant',{n:'Basil'})});await pg.waitForTimeout(1200);
 const rc=sel=>pg.evaluate(s=>{const r=document.querySelector(s);const bt=r&&r.querySelector('button');return {t:r?r.textContent:'',ink:bt?+(+getComputedStyle(bt).opacity).toFixed(2):null,anim:r?r.getAnimations().map(a=>a.effect.getKeyframes().map(k=>k.clipPath?'clip':'op').join('')).join(','):''}},sel);
 const r={look,rm};
 await pg.click('.ch-act');await pg.waitForTimeout(1000);r.at1=await rc('.screen:last-child .receipt, .receipt');
 await pg.waitForTimeout(7000);r.at8=await rc('.receipt');await pg.waitForTimeout(1800);r.at98=await rc('.receipt');await pg.waitForTimeout(700);r.at105=await rc('.receipt');
 // water again and Undo: the line winds back while the number goes back
 await pg.evaluate(()=>back());await pg.waitForTimeout(800);await pg.evaluate(()=>go('plant',{n:'Fern'}));await pg.waitForTimeout(1200);
 await pg.click('.ch-act');await pg.waitForTimeout(500);await pg.click('.receipt button');await pg.waitForTimeout(60);
 r.undo60={...await rc('.receipt'),d:await pg.evaluate(()=>__pl.d)};await pg.waitForTimeout(400);r.undo460=await rc('.receipt');
 // a new line takes over at full ink
 await pg.click('.ch-act');await pg.waitForTimeout(6500);await pg.evaluate(()=>receipt(current,'Fern, watered',()=>{}));await pg.waitForTimeout(100);r.fresh=await rc('.receipt');
 // Bridge: the room taken down
 await pg.evaluate(()=>{back()});await pg.waitForTimeout(800);await pg.evaluate(()=>go('chart'));await pg.waitForTimeout(1200);await pg.evaluate(()=>__ch.down());await pg.waitForTimeout(3500);
 r.bridge1=await rc('.undoline');await pg.waitForTimeout(8000);r.bridge115=await rc('.undoline');
 r.errs=errs;await b.close();return r}
(async()=>{for(const [l,m] of [['paper',false],['black',false],['paper',true]])console.log(JSON.stringify(await run(l,m)))})();
