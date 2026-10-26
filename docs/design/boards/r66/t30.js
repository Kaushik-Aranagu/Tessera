// 291: boundary audit. On every landing, every visible text run of one place must not intersect a text run of another place.
const {chromium}=require('/opt/node22/lib/node_modules/playwright');
const look=process.argv[2]||'paper';
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage({viewport:{width:1300,height:1000}});
const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(2000);
if(look==='black')await p.click('#lk-black');
const out=[];
for(const room of ['home','notes','weather','training','kitchen','routines','money','l1_notes','l1_weather','l1_training','l1_kitchen','l1_routines','l1_money']){
 await p.evaluate(r=>{reset('home');if(r==='home')return;if(r.startsWith('l1_')){go(r.slice(3));setTimeout(()=>go(r,{door:0}),1800)}else go(r)},room);if(room.startsWith('l1_'))await p.waitForTimeout(1800);await p.waitForTimeout(3200);
 const res=await p.evaluate(()=>{const scr=current,K0=scr.getBoundingClientRect();const runs=[];
  const walk=(n,top)=>{for(const c of n.childNodes){if(c.nodeType===3&&c.nodeValue.trim()){const r=document.createRange();r.selectNodeContents(c);for(const q of r.getClientRects()){if(q.width<1||q.height<1)continue;const e=c.parentElement,cs=getComputedStyle(e);if(e.closest('.face.back'))continue;let op=1,v=e;while(v&&v!==scr){op*=+getComputedStyle(v).opacity;if(getComputedStyle(v).visibility==='hidden')op=0;v=v.parentElement}if(op<.05)continue;runs.push({top,r:q,t:c.nodeValue.trim().slice(0,24)})}}else if(c.nodeType===1&&getComputedStyle(c).display!=='none')walk(c,top)}};
  [...scr.children].forEach((c,i)=>walk(c,(c.className||c.tagName)+'#'+i));
  const hits=[];for(let i=0;i<runs.length;i++)for(let j=i+1;j<runs.length;j++){const a=runs[i],b=runs[j];if(a.top===b.top)continue;const ix=Math.min(a.r.right,b.r.right)-Math.max(a.r.left,b.r.left),iy=Math.min(a.r.bottom,b.r.bottom)-Math.max(a.r.top,b.r.top);if(ix>1&&iy>1)hits.push(a.top+' "'+a.t+'" x '+b.top+' "'+b.t+'"')}
  return [...new Set(hits)].slice(0,12)});
 out.push(room+': '+(res.length?'\n  '+res.join('\n  '):'clear'))}
console.log(look,JSON.stringify(errs));console.log(out.join('\n'));await b.close()})();
