// 380: the sentence catches up. When the thirstiest plant changes, the old name lifts away on the layer, the gap takes
// the new name's width, and the new one rises. In the room (watering with Allow) and on the way back from a plant's
// page. The sentence's text is right from the first frame. Reduce Motion: no overlay. Paper and black.
const {chromium}=require('/opt/node22/lib/node_modules/playwright');
async function run(look,rm){const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
 const pg=await b.newPage({viewport:{width:402,height:874},reducedMotion:rm?'reduce':'no-preference'});const errs=[];pg.on('pageerror',e=>errs.push(e.message));
 await pg.goto('file://'+__dirname+'/index.html');await pg.waitForTimeout(600);await pg.evaluate(l=>setLook(l),look);
 await pg.evaluate(()=>{ROOMS.chart.saved={at:6,plants:[{n:'Orchid',d:6},{n:'Monstera',d:4},{n:'Fern',d:2},{n:'Basil',d:1}],reach:false,way:0,calm:false,big:false,queued:false};go('chart')});await pg.waitForTimeout(1500);
 const st=()=>pg.evaluate(()=>({line:current.querySelector('.ch-line')?.textContent,cap:current.querySelector('.ch-cap')?.textContent,sw:[...document.querySelectorAll('.sw')].map(e=>e.textContent),
  nm:[...current.querySelectorAll('.ch-nm')].map(e=>e.textContent+':'+e.getAnimations().length).join(' ')}));
 const r={look,rm};r.start=await st();
 // open the orchid's door, water it there, come back
 await pg.evaluate(()=>go('plant',{n:'Orchid'}));await pg.waitForTimeout(1200);await pg.click('.ch-act');await pg.waitForTimeout(400);
 await pg.evaluate(()=>back());await pg.waitForTimeout(40);r.back40=await st();await pg.waitForTimeout(300);r.back340=await st();await pg.waitForTimeout(900);r.backEnd=await st();
 if(look==='paper'&&!rm){// a frame mid-swap for the eye
  await pg.evaluate(()=>go('plant',{n:'Monstera'}));await pg.waitForTimeout(1200);await pg.click('.ch-act');await pg.waitForTimeout(400);
  await pg.evaluate(()=>{back();});await pg.waitForTimeout(420);await pg.evaluate(()=>document.getAnimations().forEach(a=>a.pause()));await pg.screenshot({path:__dirname+'/RN.png'});
  await pg.evaluate(()=>document.getAnimations().forEach(a=>a.play()));await pg.waitForTimeout(1200);r.second=await st()}
 r.errs=errs;await b.close();return r}
(async()=>{for(const [l,m] of [['paper',false],['black',false],['paper',true]])console.log(JSON.stringify(await run(l,m)))})();
