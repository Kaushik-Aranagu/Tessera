const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage({viewport:{width:1300,height:1000}});const errs=[];
p.on('pageerror',e=>{if(!/setPointer/.test(e.message))errs.push(e.message)});
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(1500);await p.evaluate(l=>{phone.dataset.look=l},process.argv[2]||'paper');
await p.evaluate(()=>{scrollTo(0,0);reset('home');go('lock')});await p.waitForTimeout(1500);const ph=await (await p.$('#phone')).boundingBox();
for(const [i,pv] of [[0,0],[1,0],[2,0],[3,0],[0,1]]){await p.evaluate(([i,pv])=>__lk.set(i,pv),[i,pv]);await p.waitForTimeout(900);await p.screenshot({path:'LK_'+i+pv+'.png',clip:ph})}
const cut=await p.evaluate(()=>[...current.querySelectorAll('.la1,.la3,.lar b,.lar i,.lab')].filter(e=>e.scrollWidth>e.clientWidth+1).map(e=>e.textContent));
console.log('cut',cut,'errs',errs);await b.close()})();
