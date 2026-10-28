// 297: the roll in the Sheaf rows and the switcher word, mid-move.
const {chromium}=require('/opt/node22/lib/node_modules/playwright');
const look=process.argv[2]||'paper';
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage({viewport:{width:1300,height:1000}});
const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(2000);
if(look==='black'){await p.click('#lk-black');await p.evaluate(()=>scrollTo(0,0))}
const ph=await p.$('#phone');
await p.evaluate(()=>{reset('home');go('sheaf',{mode:1,open:'To tend'})});await p.waitForTimeout(1500);
const cb=await p.evaluate(()=>{const r=current.querySelector('.listclip').getBoundingClientRect();return {x:r.left,y:r.top,w:r.width,h:r.height}});
const bb=await ph.boundingBox();
await p.screenshot({path:'G'+look[0]+'rest.png',clip:{x:bb.x,y:cb.y-30,width:bb.width,height:cb.h+60}});
const st=await p.evaluate(()=>[...current.querySelectorAll('.listclip .sh')].filter(e=>e.style.maskImage).length);
await p.mouse.move(cb.x+cb.w/2,cb.y+cb.h/2);await p.mouse.wheel(0,30);await p.waitForTimeout(200);
const mid=await p.evaluate(()=>[...current.querySelectorAll('.listclip .sh')].filter(e=>e.style.maskImage).map(e=>e.textContent.slice(0,14)+' '+e.style.rotate+' '+e.style.scale));
await p.screenshot({path:'G'+look[0]+'scroll.png',clip:{x:bb.x,y:cb.y-30,width:bb.width,height:cb.h+60}});
await p.evaluate(()=>{reset('home');go('kitchen')});await p.waitForTimeout(1800);
const sx=await p.evaluate(()=>{const r=current.querySelector('.swx').getBoundingClientRect();return {x:r.left,y:r.top,w:r.width,h:r.height}});
await p.mouse.move(sx.x+sx.w*.3,sx.y+sx.h/2);await p.mouse.down();for(let i=1;i<=10;i++){await p.mouse.move(sx.x+sx.w*.3+i*9,sx.y+sx.h/2);await p.waitForTimeout(16)}
await p.waitForTimeout(80);const swm=await p.evaluate(()=>{const s=current.querySelector('.swx .sw'),H=s.parentElement.getBoundingClientRect(),r=s.getBoundingClientRect();return s.style.maskImage+' H '+H.left+'-'+H.right+' r '+r.left+'-'+r.right+' ow '+s.offsetWidth+' tf '+s.style.transform});
await p.screenshot({path:'G'+look[0]+'sw.png',clip:{x:bb.x,y:sx.y-10,width:bb.width,height:sx.h+20}});await p.mouse.up();await p.waitForTimeout(900);
const swr=await p.evaluate(()=>current.querySelector('.swx .sw').style.maskImage||'none');
console.log(look,'rest masked',st,'| mid',JSON.stringify(mid),'| sw drag masked',swm,'| sw after',swr,'| errs',JSON.stringify(errs));await b.close()})();
