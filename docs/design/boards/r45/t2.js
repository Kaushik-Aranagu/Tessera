const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
for(const sch of ['light','dark']){const p=await b.newPage({viewport:{width:1100,height:900},colorScheme:sch});const errs=[];p.on('pageerror',e=>errs.push(e.message));p.on('console',m=>{if(m.type()==='error')errs.push(m.text())});
await p.goto('file://'+process.cwd()+'/index.html',{waitUntil:'networkidle'});await p.waitForTimeout(1200);
const s=async(n,w=0)=>{await p.waitForTimeout(w);await p.locator('#ph').screenshot({path:`b${n}-${sch}.png`})};
await p.click('#start');await s(0,700);await p.click('#go');await s(1,250);await s(2,700);
await p.click('#go');await s(3,250);await s(4,450);await s(5,450);await s(6,500);await s(7,900);
// wheel drag down two rows
const r=await (await p.$('#rest')).boundingBox();await p.mouse.move(r.x+100,r.y+120);await p.mouse.down();await p.mouse.move(r.x+100,r.y+40,{steps:8});await p.mouse.up();await s(8,600);
await p.mouse.click(r.x+60,r.y+73);await s(9,700);
const vis=await p.isVisible('#exGo');if(vis){await p.click('#exGo');await s(10,900)}else errs.push('no exGo');
console.log(sch,errs)}
const p=await b.newPage({viewport:{width:400,height:800}});await p.goto('file://'+process.cwd()+'/index.html');console.log('hscroll',await p.evaluate(()=>document.documentElement.scrollWidth));await b.close()})();
