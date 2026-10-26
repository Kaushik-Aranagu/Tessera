// ---------- two columns. Sections are packed: small sections stack in one column when they fit whole, in order, and any later
// section that fits fills the space left (first fit). A section too long for a column pages inside it. A swipe moves each column on:
// a column part-way through a section shows the rest of it, a finished column takes the next sections, and with nothing left it stays.
const CAP=232,HH=26,RH=44,secMem={};let ST=null,hist=[];
const secA=(p,S)=>{const pn=pins[p]||[];return [...S.a.filter(x=>pn.includes(S.h+x.n)),...S.a.filter(x=>!pn.includes(S.h+x.n))]};
const lenOf=(p,si)=>D[p][si]?D[p][si].a.length:0;
function fillCol(p,q,lead){const col=[];let space=CAP;
  const put=(si,start,first)=>{const rem=lenOf(p,si)-start;if(rem<=0)return true;const need=HH+rem*RH;if(need<=space){col.push({si,start,k:rem});space-=need;return true}
    if(first){const k=Math.max(1,Math.floor((space-HH)/RH)-1);col.push({si,start,k});space=0;return true}return false};
  if(lead)put(lead.si,lead.start,true);else if(q.length){const h=q.shift();put(h.si,h.start,true)}
  for(let i=0;i<q.length&&space>HH;){if(put(q[i].si,q[i].start,false))q.splice(i,1);else i++}
  return col}
function startST(p){if(secMem[p])return JSON.parse(secMem[p]);const n=D[p].length;let e=D[p].findIndex(S=>S.a.some(x=>urgent(x)||x.v==='low'));if(e<0)e=0;
  const q=[...Array(n).keys()].map(i=>({si:(e+i)%n,start:0}));const cols=[fillCol(p,q),fillCol(p,q)];return{cols,q}}
const partOf=(p,col)=>{const b=col[col.length-1];return b&&b.start+b.k<lenOf(p,b.si)?{si:b.si,start:b.start+b.k}:null};
function stepST(dir){const p=PLACES[pi];if(dir<0){if(!hist.length)return false;const old=ST;ST=hist.pop();return old}
  const q=JSON.parse(JSON.stringify(ST.q));const cols=ST.cols.map(col=>{const lead=partOf(p,col);if(lead)return fillCol(p,q,lead);if(q.length)return fillCol(p,q);return col});
  const nx={cols,q};if(JSON.stringify(nx)===JSON.stringify(ST))return false;hist.push(ST);if(hist.length>6)hist.shift();const old=ST;ST=nx;return old}
function colHTML(p,col){return col.map(b=>{const S=D[p][b.si];if(!S)return '';const a=secA(p,S),k=Math.min(b.k,Math.max(0,a.length-b.start)),more=a.length-b.start-k;
  const lo=S.a.filter(x=>x.v==='low').length,ur=S.a.filter(urgent).length,al=`${S.h}, ${S.a.length}${lo?`, ${lo} low`:''}${ur?`, ${ur} to eat soon`:''}`;
  const head=`<div class="ch" aria-label="${al}" style="height:${HH}px;flex:none;display:flex;align-items:flex-end;gap:6px;white-space:nowrap;overflow:hidden;font-size:15px;line-height:20px;font-weight:600;color:var(--kitT);touch-action:none;cursor:ew-resize">${S.h}<span class="n" style="font-weight:300;color:var(--ink2)">${b.start?`${b.start+1} to ${b.start+k} of ${S.a.length}`:S.a.length}</span></div>`;
  const rows=a.slice(b.start,b.start+k).map(x=>{const v=valOf(x),pinned=(pins[p]||[]).includes(S.h+x.n),fl=flash===x;
    return `<div class="rw" data-s="${S.h}" data-n="${x.n}" style="position:relative;height:${RH}px;flex:none;overflow:hidden"><div class="rc" role="button" tabindex="0" style="position:absolute;inset:0;display:flex;flex-direction:column;justify-content:center;white-space:nowrap;touch-action:pan-y;cursor:grab;background:var(--phone)"><span class="nm" style="font-size:17px;line-height:22px;overflow:hidden;color:${fl?'var(--kit)':'var(--ink)'};font-weight:${pinned||fl?600:400};transition:color .6s">${x.n}</span><span class="vv" style="font-size:11px;line-height:16px;letter-spacing:.01em;overflow:hidden;color:${v.hot?'var(--kitT)':'var(--ink2)'};font-weight:${v.hot?600:400}">${pinned?'pinned'+(v.t?', ':''):''}${v.t}</span></div></div>`}).join('');
  return head+rows+(more>0?`<div class="tail" style="height:${RH}px;flex:none;line-height:${RH}px;font-size:11px;color:var(--ink2);touch-action:none">${more} more, swipe</div>`:'')}).join('')+`<div class="tail" style="flex:1;touch-action:none"></div>`}
function renderList(dir,old){const p=PLACES[pi];if(!ST)ST=startST(p);secMem[p]=JSON.stringify(ST);const cols=ST.cols;
  const L=$('list');const body=c=>`<div class="col" style="display:flex;flex-direction:column;height:100%">${colHTML(p,c)}</div>`;
  if(L.children.length!==cols.length)L.innerHTML=cols.map(()=>`<div class="cw" style="position:relative;overflow:hidden;min-width:0;height:100%"></div>`).join('');
  [...L.children].forEach((w,k)=>{const c=cols[k],changed=old&&JSON.stringify(old.cols[k])!==JSON.stringify(c);
    if(changed&&!RM){const d=dir;w.innerHTML=`<div class="pA" style="position:absolute;inset:0">${w.innerHTML}</div><div class="pB" style="position:absolute;top:0;bottom:0;left:${d*100}%;width:100%">${body(c)}</div>`;const A=w.firstChild,B=w.lastChild;
      setTimeout(()=>anim(.42,(e,u)=>{const t=`translateX(${-d*100*spring(u)}%)`;A.style.transform=B.style.transform=t},()=>{w.innerHTML=body(c);wireRows();wireCols()}),k*60)}
    else w.innerHTML=body(c)});
  const left=ST.q.map(z=>D[p][z.si]&&D[p][z.si].h).filter(Boolean),parts=cols.map(c=>partOf(p,c)).filter(Boolean).map(z=>D[p][z.si].h);
  $('nextL').textContent=left.length?`Next: ${left.join(', ')}`:parts.length?`Next: the rest of ${parts.join(' and ')}`:'';
  wireRows();wireCols();
  if(flash){const f=flash;setTimeout(()=>{if(flash===f){flash=null;const e=[...document.querySelectorAll('#list .nm')].find(e=>e.textContent===f.n);if(e){e.style.color='var(--ink)';e.style.fontWeight=400}}},1400)}}
function move(dir){const old=stepST(dir);if(!old){nudge(dir);return}renderList(dir,old)}
