// 385: the watered plant drinks. Watering the orchid in the room: its new color climbs up from the foot of its number
// and name (midway, the foot is the new color and the top is still the old); Undo: the thirst sinks back in from the
// top. Afterwards nothing is left on the element. The door in focus drinks too. Text is right throughout. Paper,
// black; Reduce Motion: in place.
const {chromium}=require('/opt/node22/lib/node_modules/playwright');const {execFileSync}=require('child_process');
const S='/tmp/claude-0/-home-user/5f3facde-568a-5b31-9bfd-c9653804b55e/scratchpad/';
const rgb=s=>s.match(/\d+/g).slice(0,3).map(Number);
async function run(look,rm){const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
 const pg=await b.newPage({viewport:{width:402,height:874},deviceScaleFactor:3,reducedMotion:rm?'reduce':'no-preference'});const errs=[];pg.on('pageerror',e=>errs.push(e.message));
 await pg.goto('file://'+__dirname+'/index.html');await pg.waitForTimeout(600);await pg.evaluate(l=>setLook(l),look);
 await pg.evaluate(()=>{ROOMS.chart.saved={at:9,plants:[{n:'Orchid',d:6},{n:'Monstera',d:4},{n:'Fern',d:2},{n:'Basil',d:1}],reach:true,way:0,calm:false,big:false,queued:false};ROOMS.chart.door='Orchid';reset('home');go('chart')});await pg.waitForTimeout(1600);
 const r={look,rm};
 const freeze=(sel,t)=>pg.evaluate(([sel,t])=>{const e=current.querySelector(sel);if(!e)return null;const as=e.getAnimations();const dk=as.find(a=>a._drink);as.filter(a=>!a._drink).forEach(a=>{if(a.effect.getTiming().iterations===Infinity){a.currentTime=0;a.pause()}else a.finish()});
  if(dk){dk.pause();let lo=0,hi=760;for(let i=0;i<14;i++){const m=(lo+hi)/2;dk.currentTime=m;const y=parseFloat(getComputedStyle(e).backgroundPositionY);if((dk._drink==='up')?(y<t):(y>t))lo=m;else hi=m}}const s=e.style;return {drink:dk?dk._drink:null,img:s.getPropertyValue('background-image'),text:e.textContent,color:getComputedStyle(e).color}},[sel,t]);
 const shot=async(sel,name,c0,c1)=>{const box=await pg.evaluate(s=>{const r=current.querySelector(s).getBoundingClientRect();return {x:r.left,y:r.top,width:r.width,height:r.height}},sel);
  await pg.screenshot({path:S+name,clip:box});return JSON.parse(execFileSync('python3',['-I','-W','ignore',__dirname+'/pdi_an.py',S+name,JSON.stringify(c0),JSON.stringify(c1)]).toString())};
 const wine=rgb(await pg.evaluate(()=>getComputedStyle(current.querySelector('.ch-key b[data-k="Orchid"]')).color));
 const B='.ch-key b[data-k="Orchid"]',N='.ch-key span[data-n="Orchid"]';
 r.before=await pg.evaluate(()=>current.querySelector('.ch-line').textContent);
 await pg.click('.ch-act');await pg.waitForTimeout(470);
 r.wB=await freeze(B,50);r.wN=await freeze(N,50);
 const inkC=rgb(await pg.evaluate(()=>{const x=document.createElement('b');x.style.color='var(--ink)';current.appendChild(x);const c=getComputedStyle(x).color;x.remove();return c}));
 if(!rm){r.wBs=await shot(B,'pdi_w.png',wine,inkC);r.wNs=await shot(N,'pdi_wn.png',rgb(r.wN.img.match(/rgb\([^)]*\)/)[0]),inkC)}
 r.door=await pg.evaluate(()=>{const f=[...current.querySelectorAll('.ch-dial .d')].find(x=>x.style.opacity==='1');const a=f&&f.getAnimations().find(a=>a._drink);return f?{n:f.querySelector('span').textContent,drink:a?a._drink:null}:null});
 await pg.evaluate(()=>document.getAnimations().forEach(a=>{if(a.playState==='paused')a.play()}));await pg.waitForTimeout(1000);
 r.wEnd=await pg.evaluate(s=>{const e=current.querySelector(s);return {text:e.textContent,img:e.style.getPropertyValue('background-image'),fill:e.style.getPropertyValue('-webkit-text-fill-color'),color:getComputedStyle(e).color}},B);
 r.line=await pg.evaluate(()=>current.querySelector('.ch-line').textContent);
 // Undo
 await pg.click('.receipt button');await pg.waitForTimeout(470);r.uB=await freeze(B,50);
 if(!rm)r.uBs=await shot(B,'pdi_u.png',inkC,wine);
 await pg.evaluate(()=>document.getAnimations().forEach(a=>{if(a.playState==='paused')a.play()}));await pg.waitForTimeout(1000);
 r.uEnd=await pg.evaluate(s=>{const e=current.querySelector(s);return {text:e.textContent,img:e.style.getPropertyValue('background-image'),cls:e.parentElement.className}},B);
 r.errs=errs;await b.close();return r}
(async()=>{for(const [l,m] of [['paper',false],['black',false],['paper',true]]){const r=await run(l,m);
 const chk=m?{none:!r.wB.drink&&!r.wB.img&&!r.uB.drink&&!r.door?.drink,text:r.wEnd.text==='0'&&r.uEnd.text==='6',errs:!r.errs.length}:{
  up:r.wB.drink==='up'&&r.wBs.bot>.8&&r.wBs.top<.2,name:r.wN.drink==='up'&&r.wNs.bot>.7&&r.wNs.top<.3,door:r.door&&r.door.n==='Orchid'&&r.door.drink==='up',
  clean:!r.wEnd.img&&!r.wEnd.fill&&r.wEnd.text==='0',line:r.line==='4 plants, the monstera is thirsty',
  down:r.uB.drink==='down'&&r.uBs.top>.8&&r.uBs.bot<.2,back:r.uEnd.text==='6'&&!r.uEnd.img&&/th/.test(r.uEnd.cls),errs:!r.errs.length};
 const ok=Object.values(chk).every(Boolean);console.log(ok?'ok':'FAIL',l,m?'rm':'',JSON.stringify(chk));if(!ok||process.env.V)console.log(JSON.stringify(r))}})();
