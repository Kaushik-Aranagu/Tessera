const {chromium}=require('/opt/node22/lib/node_modules/playwright');
const look=process.argv[2]||'paper';
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage({viewport:{width:1300,height:1000}});
const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(2000);
if(look==='black')await p.click('#lk-black');
const ph=await p.$('#phone');
for(const f of ['even','columns','time','ranked','tess']){await p.evaluate(k=>window.__th('page-'+k),f);await p.waitForTimeout(f==='tess'?4200:2600);await p.evaluate(()=>scrollTo(0,0));await ph.screenshot({path:'P'+look[0]+f+'.png'});
 console.log(f,await p.evaluate(()=>{const pg=current.querySelector('.lpg');if(!pg)return 'no page';const P=pg.getBoundingClientRect();const runs=[];pg.querySelectorAll('.lt,.lv,.ls,.ltm').forEach(e=>{const r=e.getBoundingClientRect();if(r.width>0)runs.push([e.className,e.textContent,r])});
  const out=[];runs.forEach(([c,t,r])=>{if(r.left<P.left-1||r.right>P.right+1||r.bottom>P.bottom+1)out.push('outside '+t)});
  for(let i=0;i<runs.length;i++)for(let j=i+1;j<runs.length;j++){const a=runs[i][2],b=runs[j][2];if(Math.min(a.right,b.right)-Math.max(a.left,b.left)>1&&Math.min(a.bottom,b.bottom)-Math.max(a.top,b.top)>1)out.push(runs[i][1]+' x '+runs[j][1])}
  return pg.querySelectorAll('.lvr').length+' rows '+(out.join('; ')||'clear')}))}
console.log(look,JSON.stringify(errs));await b.close()})();
