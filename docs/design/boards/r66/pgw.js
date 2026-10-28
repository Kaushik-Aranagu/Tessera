// 388: the ticket comes off the rail. Wash on the Galley landing counts the dishes down on their own ticket, then the
// ticket is pulled off the rail (the clip lets go, it tips from one corner and lifts away, its words do not reflow)
// and the others spread to fill the slot. The widget drops its dishes card (the next one comes up if it was showing)
// and the action word says the sink is clear. Undo hangs it back: 7 waiting, the card, the object. Washing a clear
// sink only says so. Coming back to the room after the wash: three tickets, no dishes card. Paper, black; Reduce
// Motion: in place, no count.
const {chromium}=require('/opt/node22/lib/node_modules/playwright');
async function run(look,rm,onDish){const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});
 const pg=await b.newPage({viewport:{width:402,height:874},reducedMotion:rm?'reduce':'no-preference'});const errs=[];pg.on('pageerror',e=>errs.push(e.message));
 await pg.goto('file://'+__dirname+'/index.html');await pg.waitForTimeout(600);await pg.evaluate(l=>setLook(l),look);
 await pg.evaluate(()=>{dishes=7;reset('home');go('kitchen')});await pg.waitForTimeout(1600);
 const st=()=>pg.evaluate(()=>{const tk=[...current.querySelectorAll('.tk')];const d=tk.find(t=>t.querySelector('.ttk').textContent==='Dishes');const r=current.querySelector('.receipt');
  const live=tk.filter(t=>t!==d||(!t.classList.contains('gone')&&t.style.display!=='none')).map(t=>t.getBoundingClientRect());
  return {n:tk.length,gone:d?d.classList.contains('gone')||d.style.display==='none':null,li:d?[...d.querySelectorAll('.face.front .li')].map(l=>l.textContent):[],sw:d?d.querySelector('.sheet').style.width:'',
   ws:live.map(r=>Math.round(r.width)),ov:live.some((a,i)=>live.some((c,j)=>j>i&&a.right>c.left+1)),rc:r?r.textContent:'',dishes:__gal.dishes,w:__gal.w.join('|'),wash:__gal.acts[2],
   card:[...current.querySelectorAll('.lw .blk .hdr')].map(e=>e.textContent).pop()||''}});
 const r={look,rm,onDish};r.before=await st();
 if(onDish){const bx=await pg.evaluate(()=>{const q=current.querySelector('.lw').getBoundingClientRect();return [q.left+q.width/2,q.top+q.height/2]});
  for(let k=0;k<3;k++){await pg.mouse.move(bx[0],bx[1]);await pg.mouse.down();for(let j=1;j<=6;j++)await pg.mouse.move(bx[0],bx[1]-j*14);await pg.mouse.up();await pg.waitForTimeout(500)}r.shown=await st()}
 await pg.evaluate(()=>__gal.wash());await pg.waitForTimeout(rm?60:260);r.mid=await st();
 await pg.waitForTimeout(rm?300:1900);r.end=await st();
 await pg.click('.receipt button');await pg.waitForTimeout(1100);r.undone=await st();
 await pg.evaluate(()=>__gal.wash());await pg.waitForTimeout(2400);await pg.evaluate(()=>{const r=current.querySelector('.receipt');r&&r.remove()});
 await pg.evaluate(()=>__gal.wash());await pg.waitForTimeout(200);r.again=await st();
 await pg.evaluate(()=>{reset('home');go('kitchen')});await pg.waitForTimeout(1600);r.back=await st();
 r.errs=errs;await b.close();return r}
(async()=>{for(const [l,m,d] of [['paper',false,false],['black',false,false],['paper',true,false],['paper',false,true]]){const r=await run(l,m,d);
 const nums=s=>(s.li[0]||'').match(/^(\d) waiting$/);
 const chk={start:r.before.n===4&&r.before.li.join('|')==='7 waiting|since lunch'&&/Since lunch/.test(r.before.w)&&r.before.wash==='7 dishes',
  count:m?r.mid.li[0]==='the sink is clear':!!nums(r.mid)&&+nums(r.mid)[1]<7&&+nums(r.mid)[1]>0&&!r.mid.gone,
  off:r.end.gone&&r.end.li.join('|')==='the sink is clear|all put away'&&r.end.ws.length===3&&Math.max(...r.end.ws)-Math.min(...r.end.ws)<=1&&r.end.ws[0]>r.before.ws[0]&&!r.end.ov,
  words:m||r.end.sw!=='',
  receipt:r.end.rc==='Dishes, done Undo'&&!/\.\s*Undo/.test(r.end.rc),
  widget:!/Since lunch/.test(r.end.w)&&(!d||(r.shown.card==='Since lunch'&&r.end.card==='Tonight')),
  act:r.end.wash==='the sink is clear',
  undo:!r.undone.gone&&r.undone.li.join('|')==='7 waiting|since lunch'&&r.undone.dishes===7&&/Since lunch/.test(r.undone.w)&&r.undone.wash==='7 dishes'&&r.undone.sw===''&&r.undone.ws.length===4&&!r.undone.ov,
  again:r.again.rc==='The sink is clear'&&r.again.dishes===0,
  back:r.back.n===3&&!/Since lunch/.test(r.back.w)&&r.back.wash==='the sink is clear',
  errs:!r.errs.length};
 const ok=Object.values(chk).every(Boolean);console.log(ok?'ok':'FAIL',l,m?'rm':'',d?'on the dishes card':'',JSON.stringify(chk));if(!ok||process.env.V)console.log(JSON.stringify(r))}})();
