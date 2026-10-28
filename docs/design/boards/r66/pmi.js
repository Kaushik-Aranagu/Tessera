// 379: misted in the routine, the orchid's page already knows. From the orchid's page the routine opens with "Orchid"
// as its back word and the step's "orchid" in olive; checking the step off makes the page read "Last misted today",
// the day lifts once, Tess says where it came from. Undo in the routine puts Thursday back. Paper, black, Reduce Motion.
const {chromium}=require('/opt/node22/lib/node_modules/playwright');
async function run(look,rm){const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
 const pg=await b.newPage({viewport:{width:402,height:874},reducedMotion:rm?'reduce':'no-preference'});const errs=[];pg.on('pageerror',e=>errs.push(e.message));
 await pg.goto('file://'+__dirname+'/index.html');await pg.waitForTimeout(600);await pg.evaluate(l=>setLook(l),look);
 await pg.evaluate(()=>{ROOMS.chart.saved={at:6,plants:[{n:'Orchid',d:6},{n:'Monstera',d:4},{n:'Fern',d:2},{n:'Basil',d:1}],reach:false,way:0,calm:false,big:false,queued:false};go('plant',{n:'Orchid'})});await pg.waitForTimeout(1200);
 const pl=()=>pg.evaluate(()=>{const q=s=>current.querySelector(s);return {id:current.dataset.id,ms:q('.pl-mist')?.textContent,ts:q('.ch-tess,.ch-heard')?.textContent,lift:q('.pl-w')?q('.pl-w').getAnimations().length:0}});
 const r={look,rm};
 await pg.click('.ch-act');await pg.waitForTimeout(400);await pg.click('.ch-act');await pg.waitForTimeout(2300);await pg.click('.ch-act');await pg.waitForTimeout(2300);r.before=await pl();
 await pg.click('.pl-ln');await pg.waitForTimeout(900);
 r.routine=await pg.evaluate(()=>({back:current.querySelector('.backw').textContent,came:[...current.querySelectorAll('.came')].map(e=>e.textContent+'|'+getComputedStyle(e).color+'|'+getComputedStyle(e).fontStyle),steps:[...current.querySelectorAll('.step .nm')].map(e=>e.textContent)}));
 const mi=await pg.evaluate(()=>[...current.querySelectorAll('.step')].find(e=>/orchid/.test(e.textContent)).dataset.i);
 await pg.click('.step[data-i="'+mi+'"]');await pg.waitForTimeout(rm?200:900);r.checked=await pg.evaluate(()=>({mist:PLANTMIST.Orchid,rc:current.querySelector('.receipt')?.textContent||''}));
 if(look==='paper'&&!rm)await pg.screenshot({path:__dirname+'/MI1.png'});
 await pg.evaluate(()=>back());await pg.waitForTimeout(rm?300:450);r.back=await pl();await pg.waitForTimeout(800);
 if(look==='paper'&&!rm)await pg.screenshot({path:__dirname+'/MI2.png'});
 r.overlap=await pg.evaluate(()=>{const els=[...current.querySelectorAll('.ttl2,.ch-line,.pl-key,.ch-cap,.pl-care,.pl-hist,.pl-mist,.ch-tess,.ch-heard,.ch-act,.receipt')];const rg=e=>{const r=document.createRange();r.selectNodeContents(e);return r.getBoundingClientRect()};const hits=[];
  for(let i=0;i<els.length;i++)for(let j=i+1;j<els.length;j++){const a=rg(els[i]),c=rg(els[j]);if(a.width&&c.width&&a.left<c.right-1&&c.left<a.right-1&&a.top<c.bottom-1&&c.top<a.bottom-1)hits.push(els[i].className+'/'+els[j].className)}return hits});
 // again: no change, no line
 await pg.evaluate(()=>back());await pg.waitForTimeout(800);await pg.evaluate(()=>go('plant',{n:'Orchid'}));await pg.waitForTimeout(1200);r.again=await pl();
 // back in the routine the step shows done; unchecking puts Thursday back, and so does Undo
 await pg.click('.pl-ln');await pg.waitForTimeout(900);r.shownDone=await pg.evaluate(mi=>current.querySelector('.step[data-i="'+mi+'"]').classList.contains('done'),mi);
 await pg.click('.step[data-i="'+mi+'"]');await pg.waitForTimeout(rm?200:900);r.unchecked=await pg.evaluate(()=>PLANTMIST.Orchid);
 await pg.click('.step[data-i="'+mi+'"]');await pg.waitForTimeout(rm?200:900);await pg.click('.receipt button');await pg.waitForTimeout(300);r.undone=await pg.evaluate(()=>PLANTMIST.Orchid);
 // opened from the Watch, nothing is marked and the back word is the grove
 await pg.evaluate(()=>{back();});await pg.waitForTimeout(800);await pg.evaluate(()=>go('routine',{id:'plants'}));await pg.waitForTimeout(900);r.plain=await pg.evaluate(()=>({back:current.querySelector('.backw').textContent,came:current.querySelectorAll('.came').length}));
 r.errs=errs;await b.close();return r}
(async()=>{for(const [l,m] of [['paper',false],['black',false],['paper',true]])console.log(JSON.stringify(await run(l,m)))})();
