// 378: one plant's own page. On the orchid's page "just for the orchid, show its misting" writes the orchid's own layer,
// not the class's: ghost and line, Tess and the receipt name the orchid, the part links to the Water houseplants
// routine, the fern's page doesn't get it, Undo un-dries it, a touch stops it. Paper, black, Reduce Motion.
const {chromium}=require('/opt/node22/lib/node_modules/playwright');
async function run(look,rm){const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
 const pg=await b.newPage({viewport:{width:402,height:874},reducedMotion:rm?'reduce':'no-preference'});const errs=[];pg.on('pageerror',e=>errs.push(e.message));
 await pg.goto('file://'+__dirname+'/index.html');await pg.waitForTimeout(600);await pg.evaluate(l=>setLook(l),look);
 await pg.evaluate(()=>{ROOMS.chart.saved={at:6,plants:[{n:'Orchid',d:6},{n:'Monstera',d:4},{n:'Fern',d:2},{n:'Basil',d:1}],reach:false,way:0,calm:false,big:false,queued:false};go('plant',{n:'Orchid'})});await pg.waitForTimeout(1200);
 const st=()=>pg.evaluate(()=>{const q=s=>current.querySelector(s);return {id:current.dataset.id,ttl:q('.ttl2')?.textContent,mist:window.__pl?__pl.mist:null,ms:q('.pl-mist')?.textContent,msTop:q('.pl-mist')?.style.top,gh:q('.pl-mist')?.classList.contains('gh'),
  hs:q('.pl-hist')?.textContent.slice(0,18),ts:q('.ch-tess,.ch-heard')?.textContent,tsTop:q('.ch-tess,.ch-heard')?.style.top,act:q('.ch-act')?.textContent,rc:q('.receipt')?.textContent||'',lines:[...current.querySelectorAll('.ch-dry')].map(l=>l.style.top).join(','),
  cut:[...current.querySelectorAll('.pl-hist,.pl-mist')].some(e=>e.scrollWidth>e.clientWidth+1)}});
 const ov=()=>pg.evaluate(()=>{const els=[...current.querySelectorAll('.ttl2,.ch-line,.pl-key,.ch-cap,.pl-care,.pl-hist,.pl-mist,.ch-tess,.ch-heard,.ch-act,.receipt')];const rg=e=>{const r=document.createRange();r.selectNodeContents(e);return r.getBoundingClientRect()};const hits=[];
  for(let i=0;i<els.length;i++)for(let j=i+1;j<els.length;j++){const a=rg(els[i]),c=rg(els[j]);if(a.width&&c.width&&a.left<c.right-1&&c.left<a.right-1&&a.top<c.bottom-1&&c.top<a.bottom-1)hits.push(els[i].className+'/'+els[j].className)}
  const t=document.querySelector('#tess').getBoundingClientRect();els.forEach(e=>{const a=rg(e);if(a.width&&a.left<t.right&&t.left<a.right&&a.top<t.bottom&&t.top<a.bottom)hits.push(e.className+'/tess')});return hits});
 const r={look,rm};
 await pg.click('.ch-act');await pg.waitForTimeout(400);// watered
 await pg.click('.ch-act');await pg.waitForTimeout(2300);r.hist=await st();// every plant's page gets the dates
 await pg.click('.ch-act');await pg.waitForTimeout(rm?100:900);r.drying=await st();r.ovDry=await ov();await pg.waitForTimeout(rm?2100:1500);r.set=await st();r.ovSet=await ov();
 if(look==='paper'&&!rm)await pg.screenshot({path:__dirname+'/OB.png'});
 r.linkColor=await pg.evaluate(()=>getComputedStyle(current.querySelector('.pl-ln')).color);
 await pg.click('.pl-ln');await pg.waitForTimeout(900);r.routine=await pg.evaluate(()=>current.dataset.id+'|'+current.querySelector('.backw')?.textContent);
 await pg.evaluate(()=>back());await pg.waitForTimeout(900);r.backOn=await st();
 await pg.evaluate(()=>back());await pg.waitForTimeout(800);await pg.evaluate(()=>go('plant',{n:'Fern'}));await pg.waitForTimeout(1200);await pg.click('.ch-act');await pg.waitForTimeout(400);r.fern=await st();
 await pg.evaluate(()=>back());await pg.waitForTimeout(800);await pg.evaluate(()=>go('plant',{n:'Orchid'}));await pg.waitForTimeout(1200);r.again=await st();
 // Undo un-dries it: the receipt is gone after leaving, so say it fresh: un-set it first through the hook
 await pg.evaluate(()=>{__pl.ov.mist=false;back()});await pg.waitForTimeout(800);await pg.evaluate(()=>go('plant',{n:'Orchid'}));await pg.waitForTimeout(1200);
 await pg.click('.ch-act');await pg.waitForTimeout(2300);await pg.click('.receipt button');await pg.waitForTimeout(rm?100:300);r.undoing=await st();await pg.waitForTimeout(700);r.undone=await st();
 if(!rm){await pg.click('.ch-act');await pg.waitForTimeout(900);await pg.click('.ch-heard');await pg.waitForTimeout(900);r.stopped=await st()}
 r.errs=errs;await b.close();return r}
(async()=>{for(const [l,m] of [['paper',false],['black',false],['paper',true]])console.log(JSON.stringify(await run(l,m)))})();
