const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage({viewport:{width:900,height:1000}});
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(3000);
for(const f of ['Figtree','Mona Sans']){await p.click(`.ff >> text=${f}`);await p.waitForTimeout(1500);
console.log(f,await p.evaluate(()=>{const t=[...document.querySelectorAll('#p1 .w')].map(e=>e.dataset.k+':'+e.style.opacity);return t.join(' | ')}))}
await b.close()})();
