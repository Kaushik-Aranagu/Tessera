const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
const p=await b.newPage({viewport:{width:1100,height:900},colorScheme:'dark',deviceScaleFactor:2});const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(1200);
await p.click('#start');await p.waitForTimeout(800);for(let i=0;i<4&&!(await p.$('#cfN'));i++){await p.click('#go');await p.waitForTimeout(1600)}
await p.waitForTimeout(3500);await p.locator('#ph').screenshot({path:'x0.png'});
const ws=await p.$$('#work .wi, .wi');for(const w of ws){const t=await w.evaluate(e=>e.closest('button')&&e.closest('button').textContent);if(t&&t.includes('Bench')&&await w.isVisible()){await w.click({force:true});break}}
await p.waitForTimeout(900);const r=await p.$('#sn_w');const bb=await r.boundingBox();await p.mouse.move(bb.x+10,bb.y+10);await p.mouse.down();await p.mouse.move(bb.x+10,bb.y-25,{steps:6});await p.locator('#ph').screenshot({path:'x1.png'});await p.mouse.up();console.log('ex',await p.evaluate(()=>!document.getElementById('ex').hidden),errs);await b.close()})();
