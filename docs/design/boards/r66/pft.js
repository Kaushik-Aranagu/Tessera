// 391: no shown line on a door or item page ends in a full stop (body notes included; a note's own text keeps its
// stops), and the Lookout's door pages set the rain alert instead of offering to add to the weather
const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const pg=await b.newPage({viewport:{width:402,height:874}});const errs=[];pg.on('pageerror',e=>errs.push(e.message));
 await pg.goto('file://'+__dirname+'/index.html');await pg.waitForTimeout(600);
 const rooms=await pg.evaluate(()=>Object.keys(SCREENS).filter(k=>k.startsWith('l1_')).map(k=>k.slice(3)));const bad=[];let n=0;const seen=new Set();
 for(const r of rooms)for(let d=0;d<8;d++)for(const lv of ['l1_','l2_']){await pg.evaluate(([r,d,lv])=>{reset('home');go(lv+r,{door:d})},[r,d,lv]);await pg.waitForTimeout(220);
  const got=await pg.evaluate(()=>{const keep=current.querySelectorAll('.lbd .lbt, .lbd .lbs');const skip=new Set([...current.querySelectorAll('.lbd')].filter(x=>/lb-(text|tess)/.test(x.className)));
   const sel='.ldt b, .ldt span, .lcap, .lbn, .lpg *, .lfx span, .foot, .foot *';const out=[];
   current.querySelectorAll(sel).forEach(e=>{if(e.children.length)return;const t=e.textContent.trim();if(t)out.push(t)});
   const bd=current.querySelector('.lbd');const kind=bd?bd.getAttribute('data-kind')||'':'';return {out,kind,dt:(current.querySelector('.ldt b')||{}).textContent||''}});
  const key=lv+r+got.dt;if(seen.has(key))continue;seen.add(key);n++;
  got.out.forEach(t=>{if(/\.\s*$/.test(t)&&!/\b(am|pm)\.$/.test(t))bad.push(key+': '+t)})}
 await pg.evaluate(()=>{reset('home');go('l1_weather',{door:0})});await pg.waitForTimeout(400);
 const foot=await pg.evaluate(()=>current.innerText.includes('Add\n')||/\bto Hours\b/.test(current.innerText)?'add':(/Alert/.test(current.innerText)&&/before rain/.test(current.innerText)?'alert':'none'));
 await pg.evaluate(()=>{const t=current.querySelector('.ldt');const r=t.getBoundingClientRect();const o={bubbles:true,pointerId:1,clientY:r.top+10};t.dispatchEvent(new PointerEvent('pointerdown',{...o,clientX:r.right-20}));t.dispatchEvent(new PointerEvent('pointerup',{...o,clientX:r.right-120}))});await pg.waitForTimeout(500);
 const after=await pg.evaluate(()=>{const t=current.innerText;return (current.querySelector('.ldt b')||{}).textContent==='Tonight'&&/Alert\s+before rain/.test(t)&&!/\bAdd\b|to Tonight/.test(t)});
 const ok=!bad.length&&!errs.length&&foot==='alert'&&after;
 console.log(ok?'ok':'FAIL',n+' pages','foot '+foot,'across '+after,JSON.stringify(bad.slice(0,8)),errs.slice(0,3));await b.close()})();
