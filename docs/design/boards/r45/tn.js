const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
for(const sch of ['light','dark']){const p=await b.newPage({viewport:{width:1100,height:900},colorScheme:sch});const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(1200);
const s=async n=>{await p.waitForTimeout(600);await p.locator('#ph').screenshot({path:`n${n}-${sch}.png`})};
await s(0);
await p.click('#start');await p.waitForTimeout(800);for(let i=0;i<4&&!(await p.$('#cfN'));i++){await p.click('#go');await p.waitForTimeout(1600)}
const c=await p.$('#cfN');console.log('cfN',!!c);
if(c){const bb=await c.boundingBox();await p.mouse.move(bb.x+bb.width/2,bb.y+bb.height/2);await p.mouse.down();await p.mouse.move(bb.x+bb.width/2,bb.y-40,{steps:8});await p.mouse.up();await s(1);console.log('after drag',await p.textContent('#wbrief'));
 await p.click('#cfN');await s(2);console.log('dial',!!(await p.$('#dial')),await p.textContent('#wbrief'));await p.mouse.wheel(0,90);await p.waitForTimeout(500);await s(3);await p.click('#dGo');await p.waitForTimeout(500);console.log('after dial',await p.textContent('#wbrief'))}
await p.waitForTimeout(5600);console.log('kept',await p.textContent('#wbrief'));
// exercise page
const ws=await p.$$('.wi');console.log('wi',ws.length);for(const w of ws){if(await w.isVisible()){await w.click({force:true});break}}
await p.waitForTimeout(800);await s(4);
const r=await p.$('#sn_reps');if(r){const bb=await r.boundingBox();await p.mouse.move(bb.x+5,bb.y+8);await p.mouse.down();await p.mouse.move(bb.x+5,bb.y-30,{steps:6});await p.mouse.up();}
await s(5);console.log(sch,errs)}
await b.close()})();
