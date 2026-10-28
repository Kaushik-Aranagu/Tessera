// 377: through a door the name and number travel: out of the dial row and keystone column into the plant page, and
// back to wherever the plant now sits (watered: the end of the row, "Today" landing as 0). Reduce Motion: none.
const {chromium}=require('/opt/node22/lib/node_modules/playwright');
async function run(rm){const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
 const pg=await b.newPage({viewport:{width:402,height:874},reducedMotion:rm?'reduce':'no-preference'});const errs=[];pg.on('pageerror',e=>errs.push(e.message));
 await pg.goto('file://'+__dirname+'/index.html');await pg.waitForTimeout(600);await pg.evaluate(()=>go('chart'));await pg.waitForTimeout(1500);
 for(let i=0;i<6;i++){await pg.evaluate(()=>__ch.say());await pg.waitForTimeout(2300)}
 const fx=()=>pg.evaluate(()=>[...document.querySelectorAll('.tv')].map(e=>e.textContent+'@'+Math.round(e.getBoundingClientRect().left/K)+','+Math.round(e.getBoundingClientRect().top/K)));
 const r={rm};// turn to the Monstera and open it
 let c=await pg.evaluate(()=>{const d=[...document.querySelector('.ch-dial').children].find(x=>x.style.transform.startsWith('translateY(80px)'));const q=d.getBoundingClientRect();return [q.x+q.width-30,q.y+q.height/2]});
 await pg.mouse.click(c[0],c[1]);await pg.waitForTimeout(500);
 c=await pg.evaluate(()=>{const d=[...document.querySelector('.ch-dial').children].find(x=>x.style.opacity==='1');const q=d.getBoundingClientRect();return [q.x+q.width-30,q.y+q.height/2]});
 await pg.mouse.click(c[0],c[1]);await pg.waitForTimeout(120);
 r.goingIn={fx:await fx(),ttlHidden:await pg.evaluate(()=>current.querySelector('.ttl2').style.visibility)};
 await pg.waitForTimeout(800);r.landed={fx:await fx(),ttl:await pg.evaluate(()=>current.querySelector('.ttl2').style.visibility+'|'+current.querySelector('.ttl2').textContent),num:await pg.evaluate(()=>current.querySelector('.pl-key b').style.visibility)};
 await pg.click('.ch-act');await pg.waitForTimeout(500);// watered: "Today"
 await pg.evaluate(()=>back());await pg.waitForTimeout(120);
 r.goingBack={fx:await fx(),id:await pg.evaluate(()=>current.dataset.id)};
 await pg.waitForTimeout(900);r.home={fx:await fx(),key:await pg.evaluate(()=>[...document.querySelectorAll('.ch-key > div')].map(d=>d.querySelector('span').textContent+d.querySelector('b').textContent+(d.querySelector('b').style.visibility==='hidden'?'(hidden)':'')).join(' ')),
  focus:await pg.evaluate(()=>{const d=[...document.querySelector('.ch-dial').children].find(x=>x.style.opacity==='1');return d.textContent+(d.querySelector('span').style.visibility==='hidden'?'(hidden)':'')})};
 r.errs=errs;await b.close();return r}
(async()=>{console.log(JSON.stringify(await run(false)));console.log(JSON.stringify(await run(true)))})();
