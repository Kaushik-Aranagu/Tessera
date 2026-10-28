// 390: no door page's caption ends in a full stop (the Oct 26 rule), in every room, at level 1 and level 2
const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const pg=await b.newPage({viewport:{width:402,height:874}});const errs=[];pg.on('pageerror',e=>errs.push(e.message));
 await pg.goto('file://'+__dirname+'/index.html');await pg.waitForTimeout(600);
 const rooms=await pg.evaluate(()=>Object.keys(SCREENS).filter(k=>k.startsWith('l1_')).map(k=>[k.slice(3),8]));const seen=new Set();const bad=[];let n=0;
 for(const [r,k] of rooms)for(let d=0;d<k;d++){for(const lv of ['l1_','l2_']){await pg.evaluate(([r,d,lv])=>{reset('home');go(lv+r,{door:d})},[r,d,lv]);await pg.waitForTimeout(250);
  const [t,dt]=await pg.evaluate(()=>{const c=current.querySelector('.lcap'),d=current.querySelector('.ldt b');return [c?c.textContent:null,d?d.textContent:'']});const key=lv+r+dt;if(seen.has(key))continue;seen.add(key);n++;if(t==null||/\.\s*$/.test(t))bad.push(lv+r+' '+d+': '+t)}}
 console.log(bad.length||errs.length?'FAIL':'ok',n+' pages',JSON.stringify(bad),errs.slice(0,3));await b.close()})();
