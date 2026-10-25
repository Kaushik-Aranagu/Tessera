/* ================= v3: one landing for every room (283 v2, his 12:22, 12:26 and 2:44 PM notes, Oct 25) =================
   The room landing keeps Bridge's four bands, so sections persist from Home into every room:
   top (title and nav word, then the switcher band: a text-only switcher on the left, the room's needs beside it),
   keystone (the mosaic's slot), the middle band where Bridge has its one thing (what's going on: the summary and the latest,
   arriving in the room's own way), and the doors dial where Bridge has its apps (depth blur on the left, the room's summary on the right).
   Every section opens the Bridge way: it rises 10 pt out of a 3 pt blur at 95 percent size, 80 ms apart. */
{const st=document.createElement('style');st.textContent=`
.lnav{position:absolute;right:16px;top:56px;font:500 15px var(--sans);color:var(--ink2);background:none;border:0;min-height:44px;padding:0 8px;cursor:pointer;z-index:6}
.lband{position:absolute;left:0;right:0;top:106px;height:76px;z-index:6}
.swx{position:absolute;left:24px;top:0;width:200px;height:76px;touch-action:none;cursor:grab;overflow:hidden}
.swx .sw{position:absolute;left:0;top:10px;height:56px;line-height:56px;white-space:nowrap;font:300 38px/56px var(--sans);letter-spacing:-.025em;color:var(--ink);font-variation-settings:'wght' 300}
.swx .sw .ch{display:inline-block;white-space:pre;transform-origin:50% 70%;will-change:transform}
.swx .pk{position:absolute;top:10px;line-height:56px;font:300 38px/56px var(--sans);letter-spacing:-.025em;color:var(--ink2);white-space:nowrap;opacity:.0;filter:blur(1.5px);pointer-events:none}
.swn{position:absolute;left:228px;right:24px;top:18px;height:52px;overflow:hidden}
.swn .ln{font-size:15px;line-height:24px;height:24px;white-space:nowrap;overflow:hidden;color:var(--ink2)}
.swn .ln:first-child{font-weight:600;color:var(--ink)}
.swn.rise{animation:lrise .32s cubic-bezier(.3,.9,.3,1)}
.lcap{position:absolute;left:24px;right:24px;top:388px;height:22px;font-size:15px;color:var(--ink2);white-space:nowrap;overflow:hidden;z-index:6}
.lmid{position:absolute;left:24px;right:24px;top:420px;height:192px;z-index:6}
.lmid .lsy{height:64px;font:300 24px/32px var(--sans);letter-spacing:-.01em;overflow:hidden}
.lmid .lsy b{font-weight:600}
.lmid .rows{position:absolute;left:0;right:0;top:84px;height:100px;overflow:hidden;touch-action:pan-y}
.lmid .rw{position:absolute;left:0;right:0;height:44px;line-height:44px;font:300 18px/44px var(--sans);white-space:nowrap;overflow:hidden;cursor:pointer;touch-action:none;transition:top .36s cubic-bezier(.3,.9,.3,1)}
.lmid .rw b{font-weight:600}
.lsum{position:absolute;left:186px;right:24px;top:652px;height:96px;z-index:6}
.lsum .lb{font-size:13px;color:var(--ink2);height:20px;white-space:nowrap;overflow:hidden}
.lsum .ln{font-size:16px;line-height:24px;height:24px;white-space:nowrap;overflow:hidden}
.lsum .ln:first-of-type{font-weight:700}
.lsum.rise{animation:lrise .3s cubic-bezier(.3,.9,.3,1)}
@keyframes lrise{from{transform:translateY(6px);clip-path:inset(0 0 100% 0)}to{transform:none;clip-path:inset(0 0 -10% 0)}}
.lkey{position:absolute;inset:0;pointer-events:none}.lkey>*{pointer-events:auto}
.lclip{position:absolute;top:196px;height:182px;overflow:hidden}
.lclip iframe{position:absolute;top:-196px;width:402px;height:874px;border:0;background:transparent}
.lsec{transform-origin:left top;animation:lopen .5s cubic-bezier(.2,.8,.2,1) both;animation-delay:calc(var(--i)*80ms + var(--d0,0ms))}
@keyframes lopen{from{transform:translateY(10px) scale(.95);filter:blur(3px);clip-path:inset(0 0 100% 0)}to{transform:none;filter:blur(0);clip-path:inset(-40px -40px -40px -40px)}}
.lsec.rm{animation:lfade .15s linear both}
@keyframes lfade{from{opacity:0}to{opacity:1}}
.bfact{position:absolute;left:186px;right:24px;top:688px;height:24px;font-size:15px;font-weight:500;color:var(--ink2);white-space:nowrap;overflow:hidden}
.bfact.rise{animation:lrise .3s cubic-bezier(.3,.9,.3,1)}
.tw{display:inline-block;white-space:pre}
.act{position:absolute;left:24px;bottom:22px;width:220px;height:64px;z-index:6;cursor:pointer;touch-action:none}
.act .av{font:600 24px/32px var(--sans);letter-spacing:-.01em;white-space:nowrap;display:inline-block;transition:letter-spacing .2s}
.act .av .ch{display:inline-block;white-space:pre}
.act .av.filling{color:transparent;background:linear-gradient(currentColor,currentColor) no-repeat left/0% 100%,linear-gradient(color-mix(in srgb,var(--room,currentColor) 40%,transparent),color-mix(in srgb,var(--room,currentColor) 40%,transparent));-webkit-background-clip:text;background-clip:text}
.act .ao{font:500 13px/18px var(--sans);color:var(--ink2);white-space:nowrap;overflow:hidden;max-width:220px}

`;document.head.appendChild(st)}

const SMALL=/^(and|or|of|the|a|an|to|for|with|at|in|on|by)$/i;
function fitLine(e){let n=0;while(e.scrollWidth>e.clientWidth+1&&n++<30){const tw=document.createTreeWalker(e,NodeFilter.SHOW_TEXT);let last=null,x;while(x=tw.nextNode())if(x.nodeValue.trim())last=x;if(!last)break;
 let w=last.nodeValue.replace(/\s+$/,'').split(' ');w.pop();while(w.length&&SMALL.test(w[w.length-1]))w.pop();last.nodeValue=w.join(' ').replace(/[,;:]+$/,'');}}
function fitAll(host){host.querySelectorAll('.ln,.lb,.lcap,.bfact,.rw').forEach(fitLine)}
function opening(secs,d0){secs.forEach((e,i)=>{if(!e)return;e.style.setProperty('--i',i);if(d0)e.style.setProperty('--d0',d0+'ms');e.classList.add('lsec');if(RM)e.classList.add('rm');
 e.addEventListener('animationend',function f(ev){if(ev.target!==e)return;e.classList.remove('lsec','rm');e.style.removeProperty('--i');e.removeEventListener('animationend',f)})})}

/* ---------- the switcher: text only. Swipe across or up and down; each axis carries its own list, or the same one.
   Across: the letters stream out in a wave, leaning with the swipe, and the new word streams in, landing heavy and settling light.
   Up and down: the letters roll over like a drum, one after another. While you drag, the word follows the finger, its letters
   spread and it gains weight; the next word shows at the far edge. Every few seconds a light weight wave passes through it. */
function switcherX(host,cfg,onChange){const ax={x:cfg.x||[],y:cfg.y||cfg.x||[]};let ix={x:0,y:0},last='x';
 const word=()=>ax[last][ix[last]];
 const sw=h('div','sw'),pk=h('div','pk');host.appendChild(pk);host.appendChild(sw);
 const letters=(t)=>{sw.innerHTML='';return [...t].map(c=>{const s=h('span','ch');s.textContent=c;sw.appendChild(s);return s})};
 let L=letters(word().k);sw.style.color=word().c||'var(--ink)';
 const anim=(e,kf,o)=>RM?null:e.animate(kf,o);
 function commit(axis,dir){const list=ax[axis];if(list.length<2)return;const old=L,oldW=sw.cloneNode(true);oldW.style.pointerEvents='none';host.appendChild(oldW);
  ix[axis]=(ix[axis]+dir+list.length)%list.length;if(axis==='x'&&ax.y===ax.x)ix.y=ix.x;if(axis==='y'&&ax.y===ax.x)ix.x=ix.y;last=axis;
  sw.style.transform='';sw.style.letterSpacing='';sw.style.fontVariationSettings='';L=letters(word().k);sw.style.color=word().c||'var(--ink)';pk.style.opacity=0;onChange(word(),axis);
  if(RM){oldW.remove();return}
  const OL=[...oldW.children];
  if(axis==='x'){OL.forEach((c,i)=>{const j=dir>0?i:OL.length-1-i;anim(c,[{transform:'none',filter:'blur(0)',opacity:1},{transform:'translateX('+(-dir*70)+'px) skewX('+(dir*24)+'deg)',filter:'blur(2.5px)',opacity:0}],{duration:300,delay:j*14,easing:'cubic-bezier(.5,0,.8,.4)',fill:'both'})});
   L.forEach((c,i)=>{const j=dir>0?i:L.length-1-i;anim(c,[{transform:'translateX('+(dir*90)+'px) skewX('+(-dir*22)+'deg)',filter:'blur(3px)',opacity:0,fontVariationSettings:"'wght' 800"},{transform:'translateX('+(-dir*4)+'px) skewX('+(dir*4)+'deg)',filter:'blur(0)',opacity:1,fontVariationSettings:"'wght' 700",offset:.55},{transform:'none',filter:'blur(0)',opacity:1,fontVariationSettings:"'wght' 300"}],{duration:720,delay:120+j*22,easing:'cubic-bezier(.2,.8,.2,1)',fill:'both'})})}
  else{OL.forEach((c,i)=>{anim(c,[{transform:'perspective(200px) rotateX(0)',opacity:1},{transform:'perspective(200px) translateY('+(-dir*26)+'px) rotateX('+(dir*80)+'deg)',opacity:0,filter:'blur(2px)'}],{duration:300,delay:i*18,easing:'cubic-bezier(.5,0,.8,.4)',fill:'both'})});
   L.forEach((c,i)=>{anim(c,[{transform:'perspective(200px) translateY('+(dir*30)+'px) rotateX('+(-dir*85)+'deg)',opacity:0,filter:'blur(2px)',fontVariationSettings:"'wght' 600"},{transform:'perspective(200px) translateY('+(-dir*3)+'px) rotateX('+(dir*8)+'deg)',opacity:1,filter:'blur(0)',offset:.7},{transform:'none',opacity:1,filter:'blur(0)',fontVariationSettings:"'wght' 300"}],{duration:620,delay:110+i*24,easing:'cubic-bezier(.2,.8,.2,1)',fill:'both'})})}
  setTimeout(()=>oldW.remove(),340+OL.length*24)}
 // drag: the word follows, letters spread and weigh more; the next word shows at the edge
 let x0=null,y0,dx,dy,a;
 host.onpointerdown=e=>{x0=e.clientX;y0=e.clientY;dx=dy=0;a=null;host.setPointerCapture(e.pointerId);e.stopPropagation()};
 host.onpointermove=e=>{if(x0==null)return;dx=(e.clientX-x0)/K;dy=(e.clientY-y0)/K;a=lockAxis(dx,dy,a);if(!a)return;const d=a==='x'?dx:dy,u=Math.min(1,Math.abs(d)/90);
  sw.style.transform=a==='x'?'translateX('+d*.8+'px) skewX('+(-d*.06)+'deg)':'translateY('+d*.5+'px)';sw.style.letterSpacing=(-.025+u*.08)+'em';sw.style.fontVariationSettings="'wght' "+Math.round(300+u*300);
  const list=ax[a],nx=list[(ix[a]+(d<0?1:-1)+list.length)%list.length];if(list.length>1){pk.textContent=nx.k;pk.style.opacity=(u*.7).toFixed(2);
   if(a==='x'){pk.style.left=(d<0?200-u*60:-pk.offsetWidth+u*60)+'px';pk.style.top='10px'}else{pk.style.left='0';pk.style.top=(d<0?66-u*30:-46+u*30)+'px'}}};
 host.onpointerup=()=>{if(x0==null)return;x0=null;const d=a==='x'?dx:dy;
  if(a&&Math.abs(d)>40){commit(a,d<0?1:-1);return}
  if(!a){commit('x',1);return}
  if(!RM)sw.animate([{transform:sw.style.transform||'none'},{transform:'none'}],{duration:280,easing:'cubic-bezier(.3,1.4,.4,1)'});sw.style.transform='';sw.style.letterSpacing='';sw.style.fontVariationSettings='';pk.style.opacity=0};
 // breath: a light weight wave through the letters, about every 9 s, 1.2 s long
 const br=RM?0:setInterval(()=>{if(x0!=null)return;L.forEach((c,i)=>c.animate([{fontVariationSettings:"'wght' 300"},{fontVariationSettings:"'wght' 520"},{fontVariationSettings:"'wght' 300"}],{duration:700,delay:i*45,easing:'ease-in-out'}))},9000);
 onChange(word(),'x');return ()=>clearInterval(br)}

/* ---------- the middle band: what's going on, arriving the room's own way ---------- */
const THEMES={
 type:(els)=>{els.forEach(e=>{const t=e.innerHTML;const nodes=[];const walk=n=>{[...n.childNodes].forEach(c=>{if(c.nodeType===3){const f=document.createDocumentFragment();[...c.nodeValue].forEach(ch=>{const s=h('span','tw');s.textContent=ch;s.style.visibility='hidden';nodes.push(s);f.appendChild(s)});c.replaceWith(f)}else walk(c)})};walk(e);
  nodes.forEach((s,i)=>setTimeout(()=>{s.style.visibility=''},260+i*16))})},          // Log: typed in, a letter at a time
 wind:(els)=>words(els,(w,i)=>w.animate([{transform:'translateX(40px)',filter:'blur(3px)',opacity:0},{transform:'none',filter:'blur(0)',opacity:1}],{duration:700,delay:260+i*45,easing:'cubic-bezier(.2,.8,.2,1)',fill:'both'})), // Lookout: blown in from the right
 chalk:(els)=>els.forEach((e,i)=>e.animate([{clipPath:'inset(0 100% 0 0)'},{clipPath:'inset(0 0 0 0)'}],{duration:900,delay:260+i*300,easing:'steps(18,end)',fill:'both'})), // Deck: written on, stroke by stroke
 steam:(els)=>words(els,(w,i)=>w.animate([{transform:'translateY(14px) rotate(-3deg)',filter:'blur(2px)',opacity:0},{transform:'translateY(-3px) rotate(1deg)',opacity:1,offset:.6},{transform:'none',filter:'blur(0)',opacity:1}],{duration:800,delay:260+i*40,easing:'ease-out',fill:'both'})), // Galley: rises like steam
 grow:(els)=>words(els,(w,i)=>w.animate([{transform:'scaleY(0)',transformOrigin:'50% 85%'},{transform:'scaleY(1.12)',transformOrigin:'50% 85%',offset:.65},{transform:'none',transformOrigin:'50% 85%'}],{duration:700,delay:260+i*55,easing:'cubic-bezier(.2,.8,.2,1)',fill:'both'})), // Watch: grows from the ground
 roll:(els)=>{els.forEach(e=>e.querySelectorAll('.o').forEach(n=>{const to=n.textContent,v=parseFloat(to.replace(/,/g,''));if(isNaN(v))return;const dec=(to.split('.')[1]||'').length,t0=performance.now();
  const f=now=>{const u=Math.min(1,(now-t0-260)/900);const k=u<0?0:1-Math.pow(1-u,3);n.textContent=(v*k).toLocaleString('en-US',{minimumFractionDigits:dec,maximumFractionDigits:dec});if(u<1)requestAnimationFrame(f);else n.textContent=to};requestAnimationFrame(f)}));
  words(els,(w,i)=>w.animate([{transform:'translateY(8px)',clipPath:'inset(0 0 100% 0)'},{transform:'none',clipPath:'inset(0 0 -20% 0)'}],{duration:500,delay:200+i*30,easing:'cubic-bezier(.2,.8,.2,1)',fill:'both'}))}}; // Purse: numbers count up
function words(els,fn){let k=0;els.forEach(e=>{const walk=n=>{[...n.childNodes].forEach(c=>{if(c.nodeType===3){const f=document.createDocumentFragment();c.nodeValue.split(/(\s+)/).forEach(p=>{if(!p)return;if(/^\s+$/.test(p)){f.appendChild(document.createTextNode(p));return}const s=h('span','tw');s.textContent=p;f.appendChild(s);if(!RM)fn(s,k++)});c.replaceWith(f)}else if(c.classList&&c.classList.contains('o')){c.style.display='inline-block';if(!RM)fn(c,k++)}else walk(c)})};walk(e)})}
function rowsOf(host,el,items){let list=items.slice();
 const draw=()=>{host.innerHTML='';list.slice(0,2).forEach((it,i)=>{const r=h('div','rw',it.h);r.style.top=(i*52)+'px';host.appendChild(r);fitLine(r);let x0=null,dx=0,ax=null,y0;
  r.onpointerdown=e=>{x0=e.clientX;y0=e.clientY;dx=0;ax=null;r.setPointerCapture(e.pointerId)};
  r.onpointermove=e=>{if(x0==null)return;dx=(e.clientX-x0)/K;ax=lockAxis(dx,(e.clientY-y0)/K,ax);if(ax==='x'){r.style.transition='none';r.style.transform='translateX('+Math.max(-110,Math.min(110,dx))+'px)'}};
  r.onpointerup=()=>{if(x0==null)return;x0=null;r.style.transition='';r.style.transform='';
   if(ax==='x'&&Math.abs(dx)>90){const k=list.indexOf(it);list.splice(k,1);draw();receipt(el,it.name+(dx>0?', done.':', not now.'),()=>{list.splice(k,0,it);draw()});return}
   if(!ax&&it.go)go(...it.go)}})};
 draw()}

/* ---------- the middle band: Bridge's widget, carried into every room (283 v3, his 3:57 PM note) ----------
   Same box as Bridge's one thing (top 400, 212 tall): Header, Big line, Middle line, Small line, and the Glyph on the right.
   It swipes the way Bridge's does: across and up or down for the room's next thing, hold the Big line to strike it
   (Done, Undo 10 s), tap to open. The Glyph follows the item: a small library of drawings, picked by rules from the
   item's words (Tess picks later). When an item arrives, something leaves the keystone and lands in the widget: a word
   lifts off the Log's wall, a ticket tears off the Galley's rail, chalk dust falls from the Deck's board, rain drips from
   the Lookout's glass, a bird flies down from the Watch's woods, a dot slides off the Purse's index. */
const G={// the glyph library: 80 x 80, drawn in the item's colour c; each returns its motion
 words:(s,c,it)=>{// the cover for anything the library has no drawing for: the item's own words, set like the wall
  const pool=[it.big,...(it.mid||'').split(/[ ,]+/)].map(w=>(w||'').replace(/<[^>]+>/g,'').toUpperCase()).filter(w=>w.length>2&&!/^(THE|AND|FOR|WITH|YOU|ALL)$/.test(w));
  const W=[...new Set(pool)].slice(0,3),cols=['var(--kitchen)','var(--training)','var(--lists)','var(--routines)','var(--teal)'];let y=0;
  s.innerHTML=W.map((t,i)=>{const z=Math.max(10,Math.min(24,82/(t.length*.68)));y+=z*.86+2;return '<text x="80" y="'+y.toFixed(1)+'" text-anchor="end" font-family="Figtree" font-weight="900" font-size="'+z.toFixed(1)+'" letter-spacing="-.5" style="fill:'+(i?cols[(t.length+i)%5]:c)+'">'+t+'</text>'}).join('');
  const T=[...s.children];return ()=>T.forEach((t,i)=>t.animate([{transform:'translateY(-10px)',opacity:0},{transform:'none',opacity:1}],{duration:360,delay:i*140,easing:'cubic-bezier(.2,.8,.2,1)',fill:'both'}))},
 checklist:(s,c)=>{s.innerHTML=[18,38,58].map((y,i)=>'<path d="M8 '+y+'l5 5 9-10" fill="none" stroke="'+c+'" stroke-width="3" stroke-linecap="round" stroke-linejoin="round" opacity="'+(i?.25:1)+'"/><path d="M30 '+(y+1)+'h'+(44-i*8)+'" stroke="'+c+'" stroke-width="3" stroke-linecap="round" opacity="'+(i?.5:.9)+'"/>').join('');
  const P=[...s.querySelectorAll('path')];return ()=>{const t=P[2],n=t.getTotalLength();t.style.strokeDasharray=n;t.animate([{strokeDashoffset:n,opacity:.25},{strokeDashoffset:0,opacity:1}],{duration:500,delay:300,easing:'ease-out',fill:'both'})}},
 spark:(s,c)=>{s.innerHTML='<g style="transform-origin:40px 40px"><path d="M40 10c3 18 12 27 30 30-18 3-27 12-30 30-3-18-12-27-30-30 18-3 27-12 30-30z" fill="'+c+'"/></g><circle cx="66" cy="16" r="4" fill="'+c+'" opacity=".6"/><circle cx="16" cy="66" r="3" fill="'+c+'" opacity=".4"/>';
  const g=s.firstChild;return ()=>g.animate([{transform:'scale(.4) rotate(-45deg)',opacity:.3},{transform:'scale(1.12) rotate(6deg)',opacity:1,offset:.6},{transform:'none'}],{duration:900,easing:'cubic-bezier(.2,.8,.2,1)'})},
 bulb:(s,c)=>{s.innerHTML='<path d="M40 12a18 18 0 0 1 10 33c-2 2-3 4-3 7H33c0-3-1-5-3-7a18 18 0 0 1 10-33z" fill="'+c+'" opacity=".25"/><path d="M40 12a18 18 0 0 1 10 33c-2 2-3 4-3 7H33c0-3-1-5-3-7a18 18 0 0 1 10-33z" fill="none" stroke="'+c+'" stroke-width="3"/><path d="M33 60h14M35 67h10" stroke="'+c+'" stroke-width="3" stroke-linecap="round"/>';
  const f=s.firstChild;return ()=>f.animate([{opacity:.25},{opacity:1,offset:.15},{opacity:.4,offset:.3},{opacity:1,offset:.5},{opacity:.85}],{duration:1200,fill:'both'})},
 book:(s,c)=>{s.innerHTML='<path d="M40 22c-8-6-20-7-30-4v46c10-3 22-2 30 4z" fill="'+c+'" opacity=".85"/><g style="transform-origin:40px 44px"><path d="M40 22c8-6 20-7 30-4v46c-10-3-22-2-30 4z" fill="'+c+'"/></g>';
  const p=s.lastChild;return ()=>p.animate([{transform:'perspective(120px) rotateY(-150deg)'},{transform:'perspective(120px) rotateY(10deg)',offset:.7},{transform:'none'}],{duration:900,easing:'cubic-bezier(.3,.8,.3,1)'})},
 rain:(s,c)=>{s.innerHTML='<path d="M20 44a12 12 0 0 1 6-22 16 16 0 0 1 30 2 10 10 0 0 1 4 20z" fill="'+c+'" opacity=".55"/>'+[24,36,48,60].map(x=>'<line x1="'+x+'" y1="52" x2="'+(x-4)+'" y2="62" stroke="'+c+'" stroke-width="3" stroke-linecap="round" opacity="0"/>').join('');
  const cl=s.firstChild,D=[...s.querySelectorAll('line')];return ()=>{cl.animate([{transform:'translateX(-6px)'},{transform:'translateX(3px)'},{transform:'none'}],{duration:1800,easing:'ease-in-out'});
   D.forEach((d,i)=>d.animate([{transform:'translateY(-4px)',opacity:0},{opacity:1,offset:.2},{transform:'translateY(14px)',opacity:0}],{duration:700,delay:i*170+(i%2)*90,iterations:3,easing:'ease-in'}))}},
 moon:(s,c)=>{s.innerHTML='<path d="M50 14a26 26 0 1 0 16 46A22 22 0 0 1 50 14z" fill="'+c+'" opacity=".8"/>'+[[18,18],[68,24],[24,66]].map(([x,y])=>'<circle cx="'+x+'" cy="'+y+'" r="2.2" fill="'+c+'"/>').join('');
  const St=[...s.querySelectorAll('circle')];return ()=>St.forEach((t,i)=>t.animate([{opacity:0},{opacity:1},{opacity:.3},{opacity:1}],{duration:1400,delay:i*250}))},
 sun:(s,c)=>{s.innerHTML='<circle cx="40" cy="40" r="13" fill="'+c+'"/><g style="transform-origin:40px 40px">'+[0,45,90,135,180,225,270,315].map(r=>'<path d="M40 14v-8" stroke="'+c+'" stroke-width="3.5" stroke-linecap="round" transform="rotate('+r+' 40 40)"/>').join('')+'</g>';
  const g=s.lastChild;return ()=>g.animate([{transform:'rotate(-40deg) scale(.7)',opacity:.3},{transform:'none',opacity:1}],{duration:1100,easing:'cubic-bezier(.2,.8,.2,1)'})},
 barbell:(s,c)=>{s.innerHTML='<g><rect x="8" y="38" width="64" height="4" rx="2" fill="'+c+'" opacity=".5"/>'+[[12,18],[20,26],[54,26],[62,18]].map(([x,hh])=>'<rect x="'+(x-3)+'" y="'+(40-hh)+'" width="7" height="'+(hh*2)+'" rx="2" fill="'+c+'"/>').join('')+'</g>';
  const g=s.firstChild;return ()=>g.animate([{transform:'none'},{transform:'translateY(-14px)',offset:.35},{transform:'translateY(-14px)',offset:.55},{transform:'translateY(1px)',offset:.85},{transform:'none'}],{duration:1500,easing:'cubic-bezier(.4,0,.2,1)'})},
 ticks:(s,c)=>{const P=['M6 40l6 8 12-20','M30 40l6 8 12-20','M54 40l6 8 12-20'];
  s.innerHTML=['MON','TUE','WED'].map((d,i)=>'<text x="'+(14+i*24)+'" y="22" text-anchor="middle" font-family="Barlow Condensed" font-weight="600" font-size="13" letter-spacing=".5" style="fill:'+c+'" opacity=".7">'+d+'</text>').join('')+P.map((d,i)=>'<path d="'+d+'" fill="none" stroke="'+c+'" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>').join('')+'<path d="M6 66h68" stroke="'+c+'" stroke-width="2" stroke-dasharray="3 4" opacity=".4"/>';
  const T=[...s.querySelectorAll('path')].slice(0,3);return ()=>T.forEach((p,i)=>{const n=p.getTotalLength();p.style.strokeDasharray=n;p.animate([{strokeDashoffset:n},{strokeDashoffset:0}],{duration:380,delay:i*300,easing:'ease-out',fill:'both'})})},
 steps:(s,c)=>{const F=[[16,62,-12],[34,44,8],[50,30,-12],[66,12,8]];s.innerHTML=F.map(([x,y,r])=>'<g transform="translate('+x+' '+y+') rotate('+r+')"><ellipse cx="0" cy="0" rx="5" ry="8" fill="'+c+'"/><circle cx="0" cy="-12" r="3" fill="'+c+'"/></g>').join('');
  const S=[...s.children];return ()=>S.forEach((g,i)=>g.animate([{opacity:0},{opacity:1}],{duration:200,delay:i*260,fill:'both'}))},
 ticket:(s,c)=>{s.innerHTML='<rect x="0" y="4" width="80" height="3" rx="1.5" fill="var(--hair)"/><rect x="36" y="2" width="8" height="7" fill="var(--ink2)"/><g style="transform-origin:40px 6px"><rect x="18" y="8" width="44" height="66" fill="#FBF8F0" stroke="var(--hair)"/><text x="23" y="24" font-family="IBM Plex Sans Condensed" font-weight="700" font-size="10" letter-spacing=".8" style="fill:'+c+'">TACOS</text>'+['25 MIN','8 THINGS','CHAR FIRST'].map((t,i)=>'<text x="23" y="'+(38+i*10)+'" font-family="IBM Plex Sans Condensed" font-size="7.5" letter-spacing=".4" fill="#4A463F">'+t+'</text>').join('')+'</g>';
  const g=s.querySelector('g');return ()=>g.animate([{transform:'rotate(7deg)'},{transform:'rotate(-4deg)'},{transform:'rotate(2deg)'},{transform:'rotate(-.8deg)'},{transform:'none'}],{duration:1500,easing:'ease-out'})},
 bowl:(s,c)=>{s.innerHTML='<path d="M10 46h60a30 22 0 0 1-60 0z" fill="'+c+'"/><rect x="6" y="44" width="68" height="4" rx="2" fill="'+c+'"/>'+[24,40,56].map(x=>'<path d="M'+x+' 38c-5-6 5-10 0-16s5-10 0-16" fill="none" stroke="'+c+'" stroke-width="3" stroke-linecap="round" opacity="0"/>').join('');
  const W=[...s.querySelectorAll('path')].slice(1);return ()=>W.forEach((w,i)=>w.animate([{transform:'translateY(8px) scaleY(.6)',opacity:0},{opacity:.8,offset:.4},{transform:'translateY(-8px) scaleY(1.1)',opacity:0}],{duration:1600,delay:i*260,iterations:2,easing:'ease-out'}))},
 basket:(s,c)=>{s.innerHTML='<g class="it"><circle cx="30" cy="30" r="8" fill="var(--lists)"/><path d="M44 18c10 0 14 8 10 16-8 0-12-6-10-16z" fill="var(--green)"/><rect x="48" y="26" width="18" height="12" rx="3" fill="var(--clay)"/></g><path d="M8 38h64l-8 30H16z" fill="'+c+'"/><path d="M22 38l10-20M58 38L48 18" stroke="'+c+'" stroke-width="3" stroke-linecap="round"/>';
  const it=s.querySelector('.it');return ()=>it.animate([{transform:'translateY(-30px)',opacity:0},{transform:'translateY(3px)',opacity:1,offset:.7},{transform:'none'}],{duration:800,easing:'cubic-bezier(.3,.7,.4,1)'})},
 plates:(s,c)=>{s.innerHTML=[60,50,40,30].map((y,i)=>'<ellipse cx="40" cy="'+y+'" rx="'+(30-i)+'" ry="7" fill="'+c+'" opacity="'+(.45+i*.15)+'" stroke="var(--p-bg)" stroke-width="2"/>').join('')+'<g class="bb">'+[[22,18,4],[54,14,3],[64,26,2.5]].map(([x,y,r])=>'<circle cx="'+x+'" cy="'+y+'" r="'+r+'" fill="none" stroke="'+c+'" stroke-width="1.5"/>').join('')+'</g>';
  const B=[...s.querySelectorAll('.bb circle')];return ()=>B.forEach((b,i)=>b.animate([{transform:'translateY(8px)',opacity:0},{opacity:1,offset:.4},{transform:'translateY(-10px)',opacity:0}],{duration:1200,delay:i*200,iterations:2}))},
 bird:(s,c)=>{s.innerHTML='<path d="M0 50c18 2 40-2 74-12" stroke="#7A5B3E" stroke-width="3" fill="none" stroke-linecap="round"/><path d="M52 42c4-6 10-8 14-6-3 5-8 7-14 6z" fill="#6E9A5B"/>'+
   '<g class="bd" style="transform-origin:30px 44px"><path d="M14 40l-9 3 8 2z" fill="'+c+'"/><ellipse cx="26" cy="38" rx="12" ry="9" fill="'+c+'"/><circle cx="35" cy="30" r="6" fill="'+c+'"/><path d="M40 29l6 2-6 2z" fill="#D89A3C"/><circle cx="36.5" cy="28.5" r="1.3" fill="#fff"/><path d="M22 36c4 4 9 4 12 1" stroke="#fff" stroke-opacity=".5" stroke-width="2" fill="none"/></g>'+
   '<path d="M62 78V58" stroke="#6E9A5B" stroke-width="2.5"/><g class="fl" style="transform-origin:62px 56px">'+[0,72,144,216,288].map(r=>'<ellipse cx="62" cy="49" rx="4" ry="7" fill="#E59AB0" transform="rotate('+r+' 62 56)"/>').join('')+'<circle cx="62" cy="56" r="3.2" fill="#E8B64A"/></g>';
  const bd=s.querySelector('.bd'),fl=s.querySelector('.fl');
  return (far)=>{bd.animate([{transform:far?'translate(-150px,-190px) rotate(-20deg) scale(.6)':'translate(-30px,-26px) rotate(-14deg)',opacity:far?1:0},{transform:'translate(-8px,-14px) rotate(-6deg)',opacity:1,offset:.6},{transform:'translateY(1px)',offset:.78},{transform:'translateY(-4px)',offset:.88},{transform:'none'}],{duration:far?1400:1100,easing:'cubic-bezier(.3,.7,.4,1)',fill:'both'});
   fl.animate([{transform:'scale(.15) rotate(-60deg)'},{transform:'scale(1.1) rotate(4deg)',offset:.7},{transform:'none'}],{duration:900,delay:far?1000:700,easing:'cubic-bezier(.2,.8,.2,1)',fill:'both'})}},
 can:(s,c)=>{s.innerHTML='<g style="transform-origin:34px 46px"><rect x="14" y="34" width="34" height="28" rx="5" fill="'+c+'"/><path d="M46 40l20-12" stroke="'+c+'" stroke-width="5" stroke-linecap="round"/><path d="M20 34c0-10 22-10 22 0" fill="none" stroke="'+c+'" stroke-width="3"/></g>'+[0,1,2].map(i=>'<circle cx="'+(68+i*2)+'" cy="34" r="2.2" fill="var(--steel)" opacity="0"/>').join('')+'<path d="M56 76c0-8 10-8 10-14 0 6 10 6 10 14" fill="#6E9A5B" opacity=".9"/>';
  const g=s.querySelector('g'),D=[...s.querySelectorAll('circle')];return ()=>{g.animate([{transform:'none'},{transform:'rotate(18deg)',offset:.3},{transform:'rotate(18deg)',offset:.75},{transform:'none'}],{duration:1600,easing:'ease-in-out'});
   D.forEach((d,i)=>d.animate([{transform:'none',opacity:0},{opacity:1,offset:.2},{transform:'translate('+(2-i*2)+'px,30px)',opacity:0}],{duration:600,delay:500+i*150,iterations:2,easing:'ease-in'}))}},
 grove:(s,c)=>{s.innerHTML='<path d="M4 72h72" stroke="'+c+'" stroke-width="2" opacity=".4"/>'+[[16,.9,'#6E9A5B'],[34,1,'#E59AB0'],[52,.8,'#E8B64A'],[68,.7,'var(--hair)']].map(([x,k,f],i)=>'<g style="transform-origin:'+x+'px 72px"><path d="M'+x+' 72V'+(72-30*k)+'" stroke="#7A5B3E" stroke-width="2.5"/><circle cx="'+x+'" cy="'+(66-30*k)+'" r="'+(9*k)+'" fill="'+(i<3?f:'none')+'" stroke="'+(i<3?'none':c)+'" stroke-width="2" stroke-dasharray="'+(i<3?'':'3 3')+'"/></g>').join('');
  const T=[...s.querySelectorAll('g')];return ()=>T.forEach((g,i)=>g.animate([{transform:'scaleY(0)'},{transform:'scaleY(1.1)',offset:.7},{transform:'none'}],{duration:700,delay:i*160,easing:'cubic-bezier(.2,.8,.2,1)',fill:'both'}))},
 index:(s,c)=>{s.innerHTML='<path d="M8 66H72" stroke="'+c+'" stroke-width="2" opacity=".4"/><path d="M10 26L24 32L36 30L48 44L60 48L70 60" fill="none" stroke="'+c+'" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round"/><circle cx="70" cy="60" r="4.5" fill="'+c+'"/>';
  const p=s.children[1],d=s.children[2],n=p.getTotalLength();p.style.strokeDasharray=n;
  return ()=>{p.animate([{strokeDashoffset:n},{strokeDashoffset:0}],{duration:1100,easing:'cubic-bezier(.4,0,.2,1)',fill:'both'});d.animate([{opacity:0,transform:'scale(0)'},{opacity:0,transform:'scale(0)',offset:.85},{opacity:1,transform:'scale(1.4)',offset:.93},{opacity:1,transform:'none'}],{duration:1300})}},
 cal:(s,c)=>{s.innerHTML='<rect x="12" y="16" width="56" height="52" rx="6" fill="none" stroke="'+c+'" stroke-width="3"/><path d="M12 30h56M26 10v10M54 10v10" stroke="'+c+'" stroke-width="3" stroke-linecap="round"/><g class="pg" style="transform-origin:40px 30px"><text x="40" y="58" text-anchor="middle" font-family="Outfit" font-weight="300" font-size="24" style="fill:'+c+'">27</text></g>';
  const g=s.querySelector('.pg');return ()=>g.animate([{transform:'perspective(140px) rotateX(-90deg)',opacity:0},{transform:'none',opacity:1}],{duration:600,easing:'cubic-bezier(.2,.8,.2,1)'})},
 coins:(s,c)=>{s.innerHTML=[0,1,2,3].map(i=>'<ellipse cx="40" cy="'+(64-i*10)+'" rx="22" ry="7" fill="'+c+'" opacity="'+(.5+i*.15)+'" stroke="var(--p-bg)" stroke-width="2"/>').join('');
  const E=[...s.children];return ()=>E.forEach((e,i)=>e.animate([{transform:'translateY(-40px)',opacity:0},{transform:'translateY(2px)',opacity:1,offset:.8},{transform:'none'}],{duration:500,delay:i*120,easing:'ease-in',fill:'both'}))}};
const GRULES=[// first match wins: [room or *, words, glyph]
 ['notes',/tess|thought/i,'spark'],['notes',/repair|lamp|bulb/i,'bulb'],['notes',/club|book|chapter/i,'book'],['notes',/left|packing|list/i,'checklist'],
 ['weather',/rain|umbrella/i,'rain'],['weather',/low|tonight|night/i,'moon'],['weather',/dri|sun|clear/i,'sun'],
 ['training',/walk|run|steps/i,'steps'],['training',/of 6|week|done/i,'ticks'],['training',/push|pull|legs|bench|lift/i,'barbell'],
 ['kitchen',/dish/i,'plates'],['kitchen',/rice|leftover|goes out/i,'bowl'],['kitchen',/tacos|dal|cook|dinner/i,'ticket'],['kitchen',/things|limes|get|way/i,'basket'],['kitchen',/.*/,'ticket'],
 ['routines',/journal|thirsty|dry/i,'can'],['routines',/tended|of 7|to go/i,'grove'],['routines',/walk|next|stretch|read|swim/i,'bird'],
 ['money',/drop|monday|rent|friday/i,'cal'],['money',/today|groceries|spent/i,'coins'],['money',/yours|closing|pace|saved|index/i,'index'],
 ['*',/.*/,'words']];
function glyphFor(id,it){if(it.g)return it.g;const t=[it.hdr,it.big,it.mid].join(' ');const r=GRULES.find(([rm,re])=>(rm===id||rm==='*')&&re.test(t));return r[2]}
// what leaves the keystone when an item arrives (one per room)
function ptOf(e){const p=phone.getBoundingClientRect(),r=e.getBoundingClientRect();return {x:(r.left-p.left)/K,y:(r.top-p.top)/K,w:r.width/K,h:r.height/K}}
function dust(el,from,to,o){if(RM)return;let cv=el.querySelector('canvas.fx');if(!cv){cv=h('canvas','fx');cv.width=804;cv.height=1748;cv.style.cssText='position:absolute;left:0;top:0;width:402px;height:874px;z-index:8;pointer-events:none';el.appendChild(cv)}
 const g=cv.getContext('2d'),P=[];for(let i=0;i<(o.n||40);i++){const sx=from.x+Math.random()*from.w,sy=from.y+Math.random()*from.h,tx=to.x+to.w*(.2+Math.random()*.6),ty=to.y+to.h*(.2+Math.random()*.6);P.push({sx,sy,tx,ty,d:Math.random()*(o.spread||400),s:(o.size||2)*(.6+Math.random()*.8),k:Math.random()})}
 const t0=performance.now(),dur=o.dur||800;(function f(now){const t=now-t0;g.setTransform(2,0,0,2,0,0);g.clearRect(0,0,402,874);let live=0;
  P.forEach(p=>{const u=(t-p.d)/dur;if(u<0){live++;if(o.hold){g.fillStyle=o.c0||o.c;g.fillRect(p.sx,p.sy,p.s,p.s)}return}if(u>=1)return;live++;const e=u<.5?2*u*u:1-Math.pow(-2*u+2,2)/2;
   const x=p.sx+(p.tx-p.sx)*e+Math.sin((u+p.k)*6)*(o.wobble||0)*(1-u),y=p.sy+(p.ty-p.sy)*e-(o.arc||0)*Math.sin(Math.PI*e);g.globalAlpha=u>.85?(1-u)/.15:1;
   g.fillStyle=u<.3&&o.c0?o.c0:o.c;if(o.drop){g.beginPath();g.ellipse(x,y,p.s*.6,p.s*1.4,0,0,7);g.fill()}else g.fillRect(x,y,p.s,p.s);g.globalAlpha=1});
  if(live)requestAnimationFrame(f);else g.clearRect(0,0,402,874)})(t0)}
function fly(el,src,dst,o={}){if(RM||!src||!dst)return 0;const a=ptOf(src),b=ptOf(dst);const c=src.cloneNode(true);c.style.cssText+=';position:absolute;margin:0;left:'+a.x+'px;top:'+a.y+'px;width:'+a.w+'px;height:'+a.h+'px;z-index:9;pointer-events:none;transform-origin:0 0;'+(o.css||'');el.appendChild(c);
 const sx=b.w/a.w,sy=o.keep?sx:b.h/a.h,dx=b.x-a.x,dy=b.y-a.y;const k=[{transform:'none',opacity:1},...(o.mid||[]),{transform:'translate('+dx+'px,'+dy+'px) scale('+sx+','+sy+')',opacity:o.endOp??1}];
 c.animate(k,{duration:o.dur||700,easing:o.ease||'cubic-bezier(.5,0,.2,1)',fill:'both'}).onfinish=()=>c.remove();return o.dur||700}
const EMIT={
 notes:(el,it,b)=>{const ws=[...el.querySelectorAll('.wall .wd')];const t=it.big.toUpperCase();const w=ws.find(x=>x.textContent.toUpperCase()===t)||ws.find(x=>t.includes(x.textContent.toUpperCase().split(' ')[0]));
  const bw=b.querySelector('.bw');if(!w||!bw)return 0;bw.style.opacity=0;const d=fly(el,w,bw,{keep:1,dur:760,mid:[{transform:'translateY(-14px) scale(1.06)',offset:.18}],ease:'cubic-bezier(.45,0,.2,1)'});w.animate([{opacity:1},{opacity:.15,offset:.2},{opacity:.15,offset:.8},{opacity:1}],{duration:1400});setTimeout(()=>{bw.style.opacity=''},d-40);return d},
 kitchen:(el,it,b)=>{const map={tacos:/tacos/i,get:/things|way/i,rice:/rice/i,dish:/dish/i};const tk=[...el.querySelectorAll('.tix .tk')];const keys=['tacos','get','rice','dish'];const i=keys.findIndex(k=>map[k].test(it.big+' '+it.mid));const t=tk[i];const gl=b.parentNode.querySelector('svg.lg');if(!t||!gl)return 0;
  const face=t.querySelector('.sheet');return fly(el,face,gl,{dur:900,css:'clip-path:polygon(0 0,100% 0,100% 88%,90% 94%,80% 88%,70% 95%,60% 88%,50% 94%,40% 88%,30% 95%,20% 88%,10% 94%,0 88%)',mid:[{transform:'rotate(-4deg)',offset:.12},{transform:'translate(10px,40px) rotate(9deg)',offset:.45}],endOp:0})},
 training:(el,it,b)=>{const gl=b.parentNode.querySelector('svg.lg');if(!gl)return 0;dust(el,{x:40,y:220,w:320,h:130},ptOf(gl),{n:70,c:css('--training'),c0:'rgba(236,236,230,.95)',size:2.2,dur:900,spread:350,wobble:6,arc:-20});return 500},
 weather:(el,it,b)=>{const gl=b.parentNode.querySelector('svg.lg');if(!gl)return 0;dust(el,{x:40,y:330,w:320,h:30},ptOf(gl),{n:26,c:'rgba(220,235,250,.9)',size:3,dur:700,spread:500,drop:1});return 400},
 routines:(el,it,b,glyph,loop)=>{if(glyph==='bird'){loop(true);return 0}const gl=b.parentNode.querySelector('svg.lg');if(!gl)return 0;dust(el,{x:20,y:230,w:360,h:120},ptOf(gl),{n:24,c:'#E59AB0',size:3.2,dur:1100,spread:500,wobble:10,arc:30});return 500},
 money:(el,it,b)=>{const gl=b.parentNode.querySelector('svg.lg');if(!gl)return 0;dust(el,{x:300,y:290,w:8,h:8},ptOf(gl),{n:8,c:css('--purse'),size:4,dur:800,spread:120,arc:40});return 400}};
// the theme words arrive with, per room
const WORDIN={notes:'drop'};
THEMES.drop=(els)=>words(els,(w,i)=>w.animate([{transform:'translateY(-26px)',filter:'blur(2px)',opacity:0},{transform:'translateY(2px)',opacity:1,offset:.7},{transform:'none',filter:'blur(0)',opacity:1}],{duration:520,delay:180+i*38,easing:'cubic-bezier(.2,.8,.2,1)',fill:'both'}));
function widgetV3(el,R,id){const W=R.w,box=h('div','one lw');box.style.zIndex=6;let wi=0,cur=null,sv=null,loop=null;
 const col=it=>it.c||R.color;
 function card(i){const it=W[i];const b=h('div','blk');
  b.innerHTML='<div class="hdr" style="color:'+col(it)+'">'+it.hdr+'</div><div class="big" style="color:'+col(it)+'">'+(it.num?'<span class="bn"><span class="o">'+it.big+'</span>'+(it.unit?'<span class="u" style="font-size:28px">'+it.unit+'</span>':'')+'</span>':'<span class="bw">'+it.big+'</span>')+'<i class="strike"></i></div><div class="mid">'+it.mid+'</div><div class="sml">'+it.sml+'</div>';
  if(R.big)b.querySelectorAll('.bw').forEach(x=>x.style.cssText=R.big);if(R.bigNum)b.querySelectorAll('.bn').forEach(x=>x.style.cssText=R.bigNum);return b}
 const fit=b=>[...b.children].forEach(fitLine);
 const colorOf=it=>{const v=(it.c||R.color);if(el.classList.contains('onsky'))return 'currentColor';const m=v.match(/var\((--[^)]+)\)/);return m?css(m[1]):v};
 const NS='http://www.w3.org/2000/svg';
 function glyph(it,old){const g=glyphFor(id,it);const s=document.createElementNS(NS,'svg');s.setAttribute('viewBox','0 0 80 80');s.setAttribute('class','lg');s.style.cssText='position:absolute;right:0;top:44px;width:80px;height:80px;overflow:visible';
  const lp=G[g](s,colorOf(it),it);box.appendChild(s);
  // the change is never a cut: the old drawing collapses into a point, the point pulses once, and the new one forms out of it
  if(old){if(RM)old.remove();else{old.animate([{opacity:1,transform:'none',filter:'blur(0)'},{opacity:.9,transform:'scale(.06) rotate(70deg)',filter:'blur(1px)'}],{duration:260,easing:'cubic-bezier(.6,0,.9,.4)',fill:'both'}).onfinish=()=>old.remove();
   const dot=h('div');dot.style.cssText='position:absolute;right:37px;top:81px;width:6px;height:6px;border-radius:3px;background:'+colorOf(it).replace('currentColor','var(--ink)');box.appendChild(dot);
   dot.animate([{transform:'scale(0)'},{transform:'scale(1.6)',offset:.5},{transform:'scale(0)'}],{duration:260,delay:200,fill:'both'}).onfinish=()=>dot.remove();
   s.animate([{opacity:0,transform:'scale(.06) rotate(-70deg)',filter:'blur(1px)'},{opacity:1,transform:'scale(1.08) rotate(4deg)',filter:'blur(0)',offset:.7},{opacity:1,transform:'none'}],{duration:440,delay:330,fill:'both',easing:'cubic-bezier(.2,.8,.2,1)'})}}
  sv=s;loop=lp;return g}
 let gk=glyph(W[0]);cur=card(0);box.appendChild(cur);requestAnimationFrame(()=>fit(cur));document.fonts&&document.fonts.ready.then(()=>fit(cur));
 const enter=b=>{if(RM)return;const d=(EMIT[id]||(()=>0))(el,W[wi],b,gk,loop)||0;(THEMES[WORDIN[id]||R.theme]||THEMES.wind)([...b.children].slice(1).filter(x=>!(d&&x.classList.contains('big')&&id==='notes')));if(!(id==='routines'&&gk==='bird'))setTimeout(()=>loop&&loop(),d)};
 function show(n,ax,sgn){const nb=card(n);box.appendChild(nb);fit(nb);gk=glyph(W[n],sv);if(RM){cur.remove();cur=nb;wi=n;return}
  const m=ax==='x'?360:212;nb.style.transform=ax==='x'?'translateX('+(sgn*m)+'px)':'translateY('+(sgn*m)+'px)';
  const old=cur;requestAnimationFrame(()=>requestAnimationFrame(()=>{nb.style.transition=old.style.transition='transform .38s cubic-bezier(.3,.9,.3,1)';nb.style.transform='none';old.style.transform=ax==='x'?'translateX('+(-sgn*m)+'px)':'translateY('+(-sgn*m)+'px)'}));
  setTimeout(()=>old.remove(),400);cur=nb;wi=n;setTimeout(()=>enter(nb),id==='notes'?380:0)}
 let ox=null,oy,dx,dy,oa,hold=null,struck=false;
 box.addEventListener('pointerdown',e=>{ox=e.clientX;oy=e.clientY;dx=dy=0;oa=null;struck=false;box.setPointerCapture(e.pointerId);
  const [,ly]=localXY(e,box);if(ly>40&&ly<110){const st=$('.strike',cur);hold=R.noStrike?null:setTimeout(()=>{st.style.transition='width .6s linear';st.style.width='100%';hold=setTimeout(()=>{struck=true},600)},180)}});
 box.addEventListener('pointermove',e=>{if(ox==null)return;dx=(e.clientX-ox)/K;dy=(e.clientY-oy)/K;oa=lockAxis(dx,dy,oa);if(oa){clearTimeout(hold);const st=$('.strike',cur);st.style.transition='width .2s';st.style.width='0';
  cur.style.transition='none';cur.style.transform=oa==='x'?'translateX('+dx*.9+'px)':'translateY('+dy*.72+'px)'}});
 box.addEventListener('pointerup',()=>{if(ox==null)return;ox=null;clearTimeout(hold);cur.style.transition='transform .3s';cur.style.transform='none';
  if(struck&&!R.noStrike){const it=W[wi],k=wi;W.splice(k,1);if(!W.length){W.splice(k,0,it);return}receipt(el,it.hdr+', '+it.big+', done.',()=>{W.splice(k,0,it);show(k,'y',-1)});show(k%W.length,'y',1);return}
  const st=$('.strike',cur);st.style.transition='width .2s';st.style.width='0';
  if(oa==='x'&&Math.abs(dx)>50)show((wi+(dx<0?1:-1)+W.length)%W.length,'x',dx<0?1:-1);
  else if(oa==='y'&&Math.abs(dy)>44)show((wi+(dy<0?1:-1)+W.length)%W.length,'y',dy<0?1:-1);
  else if(!oa&&W[wi].go)go(...W[wi].go)});
 const iv=RM?0:setInterval(()=>{if(ox==null&&document.contains(box))loop&&loop()},7000);
 return {box,start:()=>enter(cur),stop:()=>clearInterval(iv)}}

/* ---------- the Foot: the action word. A verb in the room's colour, its object small under it (no "Start Push A").
   Tap does it. Drag across past 56 pt: the verb's letters stream out and the next option's stream in, the way the
   Switcher does, with one light tick; it rests on the new option. Hold 500 ms: the verb fills with weight from left
   to right, then does it (for the one thing that should not be a slip, like starting a workout). Undo 10 s after. */
function actionX(el,R){const A=R.acts,f=h('div','act');el.appendChild(f);let i=0;
 const vb=h('div','av'),ob=h('div','ao');f.appendChild(vb);f.appendChild(ob);f.style.color=R.color;
 const set=(n,dir)=>{const a=A[n];const old=[...vb.children];vb.innerHTML='';[...a.v].forEach(ch=>{const s=h('span','ch');s.textContent=ch;vb.appendChild(s)});ob.textContent=a.o;fitLine(ob);
  if(dir&&!RM){[...vb.children].forEach((c,j)=>c.animate([{transform:'translateX('+(dir*40)+'px) skewX('+(-dir*18)+'deg)',opacity:0,filter:'blur(2px)'},{transform:'none',opacity:1,filter:'blur(0)'}],{duration:480,delay:j*22,easing:'cubic-bezier(.2,.8,.2,1)',fill:'both'}));ob.animate([{opacity:0,transform:'translateY(4px)'},{opacity:1,transform:'none'}],{duration:300,delay:120,fill:'both'})}};
 set(0);let x0=null,y0,dx,ax,hold=null,did=false;
 f.onpointerdown=e=>{x0=e.clientX;y0=e.clientY;dx=0;ax=null;did=false;f.setPointerCapture(e.pointerId);e.stopPropagation();
  if(A[i].hold&&!RM){vb.style.setProperty('--fill','0%');hold=vb.animate([{backgroundSize:'0% 100%'},{backgroundSize:'100% 100%'}],{duration:500,fill:'forwards'});vb.classList.add('filling');hold.onfinish=()=>{did=true;vb.classList.remove('filling');hold=null;A[i].f(el)}}};
 f.onpointermove=e=>{if(x0==null)return;dx=(e.clientX-x0)/K;ax=lockAxis(dx,(e.clientY-y0)/K,ax);if(ax==='x'){if(hold){hold.cancel();hold=null;vb.classList.remove('filling')}vb.style.transform='translateX('+Math.max(-60,Math.min(60,dx*.6))+'px)';vb.style.letterSpacing=Math.min(.12,Math.abs(dx)/600)+'em'}};
 f.onpointerup=()=>{if(x0==null)return;x0=null;vb.style.transform='';vb.style.letterSpacing='';if(hold){hold.cancel();hold=null;vb.classList.remove('filling');if(!ax){receipt(el,'Hold to '+A[i].v.toLowerCase()+'.');return}}
  if(did)return;if(ax==='x'&&Math.abs(dx)>56&&A.length>1){const d=dx<0?1:-1;i=(i+d+A.length)%A.length;set(i,d);return}if(!ax&&!A[i].hold)A[i].f(el)};
 return f}

// a room landing
function landingV3(el,R){const stops=[];const id=el.dataset.id;
 const top=h('div');top.style.cssText='position:absolute;inset:0 0 auto 0;height:100px;z-index:6;pointer-events:none';el.appendChild(top);
 const t=h('div','ttl',R.name);t.style.color=R.color;top.appendChild(t);
 if(stack.length>1){const p=SCREENS[stack[stack.length-2].id];const nb=h('button','lnav',SHIP[p.title]||p.title);nb.style.pointerEvents='auto';nb.onclick=()=>back();top.appendChild(nb)}
 const band=h('div','lband');el.appendChild(band);
 const swn=h('div','swn');band.appendChild(swn);
 if(R.sw){const sx=h('div','swx');band.appendChild(sx);stops.push(switcherX(sx,R.sw,(v)=>{swn.innerHTML=v.lines.map(l=>'<div class="ln">'+l+'</div>').join('');swn.querySelectorAll('.ln').forEach(fitLine);if(swn._on){swn.classList.remove('rise');void swn.offsetWidth;if(!RM)swn.classList.add('rise')}swn._on=1}))}
 const key=h('div','lkey');el.appendChild(key);stops.push(R.keystone(key,el));
 const cap=h('div','lcap',R.caption||'');el.appendChild(cap);
 const WG=widgetV3(el,R,id),mid=WG.box;el.appendChild(mid);stops.push(WG.stop);
 const dh=h('div','dial');dh.style.cssText+='left:24px;top:640px;width:160px;z-index:6';el.appendChild(dh);
 const sum=h('div','lsum');el.appendChild(sum);
 dial(dh,R.doors.map(d=>({...d,color:d.color||R.color})),{start:0,slot:40,blur:1.6,label:(d,f)=>'<span style="font-size:'+(f?26:20)+'px;font-weight:'+(f?700:600)+';letter-spacing:-.01em">'+d.k+'</span>'+(d.n!=null?'<i>'+d.n+'</i>':''),
  open:d=>d.go?go(...d.go):receipt(el,d.k+' opens here. Inside pages are the next round.'),
  change:d=>{sum.innerHTML=d.sum();fitAll(sum);if(!sum._on){sum._on=1;return}sum.classList.remove('rise');void sum.offsetWidth;if(!RM)sum.classList.add('rise')}});
 const f=actionX(el,R);
 fitLine(cap);document.fonts&&document.fonts.ready.then(()=>{fitAll(el)});
 opening(el._flip?[top,band,cap,mid,dh,sum,f]:[top,band,key,cap,mid,dh,sum,f],el._flip?160:0);
 setTimeout(WG.start,el._flip?420:260);
 return ()=>stops.forEach(s=>s&&s())}
const sum=(lb,lines)=>'<div class="lb">'+lb+'</div>'+lines.map(l=>'<div class="ln">'+l+'</div>').join('');
const o=n=>'<span class="o">'+n+'</span>';
const un=u=>'<span class="u" style="font-size:.6em">'+u+'</span>';

/* ---------- Log (Notes + Lists) ---------- */
SCREENS.notes={title:'Notes',accent:'notes',tess:'You wrote three today. Trip packing is the one you keep opening.',render(el){const timers=[];
 const cut=n=>n.t.replace('Voice: ','');
 return landingV3(el,{name:'Log',color:'var(--notes)',theme:'type',big:"font-weight:900;font-size:36px;letter-spacing:-.02em;text-transform:uppercase",
  sw:{x:[{k:'Newest',lines:['Trip packing, at noon','Run plan, 9:12 am']},{k:'Due',c:'var(--wine)',lines:['Trip packing, Friday','Lamp repair, by 6 today']},{k:'Pinned',c:'var(--gold)',lines:['Trip packing','Taxes, Oct 15']},{k:'From Tess',c:'var(--tessblue)',lines:['Run plan, this morning','Sleep, Tuesday']}],
      y:[{k:'Today',lines:['Three new','One from Tess']},{k:'This week',lines:['Eleven notes','Two voice memos']},{k:'Earlier',lines:['Seven notes','Three in Home']}]},
  w:[{hdr:'Newest',big:'Trip packing',c:'var(--lists)',mid:'8 left, due Friday',sml:'You opened it four times today',go:['list']},
   {hdr:'From Tess',big:'Run plan',c:'var(--tessblue)',mid:'Tess kept a thought for you',sml:'This morning, 9:12',go:['note',{id:'n2'}]},
   {hdr:'Due today',big:'Lamp repair',mid:'The store closes at 6',sml:'Bring the old bulb',go:['note',{id:'n8'}]},
   {hdr:'Thursday',big:'Book club',mid:'At Sam’s, 7 pm',sml:'Chapter nine to the end',go:['note',{id:'n4'}]}],
  keystone:k=>{const wh=h('div','wall');wh.style.top='196px';wh.style.height='182px';k.appendChild(wh);
   const ws=NOTES.filter(n=>!n.priv&&!n.d.includes('archive')).sort((a,b)=>(b.pin||0)-(a.pin||0)||ORDW[a.w]-ORDW[b.w]).slice(0,11).map(n=>({t:cut(n),id:n.id}));
   const W1=wall(wh,ws,{h:182,seed:3,tap:w=>go('note',{id:w.id})});moments(W1.els,timers);return ()=>timers.forEach(clearInterval)},
  caption:'Tap a word to open its note.',
  doors:NDOORS.map(d=>({k:d.n,n:NOTES.filter(x=>inDoor(d.k,x)).length,color:'var(--'+d.c+')',go:['door',{k:d.k}],
   sum:()=>{const L=NOTES.filter(x=>inDoor(d.k,x)).sort((a,b)=>ORDW[a.w]-ORDW[b.w]);return d.k==='private'?sum('Locked',[L.length+' private notes']):sum('Newest '+(L[0]?L[0].w.toLowerCase():''),L.slice(0,3).map(cut))}})),
  acts:[{v:'Write',o:'a new note',f:()=>go('note',{id:'new'})},{v:'Speak',o:'a voice note, Tess types it',f:e=>receipt(e,'Listening. Tap to stop.')},{v:'List',o:'a note you can check off',f:()=>go('list')}]})}};

/* ---------- Lookout (Weather) ---------- */
SCREENS.weather={title:'Weather',accent:'weather',tess:'Rain from 7 until about midnight. Take the jacket to the gym.',render(el){el.classList.add('onsky');let iv=0;
 const r=landingV3(el,{name:'Lookout',color:'inherit',theme:'wind',
  sw:{x:[{k:'Now',lines:['64°, cloudy','Rain in 1 hr 48 min']},{k:'Tonight',lines:['Rain 7 to midnight','Low 54°']},{k:'Tomorrow',lines:['Clearing by noon','High 66°']},{k:'This week',lines:['Driest Thursday, 68°','Rain again Saturday']}]},
  noStrike:1,w:[{hdr:'Rain from',big:'7',unit:'pm',num:1,mid:'Until about midnight',sml:'Take the umbrella to the gym'},
   {hdr:'Tonight',big:'54',unit:'°',num:1,mid:'The low, clear by 1 AM',sml:'Bring the washing in before 7'},
   {hdr:'Thursday',big:'68',unit:'°',num:1,mid:'The driest day this week',sml:'Water the balcony plants then'}],
  keystone:(k)=>{const s=weatherCenter(k,W_HOUR,wcond,glassInner(wcond));
   iv=setInterval(()=>{const c=k.style.color;if(!c)return;el.style.color=c;el.style.setProperty('--ink',c);el.style.setProperty('--ink2','color-mix(in srgb,'+c+' 78%,transparent)')},120);return s},
  caption:'Rain gathers on the glass from 7.',
  doors:[{k:'Hours',go:['weatherhour',{h:'7 PM',t:60,w:'Rain'}],sum:()=>sum('Next three hours',['7 PM '+o('60°')+' rain','8 PM '+o('58°')+' rain','9 PM '+o('57°')+' rain'])},
   {k:'Tonight',sum:()=>sum('From 7',['Rain until midnight','Low '+o('54°'),'Clear by 1 AM'])},
   {k:'This week',sum:()=>sum('Driest day',['Thursday, '+o('68°'),'Rain again Saturday','Cooler next week'])},
   {k:'Air',sum:()=>sum('Now',['Wind '+o('9')+un('mph')+', gusting','Humidity '+o('58')+un('%'),'Air is clean'])},
   {k:'Sky',sum:()=>sum('Today',['Sunset '+o('6:08')+un('pm'),'Moon waxing, half','Sun '+o('12°')+' high'])}],
  acts:[{v:'Alert',o:'30 min before rain',f:e=>receipt(e,'You’ll hear 30 minutes before rain.')},{v:'Hours',o:'the next twelve',f:()=>go('weatherhour',{h:'7 PM',t:60,w:'Rain'})},{v:'Walk',o:'find a dry hour',f:e=>receipt(e,'Dry from 1 to 4 tomorrow.')}]});
 return ()=>{clearInterval(iv);r&&r()}}};

/* ---------- Deck (Training) ---------- */
SCREENS.training={title:'Training',accent:'training',tess:'Bench opens at 185 tonight. Last time, three fives.',render(el){
 return landingV3(el,{name:'Deck',color:'var(--training)',theme:'chalk',big:"font-family:'Barlow Condensed',sans-serif;font-weight:600;font-size:50px;letter-spacing:.01em;text-transform:uppercase",
  sw:{x:[{k:'Today',lines:['Push A at 6:30 pm','4 lifts, about 45 min']},{k:'This week',lines:['Three of six done','Pull A tomorrow']},{k:'This month',lines:['14 workouts','Bench up 10 lb']}],
      y:[{k:'Push A',c:'var(--clay)',lines:['Bench first, 185 lb','Then press, row, triceps']},{k:'Pull A',c:'var(--teal)',lines:['Tomorrow morning','Deadlift first, 315 lb']},{k:'Legs',lines:['Thursday','Squat 275 lb']}]},
  w:[{hdr:'Tonight',big:'6:30',unit:'pm',num:1,mid:'Push A, bench first',sml:'Bench best 205 lb, three weeks ago',go:['workout']},
   {hdr:'This week',big:'3',unit:' of 6',num:1,mid:'Workouts done',sml:'Pull A tomorrow morning'},
   {hdr:'Yesterday',big:'Walk',c:'var(--teal)',mid:'32 min, not logged yet',sml:'Hold to log it'}],
  keystone:k=>boardCenter(k,ck=>{chalk(ck,'Push A at 6:30, bench first',26,244,28,.95,C);chalk(ck,'about 45 min, 4 lifts, start on the rower',26,266,16,.7,C2);ticks(ck,290);chalk(ck,'5 weeks on plan',230,302,18,.8,C2);chalk(ck,'+10 on bench since Oct 1',230,324,17,.8,C2);let x=26;[['Bench',205],['Squat',275],['Deadlift',315],['Row',130]].forEach(([l,v])=>{x+=chalk(ck,l+' '+v,x,356,19,.65,C2)+16})}),
  caption:'Drag to write. Swipe fast left to wipe.',
  doors:[{k:'Today',go:['workout'],sum:()=>sum('Push A, 4 lifts',['Bench '+o('185')+un('lb'),'Overhead press '+o('95'),'Cable row '+o('110')])},
   {k:'This week',sum:()=>sum('Monday to Saturday',['Push, Pull, Legs done','Push A tonight','Pull A tomorrow'])},
   {k:'Library',n:28,sum:()=>sum('28 workouts in 6 kinds',['<span style="color:var(--gold)">New: hill sprints</span>','Push, Pull, Legs','Runs and rows'])},
   {k:'Bests',sum:()=>sum('Since Oct 1',['Bench '+o('205')+un('lb'),'Squat '+o('275'),'Deadlift '+o('315')])},
   {k:'Plan',sum:()=>sum('Week 5 of the block',['Bench '+o('+10')+' since Oct 1','Deload next week','Then the new block'])}],
  acts:[{v:'Start',o:'Push A, about 45 min',hold:1,f:()=>go('workout')},{v:'Log',o:'yesterday’s walk, 32 min',f:e=>receipt(e,'Walk, 32 min, logged.')},{v:'Rest',o:'a 2 min timer',f:e=>receipt(e,'Rest, 2:00.')}]})}};

/* ---------- Galley (Kitchen) ---------- */
SCREENS.kitchen={title:'Kitchen',accent:'kitchen',tess:'Tacos tonight works. You need tortillas, cilantro and limes.',render(el){
 return landingV3(el,{name:'Galley',color:'var(--kitchenText)',theme:'steam',big:"font-family:'IBM Plex Sans Condensed',sans-serif;font-weight:700;font-size:40px;letter-spacing:.04em;text-transform:uppercase",
  sw:{x:[{k:'Tonight',lines:['Tacos, 25 min','You have all 8 things']},{k:'Tomorrow',lines:['Dal, 40 min','Soak the lentils tonight']},{k:'This week',lines:['5 dinners planned','Shakshuka on Friday']}]},
  w:[{hdr:'Tonight',big:'Tacos',mid:'25 min, you have all 8 things',sml:'Char the tortillas first',go:['tonight']},
   {hdr:'Goes out today',big:'Rice',c:'var(--wine)',mid:'Cooked Thursday',sml:'Eat it with the tacos',go:['leftovers']},
   {hdr:'On the way home',big:'3',unit:' things',num:1,mid:'Limes, cilantro, tortillas',sml:'The store is open till 9',go:['groceries']},
   {hdr:'Since lunch',big:'7',unit:' dishes',num:1,mid:'Waiting in the sink',sml:'About 10 minutes'}],
  keystone:k=>{passCenter(k,[tacosT(false),getT(false),riceT(),dishT()],openT);return null},
  caption:'Swipe a ticket up for its next page.',
  doors:[{k:'Tonight',go:['tonight'],sum:()=>sum('Tacos, 25 min',['You have all 8 things','Char the tortillas first','Chicken, 5 minutes'])},
   {k:'Pantry',n:31,go:['pantry'],sum:()=>sum('31 things',PLACES.map(([n,c,s])=>n+', '+s).slice(0,3))},
   {k:'Recipes',go:['recipes'],sum:()=>sum('4 you can make',['Tacos, 25 min','Dal, 40 min','Shakshuka, 30 min'])},
   {k:'Groceries',n:GET.length,go:['groceries'],sum:()=>sum(GET.length+' to get',GET.slice(0,3))},
   {k:'Leftovers',go:['leftovers'],sum:()=>sum('Eat first',['<span style="color:var(--wine)">Rice, today</span>','Dal, by Friday'])}],
  acts:[{v:'Cook',o:'Tacos, 25 min',f:()=>go('cook')},{v:'Get',o:'3 things on the way',f:()=>go('groceries')},{v:'Wash',o:'7 dishes',f:e=>receipt(e,'Dishes, done.')}]})}};

/* ---------- Watch (Routines) ---------- */
SCREENS.routines={title:'Routines',accent:'routines',tess:'Journal has been dry since Saturday. One line tonight brings it back.',render(el){
 const wine=t=>'<span style="color:var(--wine)">'+t+'</span>',grn=t=>'<span style="color:var(--green)">'+t+'</span>',slt=t=>'<span style="color:var(--slate)">'+t+'</span>';
 return landingV3(el,{name:'Watch',color:'var(--routines)',theme:'grow',
  sw:{x:[{k:'Evening',lines:['Walk around 6','Stretch at 8 pm']},{k:'Night',lines:['Read at 9','Journal, one line']},{k:'Morning',lines:['Water, done','Lunch prep at 11']}]},
  w:[{hdr:'Next',big:'Walk',mid:'Around 6, 30 minutes',sml:'Tended five days in a row'},
   {hdr:'Thirsty',big:'Journal',c:'var(--wine)',mid:'Dry since Saturday',sml:'One line tonight brings it back'},
   {hdr:'Today',big:'3',unit:' of 7',num:1,mid:'Tended, four to go',sml:'Stretch at 8 pm, nine minutes'}],
  keystone:k=>{const c=h('div','lclip');c.style.cssText+='left:0;width:402px';c.innerHTML='<iframe title="Woodland" scrolling="no" src="watch.html?embed=1&look='+(phone.dataset.look==='black'?'black':'paper')+'"></iframe>';c.firstChild.style.left='0';k.appendChild(c);return null},
  caption:'Hold a tree to water it. Tap to see it.',
  doors:[{k:'Today',go:['sheaf',{mode:1,open:'To tend'}],sum:()=>sum('Three tended, four to go',['Walk around 6','Stretch at 8 pm',wine('Journal is thirsty')])},
   {k:'Body',go:['sheaf',{mode:0,open:'Body'}],sum:()=>sum('Walk, Stretch, Swim, Badminton',['Walk is next',grn('Stretch, tended today'),'Swim on Thursday'])},
   {k:'Mind',go:['sheaf',{mode:0,open:'Mind'}],sum:()=>sum('Journal, Read',[wine('Journal, dry since Saturday'),grn('Read, in fruit'),'Read tonight at 9'])},
   {k:'Home',go:['sheaf',{mode:0,open:'Home'}],sum:()=>sum('Water, Lunch, Tidy, Backup',[grn('Water, done today'),'Tidy tonight',slt('Backup ran at 4 am')])},
   {k:'Weekly',sum:()=>sum('Swim, Badminton, Call family',['Badminton Wednesday','Swim Thursday','Call family Sunday'])}],
  acts:[{v:'Plant',o:'a new routine',f:e=>receipt(e,'Tap open ground in the woodland to plant.')},{v:'Water',o:'Journal, one line',f:e=>receipt(e,'Journal, watered.')},{v:'Pause',o:'today, nothing is lost',f:e=>receipt(e,'Paused for today.')}]})}};

/* ---------- Purse (Money) ---------- */
SCREENS.money={title:'Money',accent:'purse',tess:'2,125 still yours. Closing at 179 after rent.',render(el){
 return landingV3(el,{name:'Purse',color:'var(--purse)',theme:'roll',
  sw:{x:[{k:'October',lines:['Still yours 2,125','Closing at 179']},{k:'This year',lines:['Saved 3,400','Spending calmer than 2025']},{k:'Since May',lines:['Car loan down 2,400','Japan on plan']}]},
  noStrike:1,w:[{hdr:'Still yours',big:'2,125',num:1,mid:'Closing at about 179',sml:'Pace 74, calm'},
   {hdr:'Next drop',big:'45',num:1,c:'var(--clay)',mid:'Phone, on Monday',sml:'Then rent, 1,450 on Friday'},
   {hdr:'Today',big:'86',num:1,mid:'Groceries',sml:'Food 412 so far this month'}],
  keystone:k=>{const c=h('div','lclip');c.style.cssText+='left:24px;width:354px';c.innerHTML='<iframe title="Indices" scrolling="no" src="purse.html?embed=1&look='+(phone.dataset.look==='black'?'black':'paper')+'"></iframe>';c.firstChild.style.left='-24px';k.appendChild(c);return null},
  caption:'Across for a category, up and down for an index.',
  doors:[{k:'This month',sum:()=>sum('You are the stock',['Still yours '+o('2,125'),'Closes at '+o('179'),'Pace '+o('74')+', calm'])},
   {k:'Kinds',sum:()=>sum('October so far',['<span style="color:var(--kitchenText)">Food '+o('412')+'</span>','<span style="color:var(--clay)">Home '+o('1,450')+'</span>','<span style="color:var(--slate)">Going out '+o('96')+'</span>'])},
   {k:'Saving',sum:()=>sum('On plan',['<span style="color:var(--gold)">Japan '+o('3,400')+'</span>','Rainy day '+o('2,000'),'Next in '+o('6')+' days'])},
   {k:'Investing',sum:()=>sum('Portfolio',['Index '+o('102.4'),'Above cost since Oct 3','Quiet this week'])},
   {k:'Debts',sum:()=>sum('Car loan',['Left '+o('6,200'),'Paid off by May 2028','Ahead of schedule'])},
   {k:'Mine',sum:()=>sum('Your own indices',['INDIA, 12 months','DEBTS, 4 children','Make one with Tess'])}],
  acts:[{v:'Log',o:'what you spent',f:e=>receipt(e,'Say what you spent. Tess files it.')},{v:'Look',o:'this month’s pace',f:e=>receipt(e,'Pace 74, calm.')},{v:'Plan',o:'next month',f:e=>receipt(e,'November opens here.')}]})}};
{const ph=document.getElementById('phone');const setP=()=>ph.style.setProperty('--purse',ph.dataset.look==='black'?'#8DBFA7':'#3F7A62');setP();new MutationObserver(setP).observe(ph,{attributes:true,attributeFilter:['data-look']})}

