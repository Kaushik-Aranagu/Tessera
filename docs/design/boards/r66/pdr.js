// 375: "Give each plant a door" fills the doors place with the room's own dial (keystone order, summary on the left),
// a door opens the plant's plain page, watering there needs no Allow, and back in the room the keystone and doors show it.
const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const out={};for(const look of ['paper','black']){const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
 const pg=await b.newPage({viewport:{width:402,height:874}});const errs=[];pg.on('pageerror',e=>errs.push(e.message));
 await pg.goto('file://'+__dirname+'/index.html');await pg.waitForTimeout(600);await pg.evaluate(l=>setLook(l),look);
 await pg.evaluate(()=>go('chart'));await pg.waitForTimeout(1500);
 const r={};const rows=()=>pg.evaluate(()=>{const d=document.querySelector('.chart .ch-dial');if(!d)return null;return {rows:[...d.children].map(x=>x.textContent),focus:[...d.children].find(x=>x.style.opacity==='1')?.textContent,color:getComputedStyle([...d.children].find(x=>x.style.opacity==='1')).color,sum:document.querySelector('.ch-dsum').textContent}});
 for(let i=0;i<5;i++){await pg.evaluate(()=>__ch.say());await pg.waitForTimeout(2300)}
 r.before=await rows();await pg.evaluate(()=>__ch.say());await pg.waitForTimeout(800);
 r.drying=await pg.evaluate(()=>document.querySelector('.ch-doors')?.className);await pg.waitForTimeout(1600);
 r.set=await rows();r.rc=await pg.evaluate(()=>document.querySelector('.chart .receipt')?.textContent);
 r.pl=await pg.evaluate(()=>[...document.querySelectorAll('.chart .ch-pl')].map(p=>p.className.replace('ch-pl','').trim()||'-').join('|'));
 // turn to the next door, then open it
 let c=await pg.evaluate(()=>{const d=[...document.querySelector('.ch-dial').children].find(x=>x.style.transform.startsWith('translateY(80px)'));const q=d.getBoundingClientRect();return [q.x+q.width-30,q.y+q.height/2]});
 await pg.mouse.click(c[0],c[1]);await pg.waitForTimeout(400);r.turned=await rows();
 r.sel=await pg.evaluate(()=>__ch.sel);
 c=await pg.evaluate(()=>{const d=[...document.querySelector('.ch-dial').children].find(x=>x.style.opacity==='1');const q=d.getBoundingClientRect();return [q.x+q.width-30,q.y+q.height/2]});
 await pg.mouse.click(c[0],c[1]);await pg.waitForTimeout(1300);
 const page=()=>pg.evaluate(()=>({id:current.dataset.id,ttl:current.querySelector('.ttl2')?.textContent,line:current.querySelector('.ch-line')?.textContent,key:current.querySelector('.pl-key')?.textContent,act:current.querySelector('.ch-act')?.textContent,rc:current.querySelector('.receipt')?.textContent||''}));
 r.page=await page();await pg.click('.ch-act');await pg.waitForTimeout(500);r.watered=await page();
 // nothing on the page overlaps
 r.pageOverlap=await pg.evaluate(()=>{const els=[...current.querySelectorAll('.backw,.ttl2,.ch-line,.pl-key,.ch-cap,.pl-care,.ch-tess,.ch-act,.receipt')];const rg=e=>{const r=document.createRange();r.selectNodeContents(e);return r.getBoundingClientRect()};const hits=[];
  for(let i=0;i<els.length;i++)for(let j=i+1;j<els.length;j++){const a=rg(els[i]),b=rg(els[j]);if(a.width&&b.width&&a.left<b.right&&b.left<a.right&&a.top<b.bottom&&b.top<a.bottom)hits.push(els[i].className+'/'+els[j].className)}return hits});
 await pg.evaluate(()=>back());await pg.waitForTimeout(1500);
 r.back={id:await pg.evaluate(()=>current.dataset.id),line:await pg.evaluate(()=>document.querySelector('.ch-line').textContent),key:await pg.evaluate(()=>[...document.querySelectorAll('.ch-key b')].map(b=>b.textContent).join(' ')),doors:await rows()};
 // the rest of the sentences: the wish and reach lines don't touch the doors
 for(let i=0;i<3;i++){await pg.evaluate(()=>__ch.say());await pg.waitForTimeout(2300)}
 r.at=await pg.evaluate(()=>__ch.at);
 r.overlap=await pg.evaluate(()=>{const ds=document.querySelector('.ch-doors').getBoundingClientRect();const hits=[];document.querySelectorAll('.chart .ch-c:not(.ch-doors),.chart .ch-act,.chart .receipt').forEach(e=>{const rg=document.createRange();rg.selectNodeContents(e);const q=rg.getBoundingClientRect();if(q.width&&q.left<ds.right&&ds.left<q.right&&q.top<ds.bottom&&ds.top<q.bottom)hits.push(e.className)});
  const t=document.querySelector('#tess').getBoundingClientRect();const sm=document.querySelector('.ch-dsum').getBoundingClientRect();if(t.left<ds.right&&t.top<ds.bottom&&t.bottom>ds.top&&t.right>ds.left)hits.push('tess');return hits});
 if(look==='paper')await pg.screenshot({path:__dirname+'/DR.png'});
 r.errs=errs;out[look]=r;await b.close()}console.log(JSON.stringify(out))})();
