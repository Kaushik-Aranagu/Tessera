const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
const p=await b.newPage({viewport:{width:1400,height:1000}});const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+__dirname+'/index.html');await p.waitForTimeout(3000);
for(const id of ['spec','spec2']){const e=await p.$('#'+id);if(!e){console.log('missing',id);continue;}await e.scrollIntoViewIfNeeded();await p.waitForTimeout(800);await e.screenshot({path:id+'.png'});}
const ov=await p.evaluate(()=>[...document.querySelectorAll('.sbx')].map(s=>{const r=s.getBoundingClientRect();let o=0;s.querySelectorAll('*').forEach(c=>{const q=c.getBoundingClientRect();if(q.width&&(q.right>r.right+1||q.left<r.left-1||q.bottom>r.bottom+1))o++;});return o;}));
console.log(errs,ov);await b.close();})();
