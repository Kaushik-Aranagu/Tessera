const {chromium}=require('/opt/node22/lib/node_modules/playwright');
const look=process.argv[2]||'paper';
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage({viewport:{width:1300,height:1000}});
const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(2500);
if(look==='black')await p.click('#lk-black');await p.evaluate(()=>scrollTo(0,0));await p.waitForTimeout(600);
const ph=await p.$('#phone');const one=await p.evaluate(()=>{const r=current.querySelector('.one').getBoundingClientRect();return {x:r.left,y:r.top,w:r.width,h:r.height}});
const clip=async n=>{const bb=await ph.boundingBox();await p.screenshot({path:'F'+look[0]+n+'.png',clip:{x:bb.x,y:one.y-20,width:bb.width,height:one.h+40}})};
for(const [ax,tag] of [['y','u'],['x','a']]){const sx=one.x+one.w*.55,sy=one.y+one.h*.85;await p.mouse.move(sx,sy);await p.mouse.down();
 for(let i=1;i<=8;i++){await p.mouse.move(ax==='x'?sx-i*16:sx,ax==='y'?sy-i*9:sy);await p.waitForTimeout(16)}
 await clip(tag+'0');await p.mouse.up();
 for(const t of [70,140,230]){await p.waitForTimeout(t===70?70:t-(t===140?70:140));await clip(tag+t)}await p.waitForTimeout(900)}
console.log(look,JSON.stringify(errs));await b.close()})();
