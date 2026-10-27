// 298: hard cuts mid-move. While routes, demos and gestures play, find text that a clip edge slices without a soft edge.
const {chromium}=require('/opt/node22/lib/node_modules/playwright');
const look=process.argv[2]||'paper',only=process.argv[3];
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage({viewport:{width:1300,height:1000}});
const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(2000);
if(look==='black'){await p.click('#lk-black');await p.evaluate(()=>scrollTo(0,0))}
const probe=()=>p.evaluate(()=>{const scr=current,ph=document.querySelector('#phone'),hits=[];if(!scr)return hits;
 const walk=n=>{for(const c of n.childNodes){if(c.nodeType===3&&c.nodeValue.trim()){const e=c.parentElement;let op=1,v=e;while(v&&v!==ph){const cs=getComputedStyle(v);op*=+cs.opacity;if(cs.visibility==='hidden')op=0;v=v.parentElement}if(op<.2||e.closest('.face.back'))continue;
    const r=document.createRange();r.selectNodeContents(c);const R=r.getBoundingClientRect();if(R.width<2)continue;
    let w=e;while(w&&w!==scr){const cs=getComputedStyle(w);if(cs.overflow!=='visible'||cs.overflowX!=='visible'){const H=w.getBoundingClientRect();
      const cx=Math.max(H.left-R.left,R.right-H.right),cy=Math.max(H.top-R.top,R.bottom-H.bottom),inside=R.right>H.left+2&&R.left<H.right-2&&R.bottom>H.top+2&&R.top<H.bottom-2;
      let masked=false,y=e;while(y&&y!==w.parentElement){const m=getComputedStyle(y).webkitMaskImage;if(m&&m!=='none'){masked=true;break}y=y.parentElement}
      if(inside&&!masked&&cs.textOverflow!=='ellipsis'&&getComputedStyle(e).textOverflow!=='ellipsis'&&((cs.overflowX!=='visible'&&cx>3)||(cs.overflowY!=='visible'&&cy>Math.max(6,R.height*.22)))){const cls=typeof w.className==='string'&&w.className?w.className.split(' ')[0]:w.tagName;hits.push(cls+(cs.overflowX!=='visible'&&cx>3?' x':' y')+' "'+c.nodeValue.trim().slice(0,18)+'"')}}
     w=w.parentElement}}else if(c.nodeType===1&&getComputedStyle(c).display!=='none')walk(c)}};
 walk(scr);return hits});
const run=async(name,setup,act,ms=1700)=>{if(only&&!name.includes(only))return;await p.evaluate(setup);await p.waitForTimeout(2600);const base=new Set(await probe());
 await p.evaluate(act);const seen=new Map();const t0=Date.now();while(Date.now()-t0<ms){for(const h of await probe())if(!base.has(h))seen.set(h,(seen.get(h)||0)+1);await p.waitForTimeout(25)}
 console.log(name+': '+(seen.size?[...seen].map(([h,n])=>h+' x'+n).join(' | '):'clean'))};
const R=(a)=>new Function('reset("home");'+(a!=='home'?'go("'+a+'")':''));
for(const [a,z] of [['home','training'],['home','kitchen'],['home','notes'],['home','money'],['home','routines'],['home','weather'],['training','l1_training'],['kitchen','l1_kitchen'],['notes','l1_notes'],['money','l1_money'],['routines','sheaf']])
 await run(a+'>'+z,R(a),new Function(z.startsWith('l1_')?'go("'+z+'",{door:0})':'go("'+z+'")'));
for(const room of ['home','training','kitchen','notes','money','routines','weather']){
 await run(room+' switcher',R(room),()=>{const s=current.querySelector('.swx');if(!s)return;const r=s.getBoundingClientRect();['pointerdown','pointerup'].forEach(t=>s.dispatchEvent(new PointerEvent(t,{bubbles:true,clientX:r.left+20,clientY:r.top+30,pointerId:1})))});
 await run(room+' dial',R(room),()=>{const s=current.querySelector('.reel,.apps');if(!s)return;s.dispatchEvent(new WheelEvent('wheel',{bubbles:true,deltaY:60,cancelable:true}))});
 await run(room+' widget',R(room),()=>{const s=current.querySelector('.one');if(!s)return;const r=s.getBoundingClientRect();const f=(t,x)=>s.dispatchEvent(new PointerEvent(t,{bubbles:true,clientX:x,clientY:r.top+100,pointerId:2}));f('pointerdown',r.left+200);for(let i=1;i<9;i++)f('pointermove',r.left+200-i*20);f('pointerup',r.left+40)})}
for(const d of ['galley-tess','galley-dish','galley-you','deck-tess','deck-you','deck-rest','log-index','log-sentence','log-reel','look-tess','look-index','page-columns','page-time','page-tess'])
 await run('demo '+d,()=>{reset('home')},new Function('window.__th("'+d+'")'),3400);
console.log(look,JSON.stringify(errs));await b.close()})();
