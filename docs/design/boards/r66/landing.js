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

/* ---------- the middle band: Bridge's widget, carried into every room (283 v2, his 2:48 PM note) ----------
   Same box as Bridge's one thing (top 400, 212 tall): a small header, a big line (a word or a number), a middle line,
   a small line, and a drawing on the right. It swipes the way Bridge's does: across and up or down for the room's next
   thing, hold the big line to strike it (Done, Undo 10 s), tap to open. Each room brings its words in its own way and its
   drawing moves its own way, once on arrival and then quietly every few seconds. */
const GLYPH={// 80 x 80, the room's colour; each returns a loop function
 notes:(s,c)=>{// a pinch of the word wall: three words in its heavy type, re-set one after another
  const W=[['TACOS','var(--kitchen)',21,24],['BENCH','var(--training)',17,42],['TRIP','var(--lists)',23,63]];
  s.innerHTML=W.map(([t,f,z,y])=>'<text x="80" y="'+y+'" text-anchor="end" font-family="Figtree" font-weight="900" font-size="'+z+'" letter-spacing="-1" style="fill:'+f+'">'+t+'</text>').join('');
  const T=[...s.children];return ()=>T.forEach((t,i)=>t.animate([{transform:'translateY(6px)',opacity:0,clipPath:'inset(0 0 100% 0)'},{transform:'none',opacity:1,clipPath:'inset(0 0 0 0)'}],{duration:360,delay:i*140,easing:'cubic-bezier(.2,.8,.2,1)',fill:'both'}))},
 weather:(s,c)=>{s.innerHTML='<path d="M20 44a12 12 0 0 1 6-22 16 16 0 0 1 30 2 10 10 0 0 1 4 20z" fill="'+c+'" opacity=".55"/>'+[24,36,48,60].map((x,i)=>'<line x1="'+x+'" y1="52" x2="'+(x-4)+'" y2="62" stroke="'+c+'" stroke-width="3" stroke-linecap="round" opacity="0"/>').join('');
  const cl=s.firstChild,D=[...s.querySelectorAll('line')];
  return ()=>{cl.animate([{transform:'translateX(-6px)'},{transform:'translateX(3px)'},{transform:'none'}],{duration:1800,easing:'ease-in-out'});
   D.forEach((d,i)=>d.animate([{transform:'translateY(-4px)',opacity:0},{opacity:1,offset:.2},{transform:'translateY(14px)',opacity:0}],{duration:700,delay:i*170+(i%2)*90,iterations:3,easing:'ease-in'}))}},
 training:(s,c)=>{// the board's ticks, in chalk: this week's sessions, written one stroke at a time
  const P=['M8 46l6 8 12-20','M30 46l6 8 12-20','M52 46l6 8 12-20'];
  s.innerHTML='<text x="2" y="24" font-family="Caveat" font-weight="600" font-size="17" style="fill:'+c+'" opacity=".75">M T W</text>'+P.map((d,i)=>'<path d="'+d+'" fill="none" stroke="'+c+'" stroke-width="'+(i<2?4:3)+'" stroke-linecap="round" stroke-linejoin="round" opacity="'+(i<2?.9:.35)+'" stroke-dasharray="2.2 .8 6 .6 40"/>').join('')+'<text x="2" y="76" font-family="Caveat" font-weight="600" font-size="16" style="fill:'+c+'" opacity=".6">3 of 6</text>';
  const T=[...s.querySelectorAll('path')];T.forEach(p=>{const n=p.getTotalLength();p.dataset.n=n});
  return ()=>T.forEach((p,i)=>{const n=+p.dataset.n;p.style.strokeDasharray=n;p.animate([{strokeDashoffset:n},{strokeDashoffset:0}],{duration:380,delay:i*300,easing:'ease-out',fill:'both'})})},
 kitchen:(s,c)=>{// one ticket on the rail, swinging a little as it is hung
  s.innerHTML='<rect x="0" y="4" width="80" height="3" rx="1.5" fill="var(--hair)"/><rect x="36" y="2" width="8" height="7" fill="var(--ink2)"/><g style="transform-origin:40px 6px"><rect x="18" y="8" width="44" height="66" fill="var(--paper2,#FBF7EC)" stroke="var(--hair)"/><text x="23" y="26" font-family="Caveat" font-weight="600" font-size="15" style="fill:'+c+'">Tacos</text>'+['25 min','8 things','char first'].map((t,i)=>'<text x="23" y="'+(42+i*11)+'" font-family="Caveat" font-size="11" style="fill:var(--ink2)">'+t+'</text>').join('')+'</g>';
  const g=s.querySelector('g');return ()=>g.animate([{transform:'rotate(7deg)'},{transform:'rotate(-4deg)'},{transform:'rotate(2deg)'},{transform:'rotate(-.8deg)'},{transform:'none'}],{duration:1500,easing:'ease-out'})},
 routines:(s,c)=>{// from the woodland: a small bird hops onto the branch, and the flower under it opens
  s.innerHTML='<path d="M0 50c18 2 40-2 74-12" stroke="#7A5B3E" stroke-width="3" fill="none" stroke-linecap="round"/><path d="M52 42c4-6 10-8 14-6-3 5-8 7-14 6z" fill="#6E9A5B"/>'+
   '<g class="bd" style="transform-origin:30px 44px"><path d="M14 40l-9 3 8 2z" fill="'+c+'"/><ellipse cx="26" cy="38" rx="12" ry="9" fill="'+c+'"/><circle cx="35" cy="30" r="6" fill="'+c+'"/><path d="M40 29l6 2-6 2z" fill="#D89A3C"/><circle cx="36.5" cy="28.5" r="1.3" fill="#fff"/><path d="M22 36c4 4 9 4 12 1" stroke="#fff" stroke-opacity=".5" stroke-width="2" fill="none"/></g>'+
   '<path d="M62 78V58" stroke="#6E9A5B" stroke-width="2.5"/><g class="fl" style="transform-origin:62px 56px">'+[0,72,144,216,288].map(r=>'<ellipse cx="62" cy="49" rx="4" ry="7" fill="#E59AB0" transform="rotate('+r+' 62 56)"/>').join('')+'<circle cx="62" cy="56" r="3.2" fill="#E8B64A"/></g>';
  const bd=s.querySelector('.bd'),fl=s.querySelector('.fl');
  return ()=>{bd.animate([{transform:'translate(-30px,-26px) rotate(-14deg)',opacity:0},{transform:'translate(-8px,-14px) rotate(-6deg)',opacity:1,offset:.45},{transform:'translateY(1px)',offset:.7},{transform:'translateY(-4px)',offset:.82},{transform:'none'}],{duration:1100,easing:'cubic-bezier(.3,.7,.4,1)',fill:'both'});
   fl.animate([{transform:'scale(.15) rotate(-60deg)'},{transform:'scale(1.1) rotate(4deg)',offset:.7},{transform:'none'}],{duration:900,delay:700,easing:'cubic-bezier(.2,.8,.2,1)',fill:'both'})}},
 money:(s,c)=>{s.innerHTML='<path d="M8 66H72" stroke="'+c+'" stroke-width="2" opacity=".4"/><path d="M10 26L24 32L36 30L48 44L60 48L70 60" fill="none" stroke="'+c+'" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round"/><circle cx="70" cy="60" r="4.5" fill="'+c+'"/>';
  const p=s.children[1],d=s.children[2],n=p.getTotalLength();p.style.strokeDasharray=n;
  return ()=>{p.animate([{strokeDashoffset:n},{strokeDashoffset:0}],{duration:1100,easing:'cubic-bezier(.4,0,.2,1)',fill:'both'});d.animate([{opacity:0,transform:'scale(0)'},{opacity:0,transform:'scale(0)',offset:.85},{opacity:1,transform:'scale(1.4)',offset:.93},{opacity:1,transform:'none'}],{duration:1300,transformOrigin:'70px 60px'})}}};
function widgetV3(el,R,id){const W=R.w,box=h('div','one lw');box.style.zIndex=6;let wi=0,cur=null;
 const col=it=>it.c||R.color;
 function card(i){const it=W[i];const b=h('div','blk');
  b.innerHTML='<div class="hdr" style="color:'+col(it)+'">'+it.hdr+'</div><div class="big" style="color:'+col(it)+'">'+(it.num?'<span class="bn"><span class="o">'+it.big+'</span>'+(it.unit?'<span class="u" style="font-size:28px">'+it.unit+'</span>':'')+'</span>':'<span class="bw">'+it.big+'</span>')+'<i class="strike"></i></div><div class="mid">'+it.mid+'</div><div class="sml">'+it.sml+'</div>';
  if(R.big)b.querySelectorAll('.bw').forEach(x=>x.style.cssText=R.big);return b}
 const fit=b=>[...b.children].forEach(fitLine);
 const NS='http://www.w3.org/2000/svg',sv=document.createElementNS(NS,'svg');sv.setAttribute('viewBox','0 0 80 80');sv.setAttribute('class','lg');sv.style.cssText='position:absolute;right:0;top:44px;width:80px;height:80px;overflow:visible';
 const c=R.color==='inherit'?css('--ink')||'#fff':css(R.color.replace(/var\((--[^)]+)\)/,'$1'))||R.color;const loop=(GLYPH[id]||GLYPH.notes)(sv,el.classList.contains('onsky')?'currentColor':c);
 box.appendChild(sv);cur=card(0);box.appendChild(cur);requestAnimationFrame(()=>fit(cur));document.fonts&&document.fonts.ready.then(()=>fit(cur));
 const enter=b=>{if(!RM)(THEMES[R.theme]||THEMES.wind)([...b.children].slice(1))};
 function show(n,ax,sgn){const nb=card(n);box.appendChild(nb);fit(nb);if(RM){cur.remove();cur=nb;wi=n;return}
  const m=ax==='x'?360:212;nb.style.transform=ax==='x'?'translateX('+(sgn*m)+'px)':'translateY('+(sgn*m)+'px)';
  const old=cur;requestAnimationFrame(()=>requestAnimationFrame(()=>{nb.style.transition=old.style.transition='transform .38s cubic-bezier(.3,.9,.3,1)';nb.style.transform='none';old.style.transform=ax==='x'?'translateX('+(-sgn*m)+'px)':'translateY('+(-sgn*m)+'px)'}));
  setTimeout(()=>old.remove(),400);cur=nb;wi=n;enter(nb);loop&&loop()}
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
 return {box,start:()=>{enter(cur);loop&&!RM&&loop()},stop:()=>clearInterval(iv)}}

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
 const f=h('button','foot',R.action[0]);f.style.color=R.color;f.onclick=()=>R.action[1](el);el.appendChild(f);
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
  action:['New note',()=>go('note',{id:'new'})]})}};

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
  action:['Rain alert',e=>receipt(e,'You’ll hear 30 minutes before rain.')]});
 return ()=>{clearInterval(iv);r&&r()}}};

/* ---------- Deck (Training) ---------- */
SCREENS.training={title:'Training',accent:'training',tess:'Bench opens at 185 tonight. Last time, three fives.',render(el){
 return landingV3(el,{name:'Deck',color:'var(--training)',theme:'chalk',big:"font-family:Caveat,cursive;font-weight:600;font-size:48px;letter-spacing:0",
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
  action:['Start Push A',()=>go('workout')]})}};

/* ---------- Galley (Kitchen) ---------- */
SCREENS.kitchen={title:'Kitchen',accent:'kitchen',tess:'Tacos tonight works. You need tortillas, cilantro and limes.',render(el){
 return landingV3(el,{name:'Galley',color:'var(--kitchenText)',theme:'steam',big:"font-family:Caveat,cursive;font-weight:600;font-size:48px;letter-spacing:0",
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
  action:['Cook',()=>go('cook')]})}};

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
  action:['Plant',e=>receipt(e,'Tap open ground in the woodland to plant.')]})}};

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
  action:['Log',e=>receipt(e,'Say what you spent. Tess files it.')]})}};
{const ph=document.getElementById('phone');const setP=()=>ph.style.setProperty('--purse',ph.dataset.look==='black'?'#8DBFA7':'#3F7A62');setP();new MutationObserver(setP).observe(ph,{attributes:true,attributeFilter:['data-look']})}

