// 376: a change said on one plant's page is the Plant class's page, so every plant gets it. Ghost and drying line,
// Tess names what it reached, Undo un-dries, touching the words stops it, another plant's page has it. Paper, black, RM.
const {chromium}=require('/opt/node22/lib/node_modules/playwright');
async function run(look,rm){const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
 const pg=await b.newPage({viewport:{width:402,height:874},reducedMotion:rm?'reduce':'no-preference'});const errs=[];pg.on('pageerror',e=>errs.push(e.message));
 await pg.goto('file://'+__dirname+'/index.html');await pg.waitForTimeout(600);await pg.evaluate(l=>setLook(l),look);
 await pg.evaluate(()=>{ROOMS.chart.saved={at:6,plants:[{n:'Orchid',d:6},{n:'Monstera',d:4},{n:'Fern',d:2},{n:'Basil',d:1}],reach:false,way:0,calm:false,big:false,queued:false};go('plant',{n:'Monstera'})});await pg.waitForTimeout(1200);
 const st=()=>pg.evaluate(()=>({id:current.dataset.id,ttl:current.querySelector('.ttl2').textContent,hist:__pl.hist,hs:current.querySelector('.pl-hist').textContent,gh:current.querySelector('.pl-hist').classList.contains('gh'),ts:current.querySelector('.ch-tess,.ch-heard').textContent,act:current.querySelector('.ch-act').textContent,rc:current.querySelector('.receipt')?.textContent||'',lines:current.querySelectorAll('.ch-dry').length,
  cut:(e=>e.scrollWidth>e.clientWidth+1)(current.querySelector('.pl-hist'))}));
 const r={look,rm};await pg.click('.ch-act');await pg.waitForTimeout(400);r.watered=await st();
 await pg.click('.ch-act');await pg.waitForTimeout(rm?100:900);r.drying=await st();await pg.waitForTimeout(rm?2100:1500);r.set=await st();
 r.overlap=await pg.evaluate(()=>{const els=[...current.querySelectorAll('.ttl2,.ch-line,.pl-key,.ch-cap,.pl-care,.pl-hist,.ch-tess,.ch-heard,.ch-act,.receipt')];const rg=e=>{const r=document.createRange();r.selectNodeContents(e);return r.getBoundingClientRect()};const hits=[];
  for(let i=0;i<els.length;i++)for(let j=i+1;j<els.length;j++){const a=rg(els[i]),c=rg(els[j]);if(a.width&&c.width&&a.left<c.right-1&&c.left<a.right-1&&a.top<c.bottom-1&&c.top<a.bottom-1)hits.push(els[i].className+'/'+els[j].className)}
  const t=document.querySelector('#tess').getBoundingClientRect();els.forEach(e=>{const a=rg(e);if(a.width&&a.left<t.right&&t.left<a.right&&a.top<t.bottom&&t.top<a.bottom)hits.push(e.className+'/tess')});return hits});
 // Undo un-dries it
 await pg.click('.receipt button');await pg.waitForTimeout(rm?100:300);r.undoing=await st();await pg.waitForTimeout(600);r.undone=await st();
 if(!rm){// touching his words while it dries stops it
  await pg.click('.ch-act');await pg.waitForTimeout(900);await pg.click('.ch-heard');await pg.waitForTimeout(900);r.stopped=await st()}
 // say it again and let it set, then another plant's page has it
 await pg.click('.ch-act');await pg.waitForTimeout(2300);r.again=await st();
 await pg.evaluate(()=>back());await pg.waitForTimeout(800);await pg.evaluate(()=>go('plant',{n:'Fern'}));await pg.waitForTimeout(1200);r.fern=await st();
 if(look==='paper'&&!rm)await pg.screenshot({path:__dirname+'/CV.png'});
 r.errs=errs;await b.close();return r}
(async()=>{console.log(JSON.stringify(await run('paper',false)));console.log(JSON.stringify(await run('black',false)));console.log(JSON.stringify(await run('paper',true)))})();
