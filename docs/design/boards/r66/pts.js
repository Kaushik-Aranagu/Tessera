// 383: Tess's line speaks. A new line from her arrives word by word at her pace and her face blinks once; the line a
// page opens with is simply there; his own words are never spoken. Text is whole from the first frame. On a plant page
// (the dates set for every plant) and in the room (stopping a change). Paper, black, Reduce Motion.
const {chromium}=require('/opt/node22/lib/node_modules/playwright');
async function run(look,rm){const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
 const pg=await b.newPage({viewport:{width:402,height:874},reducedMotion:rm?'reduce':'no-preference'});const errs=[];pg.on('pageerror',e=>errs.push(e.message));
 await pg.goto('file://'+__dirname+'/index.html');await pg.waitForTimeout(600);await pg.evaluate(l=>setLook(l),look);
 await pg.evaluate(()=>{ROOMS.chart.saved={at:6,plants:[{n:'Orchid',d:6},{n:'Monstera',d:4},{n:'Fern',d:2},{n:'Basil',d:1}],reach:false,way:0,calm:false,big:false,queued:false};go('plant',{n:'Monstera'})});await pg.waitForTimeout(100);
 const st=sel=>pg.evaluate(s=>{const e=current.querySelector(s);if(!e)return null;const w=[...e.querySelectorAll('.sw-w')];return {t:e.textContent,words:w.length,moving:w.filter(x=>x.getAnimations().length).length,
  blink:(window.__tblink||0)>performance.now()-400,lines:Math.round(e.getBoundingClientRect().height/K/28)}},sel);
 const r={look,rm};r.open=await st('.ch-tess');await pg.waitForTimeout(1100);
 await pg.click('.ch-act');await pg.waitForTimeout(400);await pg.click('.ch-act');await pg.waitForTimeout(900);r.heard=await st('.ch-heard');
 await pg.waitForTimeout(1150);r.said=await st('.ch-tess');await pg.waitForTimeout(1200);r.settled=await st('.ch-tess');
 // the room: say a sentence, stop it while it dries
 await pg.evaluate(()=>{back()});await pg.waitForTimeout(900);await pg.evaluate(()=>{ROOMS.chart.saved=null;reset('home');go('chart')});await pg.waitForTimeout(1500);
 await pg.evaluate(()=>__ch.say());await pg.waitForTimeout(900);await pg.evaluate(()=>__ch.stop());await pg.waitForTimeout(rm?50:820);r.room=await st('.ch-tess');
 r.errs=errs;await b.close();return r}
(async()=>{for(const [l,m] of [['paper',false],['black',false],['paper',true]])console.log(JSON.stringify(await run(l,m)))})();
