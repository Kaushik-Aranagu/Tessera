// 381: watering turns the dates over by one, like a departure board. On the fern's page (the dates already set for every
// plant): each place rolls from its old date to its new one, front first, and Oct 17 leaves; Undo rolls them back.
// The line's text is right from the first frame. Reduce Motion: no movement. Paper and black.
const {chromium}=require('/opt/node22/lib/node_modules/playwright');
async function run(look,rm){const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
 const pg=await b.newPage({viewport:{width:402,height:874},reducedMotion:rm?'reduce':'no-preference'});const errs=[];pg.on('pageerror',e=>errs.push(e.message));
 await pg.goto('file://'+__dirname+'/index.html');await pg.waitForTimeout(600);await pg.evaluate(l=>setLook(l),look);
 await pg.evaluate(()=>{ROOMS.chart.saved={at:6,plants:[{n:'Orchid',d:6},{n:'Monstera',d:4},{n:'Fern',d:2},{n:'Basil',d:1}],reach:false,way:0,calm:false,big:false,queued:false};go('plant',{n:'Orchid'})});await pg.waitForTimeout(1200);
 await pg.click('.ch-act');await pg.waitForTimeout(400);await pg.click('.ch-act');await pg.waitForTimeout(2300);// the dates, for every plant
 await pg.evaluate(()=>back());await pg.waitForTimeout(800);await pg.evaluate(()=>go('plant',{n:'Fern'}));await pg.waitForTimeout(1200);
 const st=()=>pg.evaluate(()=>({hs:current.querySelector('.pl-hist').textContent,moving:[...current.querySelectorAll('.pl-hist .dt')].map(e=>e.textContent+':'+e.getAnimations().length).join(' '),out:[...document.querySelectorAll('.dt-out')].map(e=>e.textContent),
  cut:(e=>e.scrollWidth>e.clientWidth+1)(current.querySelector('.pl-hist')),rc:current.querySelector('.receipt')?.textContent||''}));
 const r={look,rm};r.before=await st();
 await pg.click('.ch-act');await pg.waitForTimeout(60);r.mid=await st();
 await pg.waitForTimeout(700);r.after=await st();
 await pg.click('.receipt button');await pg.waitForTimeout(60);r.undoMid=await st();await pg.waitForTimeout(700);r.undone=await st();
 r.errs=errs;await b.close();return r}
(async()=>{for(const [l,m] of [['paper',false],['black',false],['paper',true]])console.log(JSON.stringify(await run(l,m)))})();
