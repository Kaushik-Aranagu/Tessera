const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const pg=await b.newPage({viewport:{width:402,height:874}});const errs=[];pg.on('pageerror',e=>errs.push(e.message));
await pg.goto('file://'+__dirname+'/index.html');await pg.waitForTimeout(600);
await pg.evaluate(s=>go(s),process.argv[2]||'chartfull');await pg.waitForTimeout(1800);
await pg.screenshot({path:'CF1.png'});
// overlap check among visible text boxes on the screen
const r=await pg.evaluate(()=>{const scr=[...document.querySelectorAll('.screen')].pop()||document.body;const els=[...document.querySelectorAll('.ttl,.swx,.swn,.ch-key,.lcap,.one,.dial,.lsum,.act')].filter(e=>e.offsetParent);
 const R=els.map(e=>[e.className.split(' ')[0],e.getBoundingClientRect()]);const ov=[];
 for(let i=0;i<R.length;i++)for(let j=i+1;j<R.length;j++){const a=R[i][1],c=R[j][1];const x=Math.min(a.right,c.right)-Math.max(a.left,c.left),y=Math.min(a.bottom,c.bottom)-Math.max(a.top,c.top);if(x>1&&y>1)ov.push(R[i][0]+'/'+R[j][0]+' '+Math.round(x)+'x'+Math.round(y))}
 return {n:els.length,ov,clip:els.filter(e=>e.scrollWidth>e.clientWidth+1).map(e=>e.className)}});
console.log(JSON.stringify(r),errs);await b.close()})();
