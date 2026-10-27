const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
for(const sch of ['light','dark']){const p=await b.newPage({viewport:{width:1100,height:1000},colorScheme:sch,deviceScaleFactor:2});const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(1500);
for(let i=0;i<5;i++){await p.click('#wxB');await p.waitForTimeout(i==2?1500:2600);const ph=await (await p.$('#ph')).boundingBox();await p.screenshot({path:`w${i}-${sch}.png`,clip:{x:ph.x,y:ph.y+60,width:ph.width,height:110}})}
const o=await (await p.$('#one')).boundingBox();const before=await p.$eval('#one',e=>e.textContent);
await p.mouse.move(o.x+o.width/2,o.y+o.height-30);await p.mouse.down();for(let k=1;k<=10;k++){await p.mouse.move(o.x+o.width/2,o.y+o.height-30-k*8);await p.waitForTimeout(16)}
await p.screenshot({path:`mid-${sch}.png`,clip:{x:o.x-10,y:o.y-20,width:o.width+20,height:o.height+40}});
await p.mouse.up();await p.waitForTimeout(800);const after=await p.$eval('#one',e=>e.textContent);
console.log(sch,errs,'vertical turned:',before!==after)}
await b.close()})();
