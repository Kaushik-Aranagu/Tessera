// 301: no full stop at the end of any shown line. Notes and documents keep theirs. Samples each page several times.
const {chromium}=require('/opt/node22/lib/node_modules/playwright');
const look=process.argv[2]||'paper';
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage({viewport:{width:1300,height:1000}});
const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(2000);
if(look==='black'){await p.click('#lk-black')}
const KEEP='.nbody,.lbp,.lbn,.lbt,.tv,.tessv,.notebody,[data-doc],textarea,input,script,style';
const probe=()=>p.evaluate(KEEP=>{const ph=document.querySelector('#phone'),out=[];
 const blocks=[...ph.querySelectorAll('*')].filter(e=>{const d=getComputedStyle(e).display;return !d.startsWith('inline')&&d!=='none'});
 for(const e of blocks){if(e.closest(KEEP))continue;let txt='';for(const c of e.childNodes){if(c.nodeType===3)txt+=c.nodeValue;else if(c.nodeType===1&&getComputedStyle(c).display.startsWith('inline'))txt+=c.textContent}
  txt=txt.trim();if(!txt||!/(^|[^.])\.$/.test(txt))continue;let op=1,v=e;while(v&&v!==ph){const cs=getComputedStyle(v);op*=+cs.opacity;if(cs.visibility==='hidden'||cs.display==='none')op=0;v=v.parentElement}if(op<.1)continue;
  out.push((e.className||e.tagName)+': "'+txt.slice(-40)+'"')}return out},KEEP);
const pages=['home','notes','weather','training','kitchen','routines','money','sheaf','list','pantry','routine','l1_notes','l1_weather','l1_training','l1_kitchen','l1_routines','l1_money','l2_notes','l2_kitchen','l2_money','l2_training','l2_routines','l2_weather'];
const all=new Map();
for(const pg of pages){await p.evaluate(pg=>{scrollTo(0,0);reset('home');if(pg==='home')return;if(/^l[12]_/.test(pg)){go(pg.slice(3));setTimeout(()=>go(pg,{door:0}),1500)}else go(pg)},pg);
 for(const t of [2500,1500,2500,3000]){await p.waitForTimeout(t);for(const h of await probe())all.set(pg+' | '+h,1)}}
console.log(look,JSON.stringify(errs));console.log([...all.keys()].join('\n')||'none');await b.close()})();
