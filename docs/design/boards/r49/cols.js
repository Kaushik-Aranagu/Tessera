// ---------- two columns, one section each. A swipe moves each column on: a column with more things shows its next set,
// a finished column takes the next section, and with no next section it stays. Swipes live on the column names and on the space under the last thing.
const ROWS=4,secMem={};let cols=[],hist=[];
const secA=(p,S)=>{const pn=pins[p]||[];return [...S.a.filter(x=>pn.includes(S.h+x.n)),...S.a.filter(x=>!pn.includes(S.h+x.n))]};
function pagesIn(p,i){const S=D[p][i];if(!S)return[[]];const a=secA(p,S).map(x=>({x,s:S})),out=[];let k=0;while(k<a.length){if(a.length-k<=ROWS){out.push(a.slice(k));break}out.push([...a.slice(k,k+ROWS-1),{more:a.length-k-(ROWS-1)}]);k+=ROWS-1}return out.length?out:[[]]}
function startCols(p){if(secMem[p])return JSON.parse(secMem[p]);const n=D[p].length;let e=D[p].findIndex(S=>S.a.some(x=>urgent(x)||x.v==='low'));if(e<0)e=0;if(e>n-2)e=Math.max(0,n-2);return n>1?[{si:e,pg:0},{si:e+1,pg:0}]:[{si:0,pg:0}]}
function stepCols(dir){const p=PLACES[pi],n=D[p].length;
  if(dir<0){if(!hist.length)return false;const old=cols;cols=hist.pop();return old}
  let next=Math.max(...cols.map(c=>c.si))+1;const nc=cols.map(c=>{if(c.pg<pagesIn(p,c.si).length-1)return{si:c.si,pg:c.pg+1};if(next<n)return{si:next++,pg:0};return c});
  if(JSON.stringify(nc)===JSON.stringify(cols))return false;hist.push(cols);const old=cols;cols=nc;return old}
function colHTML(p,c){const S=D[p][c.si];if(!S)return '';const P=pagesIn(p,c.si),pg=Math.min(c.pg,P.length-1);
  const lo=S.a.filter(x=>x.v==='low').length,ur=S.a.filter(urgent).length,al=`${S.h}, ${S.a.length}${lo?`, ${lo} low`:''}${ur?`, ${ur} to eat soon`:''}`;
  const head=`<div class="ch" aria-label="${al}" style="height:30px;display:flex;align-items:baseline;gap:6px;white-space:nowrap;overflow:hidden;font-size:15px;font-weight:600;color:var(--kitT);touch-action:none;cursor:ew-resize">${S.h}<span class="n" style="font-weight:300;color:var(--ink2)">${S.a.length}</span></div>`;
  const rows=P[pg].map(r=>{if(r.more)return `<div class="tail" style="height:48px;line-height:48px;font-size:13px;color:var(--ink2);touch-action:none">${r.more} more, swipe</div>`;
    const x=r.x,v=valOf(x),pinned=(pins[p]||[]).includes(S.h+x.n),fl=flash===x;
    return `<div class="rw" data-s="${S.h}" data-n="${x.n}" style="position:relative;height:48px;overflow:hidden"><div class="rc" role="button" tabindex="0" style="position:absolute;inset:0;display:flex;flex-direction:column;justify-content:center;white-space:nowrap;touch-action:pan-y;cursor:grab;background:var(--phone)"><span class="nm" style="font-size:17px;line-height:22px;overflow:hidden;color:${fl?'var(--kit)':'var(--ink)'};font-weight:${pinned||fl?600:400};transition:color .6s">${x.n}</span><span class="vv" style="font-size:13px;line-height:18px;overflow:hidden;color:${v.hot?'var(--kitT)':'var(--ink2)'};font-weight:${v.hot?600:400}">${pinned?'pinned'+(v.t?', ':''):''}${v.t}</span></div></div>`}).join('');
  return head+rows+`<div class="tail" style="flex:1;touch-action:none"></div>`}
function renderList(dir,old){const p=PLACES[pi];if(!cols.length)cols=startCols(p);secMem[p]=JSON.stringify(cols);
  const L=$('list');const body=c=>`<div class="col" style="display:flex;flex-direction:column;height:100%">${colHTML(p,c)}</div>`;
  if(!L.children.length||L.children.length!==cols.length)L.innerHTML=cols.map(()=>`<div class="cw" style="position:relative;overflow:hidden;min-width:0;height:100%"></div>`).join('');
  [...L.children].forEach((w,k)=>{const c=cols[k],changed=old&&JSON.stringify(old[k])!==JSON.stringify(c);
    if(changed&&!RM){const d=dir;w.innerHTML=`<div class="pA" style="position:absolute;inset:0">${w.innerHTML}</div><div class="pB" style="position:absolute;top:0;bottom:0;left:${d*100}%;width:100%">${body(c)}</div>`;const A=w.firstChild,B=w.lastChild;
      setTimeout(()=>anim(.42,(e,u)=>{const t=`translateX(${-d*100*spring(u)}%)`;A.style.transform=B.style.transform=t},()=>{w.innerHTML=body(c);wireRows();wireCols()}),k*60)}
    else w.innerHTML=body(c)});
  const n=D[p].length,mx=Math.max(...cols.map(c=>c.si)),left=D[p].slice(mx+1).map(S=>S.h);
  $('nextL').textContent=left.length?`Next: ${left.join(', ')}`:cols.some(c=>c.pg<pagesIn(p,c.si).length-1)?'More in these':'';
  wireRows();wireCols();
  if(flash){const f=flash;setTimeout(()=>{if(flash===f){flash=null;const e=[...document.querySelectorAll('#list .nm')].find(e=>e.textContent===f.n);if(e){e.style.color='var(--ink)';e.style.fontWeight=400}}},1400)}}
function move(dir){const old=stepCols(dir);if(!old){nudge(dir);return}renderList(dir,old)}
function nudge(dir){if(RM)return;const L=$('list');anim(.3,(e,u)=>L.style.transform=`translateX(${-dir*10*Math.sin(Math.PI*u)}px)`,()=>L.style.transform='')}
let cdrag=false;function wireCols(){document.querySelectorAll('#list .ch, #list .tail').forEach(el=>{if(el.dataset.w)return;el.dataset.w=1;let sx=null,sy=0;
  el.onpointerdown=e=>{sx=e.clientX;sy=e.clientY};el.onpointerup=e=>{if(sx==null)return;const dx=e.clientX-sx,dy=e.clientY-sy;sx=null;if(Math.abs(dx)>40&&Math.abs(dx)>Math.abs(dy))move(dx<0?1:-1)};el.onpointercancel=()=>sx=null})}
$('list').addEventListener('wheel',e=>{e.preventDefault();const L=$('list');const d=Math.abs(e.deltaX)>Math.abs(e.deltaY)?e.deltaX:0;if(Math.abs(d)>20&&!L.dataset.lock){L.dataset.lock=1;move(d>0?1:-1);setTimeout(()=>delete L.dataset.lock,500)}},{passive:false});
document.addEventListener('keydown',e=>{if(!$('put').hidden||!$('meal').hidden||document.activeElement.tagName==='INPUT')return;if(e.key==='PageDown'||e.key==='.')move(1);if(e.key==='PageUp'||e.key===',')move(-1)});
