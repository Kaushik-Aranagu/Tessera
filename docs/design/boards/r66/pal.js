const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage({viewport:{width:1300,height:1000}});const errs=[];
p.on('pageerror',e=>{if(!/setPointer/.test(e.message))errs.push(e.message)});
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(1500);const ph=await (await p.$('#phone')).boundingBox();
await p.evaluate(()=>{scrollTo(0,0);reset('home');go('cook')});await p.waitForTimeout(1200);await p.evaluate(()=>{__ck.next();__ck.fast(999)});await p.waitForTimeout(2500);
await p.screenshot({path:'AL.png',clip:{x:ph.x,y:ph.y,width:ph.width,height:ph.height*.5}});console.log(await p.evaluate(()=>__ck.S.alert),errs);await b.close()})();
