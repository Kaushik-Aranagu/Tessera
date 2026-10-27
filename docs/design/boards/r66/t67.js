// 327-329: the whole-screen modes. Workout, cooking, shopping and routine each open, move on, and finish, with no
// cut line, no full stop on a shown line and no page error. Replaces t63-t65 (which checked the landing-place modes).
const {chromium}=require('/opt/node22/lib/node_modules/playwright');const look=process.argv[2]||'paper';
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage({viewport:{width:1300,height:1000}});
const errs=[];p.on('pageerror',e=>{if(!/setPointerCapture/.test(e.message))errs.push(e.message)});let bad=0;const ok=(c,m)=>{console.log((c?'ok   ':'FAIL ')+m);if(!c)bad++};
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(1500);await p.evaluate(l=>{phone.dataset.look=l},look);
const open=async(r,m)=>{await p.evaluate(r=>{scrollTo(0,0);reset('home');go(r)},r);await p.waitForTimeout(900);await p.evaluate(m=>go(m),m);await p.waitForTimeout(1200)};
const lines=sel=>p.evaluate(sel=>{const E=[...current.querySelectorAll(sel)];return {cut:E.filter(e=>e.scrollWidth>e.clientWidth+1).map(e=>e.textContent),stops:E.map(e=>e.textContent.trim()).filter(t=>/\.$/.test(t))}},sel);
await open('training','workout');let s=await p.evaluate(()=>__wo.S.li);ok(s===0,'workout opens on the warm up');
await p.evaluate(()=>{__wo.log();__wo.tickRest(999)});await p.waitForTimeout(1300);s=await p.evaluate(()=>({li:__wo.S.li,ph:__wo.S.phase}));ok(s.li===1&&s.ph==='lift','after the rest it is Bench');
await p.evaluate(()=>{__wo.log()});s=await p.evaluate(()=>__wo.S.phase);ok(s==='rest','a set starts the rest');await p.evaluate(()=>__wo.feel('Easy'));s=await p.evaluate(()=>__wo.LIFTS[1].sets[1].w);ok(s===190,'Easy adds 5 lb to the next set: '+s);
await p.evaluate(()=>__wo.finish());s=await p.evaluate(()=>__wo.S.phase);ok(s==='done','finish');
await open('kitchen','cook');await p.evaluate(()=>__ck.next());await p.waitForTimeout(600);s=await p.evaluate(()=>({i:__ck.S.i,T:__ck.S.T.Brown,big:current.querySelector('.tk-big').textContent}));ok(s.i===1&&s.T>0&&s.big==='Brown the chicken','Next turns to Brown, whole, and starts its timer');
let L=await lines('.tk-how,.tk-cue,.tl,.tk-h,.tk-top span,.tk-steps div,.tk-verb');ok(!L.cut.length&&!L.stops.length,'cook lines whole, no stops '+L.cut.concat(L.stops).join('|'));
await open('kitchen','shop');s=await p.evaluate(()=>current.querySelector('.tk-big').textContent);ok(s==='Limes','shop starts with limes');
await p.evaluate(()=>{for(let k=0;k<4;k++)__sh.got()});s=await p.evaluate(()=>({a:__sh.S.a,big:current.querySelector('.tk-big').textContent}));ok(s.a===1&&s.big==='Feta','produce done, Dairy next: '+s.big);
L=await lines('.tk-how,.tk-cue,.tl,.tk-h,.tk-top span,.tk-big');ok(!L.cut.length&&!L.stops.length,'shop lines whole, no stops '+L.cut.concat(L.stops).join('|'));
await open('routines','tend');s=await p.evaluate(()=>current.querySelector('.dk-big').textContent);ok(s==='Counter','routine opens on Counter');
await p.evaluate(()=>{for(let k=0;k<3;k++)__rt.next()});await p.waitForTimeout(900);s=await p.evaluate(()=>({i:__rt.S.i,big:current.querySelector('.dk-big').textContent}));ok(s.i===1&&s.big==='Hamstrings','Tidy tended, Stretch begins: '+JSON.stringify(s));
L=await lines('.dk-big,.dk-cue,.dk-top span,.dk-h');ok(!L.cut.length&&!L.stops.length,'routine lines whole, no stops '+L.cut.concat(L.stops).join('|'));
ok(!errs.length,'no page errors '+errs.join('|'));console.log(bad?'FAILED '+bad:'All green');await b.close()})();
