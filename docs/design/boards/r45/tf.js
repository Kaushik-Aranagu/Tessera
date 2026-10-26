const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage({viewport:{width:1100,height:900}});const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html',{waitUntil:'networkidle'});await p.waitForTimeout(1000);
const btn=await p.$$('button');for(const x of btn){const t=await x.textContent();if(/^Start /.test(t.trim())){await x.click();break}}
await p.waitForTimeout(800);
const r=await p.evaluate(()=>{const e=document.getElementById('exName');if(!e)return 'none';e.textContent='Triceps pushdown';fitTitle(e,34,26);return e.style.fontSize+' '+e.scrollWidth+' '+e.parentElement.clientWidth});
console.log(r,errs);await p.locator('.phone').first().screenshot({path:'tf.png'});await b.close()})();
