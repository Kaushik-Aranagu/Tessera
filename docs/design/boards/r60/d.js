const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage();p.on('console',m=>console.log(m.text()));p.on('pageerror',e=>console.log('ERR',e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(2500);
console.log(await p.evaluate(()=>[...document.querySelectorAll('.band')][0].innerHTML.slice(0,400)));await b.close()})();
