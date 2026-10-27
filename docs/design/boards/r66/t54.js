// 310: shape mode's foot line. No full stops; it eases between places; the doors' words still work after.
const {chromium}=require('/opt/node22/lib/node_modules/playwright');
const look=process.argv[2]||'paper',room=process.argv[3]||'training';
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage({viewport:{width:1300,height:1000}});
const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(2000);
if(look==='black'){await p.click('#lk-black')}await p.evaluate(r=>{scrollTo(0,0);reset('home');go(r)},room);await p.waitForTimeout(3000);
const ph=await (await p.$('#phone')).boundingBox();const K=ph.width/402;const clip={x:ph.x,y:ph.y+760*K,width:ph.width,height:110*K};
const st=()=>p.evaluate(()=>{const b=current.querySelector('.shapebar');const lines=[...b.children].map(c=>c.textContent.trim());const ops=[...b.children].map(c=>(+getComputedStyle(c).opacity).toFixed(2));
 return JSON.stringify(lines)+' op '+ops.join(',')+(lines.some(t=>/(^|[^.])\.$/.test(t))?' STOP':'')});
const out=[],fs=[];const shot=async n=>{const f='F'+look[0]+n+'.png';await p.screenshot({path:f,clip});fs.push(f);out.push(n+': '+await st())};
await p.evaluate(r=>__shape.on(r),room);await p.waitForTimeout(700);await shot('on');
for(const k of ['keystone','widget','summary','dial']){await p.evaluate(([r,k])=>__shape.pick(r,k),[room,k]);let t0=0;for(const t of [70,160,500]){await p.waitForTimeout(t-t0);t0=t;await shot(k+t)}}
// the Index word still changes the look
await p.click('#phone .shapebar [data-f=index]');await p.waitForTimeout(800);out.push('look '+await p.evaluate(r=>window.__looks[r],room));await shot('after');
// fast picks do not stack two lines
await p.evaluate(r=>{__shape.pick(r,'keystone');__shape.pick(r,'widget');__shape.pick(r,'needs')},room);await p.waitForTimeout(600);await shot('fast');
console.log(out.join('\n'));console.error(look,JSON.stringify(errs));await b.close()})();
