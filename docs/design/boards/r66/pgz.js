// 384: Tess looks at what she means. In the room: while his words are up her eyes rest on them, then on the place that
// dries; when she says no she looks at you, then at the numbers she offers; stopped, she looks at you. On a plant page:
// his words, then the new part, then the plant's name as she says it. A tap on her face is eye contact. The eyes come
// home after. Paper, black, Reduce Motion (placed at once, first thing named only). Text is unchanged.
const {chromium}=require('/opt/node22/lib/node_modules/playwright');
async function run(look,rm){const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
 const pg=await b.newPage({viewport:{width:402,height:874},reducedMotion:rm?'reduce':'no-preference'});const errs=[];pg.on('pageerror',e=>errs.push(e.message));
 await pg.goto('file://'+__dirname+'/index.html');await pg.waitForTimeout(600);await pg.evaluate(l=>setLook(l),look);
 const g=()=>pg.evaluate(()=>__tgaze());const W=ms=>pg.waitForTimeout(ms);const r={look,rm};
 await pg.evaluate(()=>{ROOMS.chart.saved=null;reset('home');go('chart')});await W(1500);
 await pg.evaluate(()=>__ch.say());await W(250);r.hear=await g();await W(900);r.dry=await g();await W(1400);r.landed=await g();await W(2200);r.home=await g();
 await pg.evaluate(()=>__ch.say());await W(2600);await pg.evaluate(()=>__ch.say());await W(2600);
 // the rule says no: "No boxes in this house. Bigger numbers instead?"
 await pg.evaluate(()=>__ch.say());await W(1200+150);r.no1=await g();r.noLine=await pg.evaluate(()=>current.querySelector('.ch-tess')?.textContent);await W(rm?0:500);r.no2=await g();
 await W(2600);
 // the ring is queued; stop it while it dries
 await pg.evaluate(()=>__ch.say());await W(400);await pg.evaluate(()=>__ch.stop());await W(rm?150:1000);r.stop=await g();r.stopLine=await pg.evaluate(()=>current.querySelector('.ch-tess')?.textContent);
 // a plant page: say show when I watered it
 await pg.evaluate(()=>{ROOMS.chart.saved={at:6,plants:[{n:'Orchid',d:6},{n:'Monstera',d:0},{n:'Fern',d:2},{n:'Basil',d:1}],reach:false,way:0,calm:false,big:false,queued:false};reset('home');go('plant',{n:'Monstera'})});await W(1200);
 await pg.click('.ch-act');await W(300);r.pHear=await g();await W(900);r.pDry=await g();await W(800+150);r.pSaid1=await g();await W(rm?0:900);r.pSaid2=await g();
 r.pLine=await pg.evaluate(()=>current.querySelector('.ch-tess')?.textContent);
 await W(3500);r.pHome=await g();
 await pg.click('#tess');await W(rm?60:400);r.tap=await g();
 r.errs=errs;await b.close();return r}
(async()=>{for(const [l,m] of [['paper',false],['black',false],['paper',true]]){const r=await run(l,m);
 const up=x=>x&&x.x<-1&&x.y<-1;const chk={
  hear:r.hear.a&&/ch-heard/.test(r.hear.a)&&up(r.hear),
  dry:r.dry.a&&(m?/ch-heard/:/ch-ttl/).test(r.dry.a),
  home:r.home.a===null&&Math.abs(r.home.x)<.6&&Math.abs(r.home.y)<.6,
  no:r.noLine==='No boxes in this house. Bigger numbers instead?'&&(m?/ch-key/.test(r.no1.a):r.no1.a==='you'&&Math.abs(r.no1.x)<1.5)&&/ch-key/.test(r.no2.a)&&up(r.no2),
  stop:r.stopLine==='Stopped, nothing changed'&&r.stop.a==='you'&&r.stop.m>.8,
  page:/ch-heard/.test(r.pHear.a)&&(m?/ch-heard/:/pl-hist/).test(r.pDry.a)&&/pl-hist/.test(r.pSaid1.a)&&(m||/ttl2/.test(r.pSaid2.a))&&r.pLine==='Every plant’s page has it now, not just the monstera’s',
  pHome:r.pHome.a===null,tap:r.tap.a==='you',
  rmSnap:!m||(r.no2.x===r.no1.x),errs:!r.errs.length};
 console.log(Object.values(chk).every(Boolean)?'ok':'FAIL',l,m?'rm':'',JSON.stringify(chk));if(!Object.values(chk).every(Boolean)||process.env.V)console.log(JSON.stringify(r))}})();
