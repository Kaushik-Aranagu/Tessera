const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage();await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(800);
console.log(await p.evaluate(()=>{const rw=document.querySelectorAll('#list .rw')[1];return [rw.outerHTML.slice(0,900),...[...rw.querySelectorAll('.nm span')].map(s=>JSON.stringify(s.getBoundingClientRect())),JSON.stringify(rw.getBoundingClientRect())].join('\n')}));await b.close()})();
