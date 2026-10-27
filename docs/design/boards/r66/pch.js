const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
for(const cs of ['light','dark']){const pg=await b.newPage({viewport:{width:402,height:874},colorScheme:cs});const errs=[];pg.on('pageerror',e=>errs.push(e.message));
await pg.goto('file://'+__dirname+'/index.html');await pg.waitForTimeout(600);
await pg.evaluate(()=>go('chart'));await pg.waitForTimeout(800);
const shot=async n=>pg.screenshot({path:'CH'+n+'-'+cs+'.png'});
await shot(0);
const fit=()=>pg.evaluate(()=>{const scr=document.querySelector('.chart');const out=[];scr.querySelectorAll('.ch-c').forEach(e=>{const p=scr.querySelector('.ch-pl:nth-of-type(1)');});
 const PL={title:[24,50,260,48],line:[24,106,354,76],key:[24,196,354,182],cap:[24,378,354,34],wid:[24,412,354,200]};const r0=scr.getBoundingClientRect(),k=r0.width/402;
 scr.querySelectorAll('.ch-c[data-p]').forEach(e=>{const [x,y,w,hh]=PL[e.dataset.p];const r=e.getBoundingClientRect();const L=(r.left-r0.left)/k,T=(r.top-r0.top)/k,R=L+r.width/k,B=T+r.height/k;if(L<x-.5||T<y-.5||R>x+w+.5||B>y+hh+.5)out.push(e.dataset.p+' '+[L,T,R,B].map(Math.round))});
 scr.querySelectorAll('.ch-c').forEach(e=>{if(e.scrollWidth>e.clientWidth+1)out.push('clipped '+e.className)});return out});
const log=[];
for(let i=0;i<7;i++){await pg.evaluate(()=>__ch.say());await pg.waitForTimeout(900);const gh=await pg.evaluate(()=>document.querySelectorAll('.ch-c.gh').length);if(i===1)await shot(1);await pg.waitForTimeout(1400);
 log.push('say'+(i+1)+' ghosts mid:'+gh+' set:'+await pg.evaluate(()=>document.querySelectorAll('.ch-c.gh').length)+' fit:'+JSON.stringify(await fit()))}
await shot(2);
const al=await pg.evaluate(()=>{const b=document.querySelector('[data-a="allow"]').getBoundingClientRect();return [b.x+b.width/2,b.y+b.height/2]});await pg.mouse.click(al[0],al[1]);await pg.waitForTimeout(300);
const a=await pg.evaluate(()=>{const b=document.querySelector('.ch-act').getBoundingClientRect();return [b.x+40,b.y+20]});await pg.mouse.click(a[0],a[1]);await pg.waitForTimeout(500);
log.push('after water: '+await pg.evaluate(()=>document.querySelector('.ch-line').textContent+' | '+document.querySelector('.ch-act').textContent+' | '+document.querySelector('.receipt').textContent));
await shot(3);
// undo via receipt
const u=await pg.evaluate(()=>{const b=document.querySelector('.receipt button').getBoundingClientRect();return [b.x+b.width/2,b.y+b.height/2]});await pg.mouse.click(u[0],u[1]);await pg.waitForTimeout(300);
log.push('undo water: '+await pg.evaluate(()=>document.querySelector('.ch-line').textContent));
console.log(cs,log.join('\n'),errs);await pg.close()}
await b.close()})();
