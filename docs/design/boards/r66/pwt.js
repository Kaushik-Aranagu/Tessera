// 386: Tess watches with him. Turning the room's dial, her eyes follow the door in focus, then come home; going round
// past the zero notch she blinks once; opening a door, her eyes ride the flying name and land on the page's title,
// then come home. Paper, black; Reduce Motion: the eyes still follow the dial (placed at once), no flight to ride.
const {chromium}=require('/opt/node22/lib/node_modules/playwright');
async function run(look,rm){const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
 const pg=await b.newPage({viewport:{width:402,height:874},reducedMotion:rm?'reduce':'no-preference'});const errs=[];pg.on('pageerror',e=>errs.push(e.message));
 await pg.goto('file://'+__dirname+'/index.html');await pg.waitForTimeout(600);await pg.evaluate(l=>setLook(l),look);
 await pg.evaluate(()=>{ROOMS.chart.saved={at:9,plants:[{n:'Orchid',d:6},{n:'Monstera',d:4},{n:'Fern',d:2},{n:'Basil',d:1}],reach:true,way:0,calm:false,big:false,queued:false};ROOMS.chart.door='Orchid';reset('home');go('chart')});await pg.waitForTimeout(1600);
 const g=()=>pg.evaluate(()=>__tgaze()),W=ms=>pg.waitForTimeout(ms),r={look,rm};
 const rows=()=>pg.evaluate(()=>[...current.querySelectorAll('.ch-dial .d')].map(d=>({n:d.querySelector('span').textContent,o:d.style.opacity})));
 const clickRow=n=>pg.evaluate(n=>{[...current.querySelectorAll('.ch-dial .d')].find(d=>d.querySelector('span').textContent===n).click()},n);
 r.rows0=await rows();
 await clickRow('Monstera');await W(250);r.turn=await g();r.focus=(await rows()).find(x=>x.o==='1').n;
 await W(1500);r.home=await g();
 // back to the orchid, then one more up: past the zero notch to the basil
 await clickRow('Orchid');await W(300);const t0=await pg.evaluate(()=>performance.now());await clickRow('Basil');r.blink=await pg.evaluate(t0=>(window.__tblink||0)>t0,t0);r.focus2=(await rows()).find(x=>x.o==='1').n;
 await W(300);await clickRow('Fern');await W(300);r.noBlink=await pg.evaluate(()=>(window.__tblink||0)<performance.now()-200);await clickRow('Monstera');await W(250);await clickRow('Orchid');
 await W(1500);
 // open the orchid's door
 await clickRow('Orchid');await W(180);r.ride=await g();r.id=await pg.evaluate(()=>current.dataset.id);await W(rm?50:520);r.land=await g();await W(1700);r.after=await g();
 r.errs=errs;await b.close();return r}
(async()=>{for(const [l,m] of [['paper',false],['black',false],['paper',true]]){const r=await run(l,m);
 const chk={turn:r.turn.a==='d'&&r.turn.y<-1&&r.focus==='Monstera',home:r.home.a===null&&Math.abs(r.home.y)<.6,
  blink:m?!r.blink:r.blink&&r.focus2==='Basil',noBlink:r.noBlink,
  ride:r.id==='plant'&&(m?r.ride.a===null:/tv/.test(r.ride.a)),land:m?r.land.a===null:r.land.a==='ttl2',after:r.after.a===null,errs:!r.errs.length};
 const ok=Object.values(chk).every(Boolean);console.log(ok?'ok':'FAIL',l,m?'rm':'',JSON.stringify(chk));if(!ok||process.env.V)console.log(JSON.stringify(r))}})();
