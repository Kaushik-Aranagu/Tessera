// 389: the walk goes up on the board. Log on the Deck lifts "yesterday's walk, 32 min" off the action word; the words
// rise onto the blackboard and, where they land, the chalk takes them over letter by letter (the type is rubbed away
// just behind the chalk's tip). The object moves on to "what you did". Undo wipes the line, leaves a faint ghost that
// fades, and the words come back to the action word. Logging again only says how. The line stays on the board when
// he comes back. Paper, black; Reduce Motion: in place, no flight, no ghost.
const {chromium}=require('/opt/node22/lib/node_modules/playwright');
async function run(look,rm){const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
 const pg=await b.newPage({viewport:{width:402,height:874},reducedMotion:rm?'reduce':'no-preference'});const errs=[];pg.on('pageerror',e=>errs.push(e.message));
 await pg.goto('file://'+__dirname+'/index.html');await pg.waitForTimeout(600);await pg.evaluate(l=>setLook(l),look);
 await pg.evaluate(()=>{reset('home');go('training')});await pg.waitForTimeout(2000);
 const toLog=async()=>{const ab=await pg.evaluate(()=>{const r=current.querySelector('.act').getBoundingClientRect();return [r.left+r.width/2,r.top+r.height/2]});
  await pg.mouse.move(ab[0],ab[1]);await pg.mouse.down();for(let j=1;j<=8;j++)await pg.mouse.move(ab[0]-j*12,ab[1]);await pg.mouse.up();await pg.waitForTimeout(700)};await toLog();
 const st=()=>pg.evaluate(()=>{const cv=current.querySelector('canvas.tboard'),d=cv.getContext('2d').getImageData(52,640,300,36).data;let lit=0;for(let i=0;i<d.length;i+=4)if(d[i]*.3+d[i+1]*.59+d[i+2]*.11>150)lit++;
  const f=__dk.fly,cl=f&&f.style.clipPath.match(/ ([\d.]+)%\)$/);return {ob:current.querySelector('.act .ao').textContent,walked:__dk.walked,p:__dk.p,g:__dk.g,fly:f?f.textContent:null,clip:cl?+cl[1]:null,lit,rc:(current.querySelector('.receipt')||{}).textContent||''}});
 const r={look,rm};r.before=await st();
 await pg.click('.act');await pg.waitForTimeout(rm?60:200);r.mid=await st();
 if(!rm){for(let k=0;k<60;k++){const s=await st();if(s.p>.2&&s.p<.85){r.hand=s;break}await pg.waitForTimeout(15)}}
 await pg.waitForTimeout(rm?100:1300);r.end=await st();
 r.geom=await pg.evaluate(()=>({right:26+__dk.cw(),bottom:338}));
 await pg.click('.receipt button');await pg.waitForTimeout(rm?60:700);r.undone=await st();await pg.waitForTimeout(rm?100:3000);r.gone=await st();
 await pg.click('.act');await pg.waitForTimeout(rm?100:1600);await pg.click('.act');await pg.waitForTimeout(150);r.again=await st();
 await pg.evaluate(()=>{reset('home');go('training')});await pg.waitForTimeout(2000);await toLog();r.back=await st();
 r.errs=errs;await b.close();return r}
(async()=>{for(const [l,m] of [['paper',false],['black',false],['paper',true]]){const r=await run(l,m);
 const chk={start:r.before.ob==='yesterday’s walk, 32 min'&&!r.before.walked&&r.before.p===0,
  lift:r.mid.ob==='what you did'&&r.mid.rc==='Walk, 32 min, logged Undo'&&(m?r.mid.fly===null&&r.mid.p===1:r.mid.fly!==null),
  hand:m||(!!r.hand&&r.hand.fly==='Yesterday’s walk, 32 min'&&r.hand.clip>0&&r.hand.clip<100),
  chalk:r.end.p===1&&r.end.fly===null&&r.end.lit>r.before.lit+40,
  room:r.geom.right<228&&r.geom.bottom<342,
  undo:!r.undone.walked&&r.undone.p===0&&r.undone.ob==='yesterday’s walk, 32 min'&&(m?r.undone.g===0:r.undone.g>0),
  ghost:r.gone.g===0&&r.gone.lit<=r.before.lit+10,
  again:r.again.rc==='Say what you did, Tess files it'&&r.again.walked,
  back:r.back.p===1&&r.back.ob==='what you did'&&r.back.lit>r.before.lit+40,
  stop:![r.mid,r.end,r.again].some(s=>/\.\s*(Undo)?$/.test(s.rc)),errs:!r.errs.length};
 const ok=Object.values(chk).every(Boolean);console.log(ok?'ok':'FAIL',l,m?'rm':'',JSON.stringify(chk));if(!ok||process.env.V)console.log(JSON.stringify(r))}})();
