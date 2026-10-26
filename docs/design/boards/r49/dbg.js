const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage({viewport:{width:1100,height:900}});
await p.goto('file://'+process.cwd()+'/index.html',{waitUntil:'networkidle'});await p.waitForTimeout(1200);
let r=await (await p.$('#secs')).boundingBox();
await p.mouse.move(r.x+250,r.y+20);await p.mouse.down();await p.mouse.move(r.x+80,r.y+22,{steps:8});await p.mouse.up();
for(const t of [100,400,900]){await p.waitForTimeout(t);console.log(await p.evaluate(()=>{const L=document.getElementById('list'),s=document.getElementById('secs');return [L.children.length,L.scrollLeft,s.scrollLeft,document.querySelector('.phone').scrollLeft,document.querySelector('#pan').scrollLeft].join(' ')}))}
await b.close()})();
