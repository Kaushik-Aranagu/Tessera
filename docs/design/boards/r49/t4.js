const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
for(const sch of ['light','dark']){const p=await b.newPage({viewport:{width:1100,height:900},colorScheme:sch});const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html',{waitUntil:'networkidle'});await p.waitForTimeout(1200);
const s=async(n,w=600)=>{await p.waitForTimeout(w);await p.locator('#ph').screenshot({path:`d${n}-${sch}.png`})};
const hs=async(dx)=>{const h=(await p.$$('#list .ch'))[1];const r=await h.boundingBox();await p.mouse.move(r.x+100,r.y+12);await p.mouse.down();await p.mouse.move(r.x+100+dx,r.y+14,{steps:8});await p.mouse.up()};
await s(0);
await hs(-120);await s(1,250);await s(2,600);
await hs(-120);await s(3,900);
await hs(-120);await s(4,700); // stays
await hs(120);await s(5,900);
// row swipe in a column
const rc=(await p.$$('#list .rc'))[0];const bb=await rc.boundingBox();await p.mouse.move(bb.x+15,bb.y+24);await p.mouse.down();await p.mouse.move(bb.x+120,bb.y+24,{steps:8});await p.mouse.up();await s(6,900);
await p.click('#doCook');await p.waitForTimeout(600);await p.click('#putGo');await s(7,1500);
console.log(sch,errs)}
const p=await b.newPage({viewport:{width:400,height:800}});await p.goto('file://'+process.cwd()+'/index.html');console.log('hscroll',await p.evaluate(()=>document.documentElement.scrollWidth));
await b.close()})();
