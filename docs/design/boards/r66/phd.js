const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const pg=await b.newPage({viewport:{width:402,height:874}});const errs=[];pg.on('pageerror',e=>errs.push(e.message));
await pg.goto('file://'+__dirname+'/index.html');await pg.waitForTimeout(600);
await pg.evaluate(()=>go('workout'));await pg.waitForTimeout(900);
await pg.evaluate(()=>{const pad=document.querySelector('.fbpad');const r=pad.getBoundingClientRect();pad.dispatchEvent(new PointerEvent('pointerdown',{clientX:r.x+340,clientY:r.y+104,bubbles:true,pointerId:1}));const S=window.__wo.S;S.hold0=performance.now()-300;const t=performance.now();performance.now=()=>t});
await pg.waitForTimeout(150);await pg.screenshot({path:'HD1.png',clip:{x:200,y:40,width:202,height:100}});
await pg.evaluate(()=>{delete performance.now});await pg.waitForTimeout(700);
console.log('phase',await pg.evaluate(()=>window.__wo.S.phase),errs);await b.close()})();
