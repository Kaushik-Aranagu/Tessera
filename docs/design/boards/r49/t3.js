const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
for(const sch of ['light','dark']){const p=await b.newPage({viewport:{width:1100,height:900},colorScheme:sch});const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html',{waitUntil:'networkidle'});await p.waitForTimeout(1200);
const s=async(n,w=600)=>{await p.waitForTimeout(w);await p.locator('#ph').screenshot({path:`c${n}-${sch}.png`})};
await s(0);
let r=await (await p.$('#secs')).boundingBox();
await p.mouse.move(r.x+250,r.y+20);await p.mouse.down();await p.mouse.move(r.x+80,r.y+22,{steps:8});await p.mouse.up();await p.waitForTimeout(200);await s(1,0);await s(2,500);
// page turn in Dairy (5 things)
let l=await (await p.$('#list')).boundingBox();await p.mouse.move(l.x+150,l.y+150);await p.mouse.down();await p.mouse.move(l.x+150,l.y+40,{steps:6});await p.mouse.up();await s(3,700);
// row swipe still used up
const rc=(await p.$$('#list .rc'))[0];const bb=await rc.boundingBox();await p.mouse.move(bb.x+20,bb.y+22);await p.mouse.down();await p.mouse.move(bb.x+160,bb.y+22,{steps:8});await p.mouse.up();await s(4,900);
// tap Fruit
await p.click('#secs button[data-i="3"]');await s(5,700);
// shelf
r=await (await p.$('#dial')).boundingBox();for(let k=0;k<2;k++){await p.mouse.move(r.x+150,r.y+140);await p.mouse.down();await p.mouse.move(r.x+150,r.y+76,{steps:8});await p.mouse.up();await p.waitForTimeout(400)}await s(6,700);
await p.click('#doCook');await p.waitForTimeout(600);await p.click('#putGo');await s(7,1500);
console.log(sch,errs)}
await b.close()})();
