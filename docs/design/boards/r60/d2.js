const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage({viewport:{width:1000,height:1000}});
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(5000);
console.log(await p.evaluate(()=>{const sk=[...document.querySelectorAll('.sk')][7];const inn=sk.querySelector('.in');return [sk.clientWidth,inn.style.transform,...[...inn.children].slice(0,3).map(e=>e.textContent+' '+e.style.fontSize+' '+e.getBoundingClientRect().width.toFixed(0)+' '+e.style.transform)].join('\n')}));await b.close()})();
