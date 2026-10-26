const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
for(const sch of ['light','dark']){const p=await b.newPage({viewport:{width:1100,height:900},colorScheme:sch});const errs=[];p.on('pageerror',e=>errs.push(e.message));p.on('console',m=>{if(m.type()==='error')errs.push(m.text())});
await p.goto('file://'+process.cwd()+'/index.html',{waitUntil:'networkidle'});await p.waitForTimeout(1200);
const s=async(n,w=600)=>{await p.waitForTimeout(w);await p.locator('#ph').screenshot({path:`w${n}-${sch}.png`})};
const drag=async(sel,dx,hold)=>{const bb=await (await p.$(sel)).boundingBox();await p.mouse.move(bb.x+20,bb.y+12);await p.mouse.down();await p.mouse.move(bb.x+20+dx,bb.y+12,{steps:10});if(hold){await p.waitForTimeout(150);await s(hold,0)}await p.mouse.up()};
await s(0);
let r=await (await p.$('#plan')).boundingBox();await p.mouse.move(r.x+150,r.y+140);await p.mouse.down();await p.mouse.move(r.x+150,r.y+60,{steps:8});await p.mouse.up();await s(1,800);
await drag('#start',-90,2);await s(3,500);
// undo
await p.click('#lbrief button');await s(4,400);
await p.click('#start');await s(5,1200);
await p.click('#go');await s(6,900);
await p.click('#go');await p.waitForTimeout(2500);
await drag('#go',90,7);await p.waitForTimeout(2500);await s(8,300);
await p.keyboard.press('Escape');await s(9,900);
await drag('#start',90,10);await s(11,900);
await p.click('#wbrief button');await s(12,800);
await p.keyboard.press('Escape');await p.waitForTimeout(600);await drag('#start',-90);await s(13,900);
console.log(sch,errs)}
const p=await b.newPage({viewport:{width:400,height:800}});await p.goto('file://'+process.cwd()+'/index.html');console.log('hscroll',await p.evaluate(()=>document.documentElement.scrollWidth));await b.close()})();
