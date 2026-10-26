const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
for(const sch of ['light','dark']){const p=await b.newPage({viewport:{width:1100,height:900},colorScheme:sch});const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(1200);
const s=async(n,w=600)=>{await p.waitForTimeout(w);await p.locator('#ph').screenshot({path:`k${n}-${sch}.png`})};
await s(0);
const c=await (await p.$('#cats')).boundingBox();await p.mouse.move(c.x+120,c.y+15);await p.mouse.down();await p.mouse.move(c.x+40,c.y+15,{steps:8});await p.mouse.up();await s(1,800);
const d=await (await p.$('#dial')).boundingBox();await p.mouse.move(d.x+200,d.y+70);await p.mouse.down();await p.mouse.move(d.x+60,d.y+74,{steps:8});await p.mouse.up();await s(2,800);
await p.click('#cats');for(let i=0;i<3;i++){await p.keyboard.press('ArrowRight');await p.waitForTimeout(300)}await s(3,800);
await p.keyboard.press('Home');await p.click('#cats');for(let i=0;i<5;i++){await p.keyboard.press('ArrowLeft');await p.waitForTimeout(200)}await p.waitForTimeout(600);
const r=await (await p.$('#wheel')).boundingBox();await p.mouse.click(r.x+120,r.y+60);await p.waitForTimeout(900);
const rows=await p.$$('#items .ir');for(let i=0;i<2;i++){const bb=await rows[i].boundingBox();await p.mouse.click(bb.x+40,bb.y+20);await p.waitForTimeout(400)}await s(4,200);await s(5,1500);
console.log(sch,errs,await p.textContent('#pRc'))}
await b.close()})();
