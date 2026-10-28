// 387: everyone's had a drink. Watering the plants one by one in the room, nothing is said until the last thirsty one:
// then Tess says "Everyone’s had a drink", word by word, looking at the keystone, and her eyes smile once and open
// again. Undo takes the line back and the basil is thirsty again. Paper, black; Reduce Motion: the line and the smile
// are simply there, then gone.
const {chromium}=require('/opt/node22/lib/node_modules/playwright');
const S='/tmp/claude-0/-home-user/5f3facde-568a-5b31-9bfd-c9653804b55e/scratchpad/';
async function run(look,rm){const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
 const pg=await b.newPage({viewport:{width:402,height:874},reducedMotion:rm?'reduce':'no-preference'});const errs=[];pg.on('pageerror',e=>errs.push(e.message));
 await pg.goto('file://'+__dirname+'/index.html');await pg.waitForTimeout(600);await pg.evaluate(l=>setLook(l),look);
 await pg.evaluate(()=>{ROOMS.chart.saved={at:9,plants:[{n:'Orchid',d:6},{n:'Monstera',d:4},{n:'Fern',d:2},{n:'Basil',d:1}],reach:true,way:0,calm:false,big:false,queued:false};ROOMS.chart.door='Orchid';reset('home');go('chart')});await pg.waitForTimeout(1600);
 const st=()=>pg.evaluate(()=>{const t=current.querySelector('.ch-tess'),r=current.querySelector('.receipt');return {line:current.querySelector('.ch-line').textContent,tess:t?t.textContent:'',words:t?t.querySelectorAll('.sw-w').length:0,joy:__tjoy(),gaze:__tgaze().a,rc:r?r.textContent:''}});
 const r={look,rm,steps:[]};
 for(let i=0;i<3;i++){await pg.click('.ch-act');await pg.waitForTimeout(1300);r.steps.push(await st())}
 await pg.click('.ch-act');await pg.waitForTimeout(rm?80:450);r.last=await st();
 if(!rm&&look==='paper'){const box=await pg.evaluate(()=>{const e=$('#tess').getBoundingClientRect();return {x:e.left,y:e.top,width:e.width,height:e.height}});await pg.screenshot({path:S+'pjy_face.png',clip:box});await pg.screenshot({path:S+'pjy_room.png'})}
 await pg.waitForTimeout(2600);r.after=await st();
 // overlap: the line against every other place in the room
 r.overlap=await pg.evaluate(()=>{const t=current.querySelector('.ch-tess');if(!t)return 'no line';const a=t.getBoundingClientRect();return [...current.querySelectorAll('.ch-c,.ch-act,.receipt,.ch-dial')].filter(e=>e!==t&&!t.contains(e)&&!e.contains(t)).filter(e=>{const b=e.getBoundingClientRect();return b.width&&a.left<b.right-1&&b.left<a.right-1&&a.top<b.bottom-1&&b.top<a.bottom-1}).map(e=>e.className)});
 await pg.click('.receipt button');await pg.waitForTimeout(1200);r.undone=await st();
 r.errs=errs;await b.close();return r}
(async()=>{for(const [l,m] of [['paper',false],['black',false],['paper',true]]){const r=await run(l,m);
 const chk={quiet:r.steps.every(s=>!s.tess&&s.joy===0),line:r.last.tess==='Everyone’s had a drink'&&r.last.line==='4 plants, all watered',
  spoken:m?r.last.words===0:r.last.words===4,joy:r.last.joy>(m?.99:.5),gaze:/ch-key/.test(r.last.gaze),after:r.after.joy===0&&r.after.tess==='Everyone’s had a drink',
  clear:Array.isArray(r.overlap)&&!r.overlap.length,undo:r.undone.tess===''&&r.undone.line==='4 plants, the basil is thirsty'&&r.undone.joy===0,errs:!r.errs.length};
 const ok=Object.values(chk).every(Boolean);console.log(ok?'ok':'FAIL',l,m?'rm':'',JSON.stringify(chk));if(!ok||process.env.V)console.log(JSON.stringify(r))}})();
