// 296: the Bounds check mid-move. Text from different places must not cross while a route plays.
const {chromium}=require('/opt/node22/lib/node_modules/playwright');
const look=process.argv[2]||'paper';
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage({viewport:{width:1300,height:1000}});
const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(2000);
if(look==='black'){await p.click('#lk-black');await p.evaluate(()=>scrollTo(0,0))}
const audit=()=>p.evaluate(()=>{const ph=document.querySelector('#phone');const P=ph.getBoundingClientRect();const runs=[];
 const scr=[...ph.querySelectorAll('.screen')];
 const walk=(n,top,sc)=>{for(const c of n.childNodes){if(c.nodeType===3&&c.nodeValue.trim()){const e=c.parentElement;let op=1,v=e;while(v&&v!==ph){const cs=getComputedStyle(v);op*=+cs.opacity;if(cs.visibility==='hidden')op=0;v=v.parentElement}if(op<.15||e.closest('.face.back'))continue;const clips=[];let w=e;while(w&&w!==ph){const cs=getComputedStyle(w);const R=w.getBoundingClientRect();if(cs.overflow!=='visible'||cs.overflowX!=='visible'||cs.webkitMaskImage!=='none'&&cs.webkitMaskImage)clips.push({l:R.left,t:R.top,r:R.right,b:R.bottom});
   const cp=cs.clipPath;if(cp&&cp.startsWith('inset(')){const v=cp.slice(6,-1).split(/\s+/).slice(0,4).map((x,i)=>x.endsWith('%')?parseFloat(x)/100*((i%2)?R.width:R.height):parseFloat(x)||0);const [t0,r0,b0,l0]=[v[0],v[1]??v[0],v[2]??v[0],v[3]??v[1]??v[0]];clips.push({l:R.left+l0,t:R.top+t0,r:R.right-r0,b:R.bottom-b0})}w=w.parentElement}
  const r=document.createRange();r.selectNodeContents(c);for(const q0 of r.getClientRects()){let q={left:q0.left,top:q0.top,right:q0.right,bottom:q0.bottom};for(const k of clips){q={left:Math.max(q.left,k.l),top:Math.max(q.top,k.t),right:Math.min(q.right,k.r),bottom:Math.min(q.bottom,k.b)}}
   if(q.right-q.left>1&&q.bottom-q.top>1&&q.bottom>P.top&&q.top<P.bottom)runs.push({top,r:q,t:c.nodeValue.trim().slice(0,20),op})}}else if(c.nodeType===1&&getComputedStyle(c).display!=='none')walk(c,top,sc)}};
 scr.forEach((s,k)=>[...s.children].forEach((c,i)=>walk(c,k+':'+(c.className||c.tagName)+'#'+i,k)));
 ph.querySelectorAll(':scope > :not(.screen)').forEach((c,i)=>{if(c.querySelector('.screen'))return;walk(c,'L:'+(c.className||c.tagName),'L')});
 const hits=[];for(let i=0;i<runs.length;i++)for(let j=i+1;j<runs.length;j++){const a=runs[i],b=runs[j];if(a.top===b.top)continue;/* allowed by sheet 291: something in flight over a place that has stepped back to 40% or less */if(Math.min(a.op,b.op)<=.4)continue;if(a.t===b.t&&Math.abs(a.r.left-b.r.left)<3&&Math.abs(a.r.top-b.r.top)<3)continue;const ix=Math.min(a.r.right,b.r.right)-Math.max(a.r.left,b.r.left),iy=Math.min(a.r.bottom,b.r.bottom)-Math.max(a.r.top,b.r.top);if(ix>2&&iy>2)hits.push(a.top+' "'+a.t+'"('+a.op.toFixed(2)+') x '+b.top+' "'+b.t+'"('+b.op.toFixed(2)+')')}
 return [...new Set(hits)].slice(0,6)});
const routes=[['home','training'],['home','kitchen'],['home','notes'],['home','money'],['home','routines'],['home','weather'],['training','l1_training'],['kitchen','l1_kitchen'],['training','kitchen']];
for(const [a,z] of routes){await p.evaluate(([a,z])=>{reset('home');if(a!=='home')go(a)},[a,z]);await p.waitForTimeout(2600);
 await p.evaluate(z=>{if(z.startsWith('l1_'))go(z,{door:0});else go(z)},z);const seen=[];
 for(const t of [80,160,240,320,420,560,760]){await p.waitForTimeout(t-(seen.length?[80,160,240,320,420,560,760][seen.length-1]:0));const h=await audit();if(h.length)seen.push(t+'ms: '+h.join(' | '));else seen.push('')}
 const bad=seen.filter(Boolean);console.log(a+'>'+z+': '+(bad.length?'\n  '+bad.join('\n  '):'clear'));
 if(bad.length){await (await p.$('#phone')).screenshot({path:'M'+look[0]+'_'+z+'.png'})}}
console.log(look,JSON.stringify(errs));await b.close()})();
