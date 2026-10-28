const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const pg=await b.newPage({viewport:{width:402,height:874}});const errs=[];pg.on('pageerror',e=>errs.push(e.message));
await pg.goto('file://'+__dirname+'/index.html');await pg.waitForTimeout(900);
const dialSt=()=>pg.evaluate(()=>{const ds=[...document.querySelectorAll('.screen .dial .d')];const f=ds.find(d=>/translateY\(40px\)/.test(d.style.transform));return {rows:ds.map(d=>d.textContent),focus:f&&f.textContent,color:f&&f.style.color,fact:document.querySelector('.bfact')?.textContent,rl:!!document.querySelector('.ch-rl')}});
const r={};r.h0=await dialSt();
// turn the dial to the Chart room: it sits after Purse
const turnTo=async name=>{for(let i=0;i<8;i++){const s=await dialSt();if(s.focus&&s.focus.includes(name))return s;const c=await pg.evaluate(()=>{const ds=[...document.querySelectorAll('.screen .dial .d')];const nx=ds.find(d=>/translateY\(80px\)/.test(d.style.transform));const r=nx.getBoundingClientRect();return [r.x+r.width-20,r.y+r.height/2]});await pg.mouse.click(c[0],c[1]);await pg.waitForTimeout(350)}return dialSt()};
r.h1=await turnTo('Chart room');await pg.screenshot({path:'RL1.png'});
await pg.evaluate(()=>reset('home'));await pg.waitForTimeout(300);
await pg.evaluate(()=>go('chart'));await pg.waitForTimeout(700);
for(let i=0;i<3;i++){await pg.evaluate(()=>__ch.say());await pg.waitForTimeout(2300)}
r.ttl=await pg.evaluate(()=>getComputedStyle(document.querySelector('.ch-ttl')).color);
await pg.evaluate(()=>reset('home'));await pg.waitForTimeout(600);
r.h2=await dialSt();
// turn until the row after Purse is focused: it relabels there, once
for(let i=0;i<8;i++){const s=await dialSt();if(s.focus&&/Purse/.test(s.focus))break;const c=await pg.evaluate(()=>{const ds=[...document.querySelectorAll('.screen .dial .d')];const nx=ds.find(d=>/translateY\(80px\)/.test(d.style.transform));const r=nx.getBoundingClientRect();return [r.x+r.width-20,r.y+r.height/2]});await pg.mouse.click(c[0],c[1]);await pg.waitForTimeout(350)}
r.beforeFocus=await dialSt();
let c=await pg.evaluate(()=>{const ds=[...document.querySelectorAll('.screen .dial .d')];const nx=ds.find(d=>/translateY\(80px\)/.test(d.style.transform));const r=nx.getBoundingClientRect();return [r.x+r.width-20,r.y+r.height/2]});await pg.mouse.click(c[0],c[1]);await pg.waitForTimeout(560);
r.mid=await dialSt();await pg.screenshot({path:'RL2.png'});await pg.waitForTimeout(700);r.h3=await dialSt();await pg.screenshot({path:'RL3.png'});
// open it from the dial
c=await pg.evaluate(()=>{const ds=[...document.querySelectorAll('.screen .dial .d')];const f=ds.find(d=>/translateY\(40px\)/.test(d.style.transform));const r=f.getBoundingClientRect();return [r.x+r.width-20,r.y+r.height/2]});await pg.mouse.click(c[0],c[1]);await pg.waitForTimeout(1400);
r.opened=await pg.evaluate(()=>({id:document.querySelector('.screen:last-child')?.dataset.id,ttl:document.querySelector('.ch-ttl')?.textContent}));
console.log(JSON.stringify(r),errs);await b.close()})();
