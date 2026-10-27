// 306: the zero notch. Turn a landing's dial all the way round and sample the focus word's offset just after each turn.
const {chromium}=require('/opt/node22/lib/node_modules/playwright');
const look=process.argv[2]||'paper',room=process.argv[3]||'kitchen';
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage({viewport:{width:1300,height:1000}});
const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(2000);
if(look==='black'){await p.click('#lk-black')}await p.evaluate(r=>{scrollTo(0,0);reset('home');go(r)},room);await p.waitForTimeout(3000);
const n=await p.evaluate(()=>current.querySelectorAll('.dial .d').length);const out=[];
for(let i=0;i<n;i++){const r=await p.evaluate(()=>{const host=current.querySelector('.dial');const R=host.getBoundingClientRect(),x=R.left+R.width/2,y=R.top+R.height/2;
  const ev=(t,yy)=>host.dispatchEvent(new PointerEvent(t,{bubbles:true,clientX:x,clientY:yy,pointerId:7}));ev('pointerdown',y);ev('pointermove',y-60*K);ev('pointerup',y-60*K);
  const ds=[...host.querySelectorAll('.d')];const fd=ds.find(d=>d.style.opacity==='1');const a=fd&&fd.getAnimations().find(a=>a.effect.composite==='add');return a?(a.effect.getKeyframes()[0].translate+' '+a.effect.getTiming().duration+'ms '+fd.textContent.trim()):'none'});out.push(r);await p.waitForTimeout(450)}
console.log(look,room,n,'doors:',out.join(' | '),JSON.stringify(errs));await b.close()})();
