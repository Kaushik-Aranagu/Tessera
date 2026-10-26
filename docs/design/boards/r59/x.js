(()=>{
const RM=matchMedia('(prefers-reduced-motion: reduce)').matches;const $=id=>document.getElementById(id);
let CC={};const css=v=>CC[v]??(CC[v]=getComputedStyle($('ph')).getPropertyValue(v).trim());
const WXC=[
 ['clear','sky1','Sunny',' until 4 PM.','clear (0), day'],
 ['clearN','moon','Clear',' tonight.','clear (0), night'],
 ['mostly','sky1','Mostly sunny',' today.','mainlyClear (1), day'],
 ['mostlyN','moon','Mostly clear',' after 9 PM.','mainlyClear (1), night'],
 ['partly','pcloud','Partly cloudy',' this afternoon.','partlyCloudy (2), day'],
 ['partlyN','moon','Partly cloudy',' tonight.','partlyCloudy (2), night'],
 ['overcast','cloud','Cloudy',' until noon.','overcast (3)'],
 ['fog','fog','Fog',' until 10 AM.','fog (45, 48)'],
 ['drizzle','rain','Drizzle',' from 3 PM.','drizzle (51, 53, 55)'],
 ['fdrizzle','ice','Freezing drizzle',' at dawn.','freezingDrizzle (56, 57)'],
 ['rain','rain','Rain',' from 4 PM.','rain (61, 63, 80, 81)'],
 ['heavy','rain','Heavy rain',' after 6 PM.','heavyRain (65, 82)'],
 ['frain','ice','Freezing rain',' tonight.','freezingRain (66, 67)'],
 ['snow','snow','Snow',' after 8 PM.','snow (71, 73, 85)'],
 ['hsnow','snow','Heavy snow',' overnight.','heavySnow (75, 86)'],
 ['grains','snow','Snow grains',' this morning.','snowGrains (77)'],
 ['storm','storm','Thunderstorms',' after 5 PM.','thunderstorm (95)'],
 ['hail','storm','Storms with hail',' at 6 PM.','thunderstormHail (96, 99)'],
 ['wind','wind','Windy',' this afternoon.','windy, wind 20 mph or more'],
 ['windW','warn','Wind warning',', gusts 45 mph.','windWarning, gusts 40 mph or more'],
 ['heat','warn','Heat warning',', feels like 101°.','heatWarning, feels like 95° or more'],
 ['cold','ice','Cold warning',', feels like 2°.','coldWarning, feels like 5° or less']];
const wxSpan=(k,c,w)=>`<span class="hl wx${/^(clear|mostly|partly)$/.test(k)?' shine':''}" data-wx="${k}" data-c="var(--${c})" style="color:var(--${c});--c:var(--${c})">${w}</span>`;
const WXS={};WXC.forEach(([k,c,w,r])=>WXS[k]=wxSpan(k,c,w)+r);
const TONE={white:[['#FFFFFF','#E6E9ED','#8A949F'],['#F2F4F7','#C3C9D0','#454C54']],grey:[['#E3E6EA','#B5BCC4','#78818B'],['#B4BBC3','#838B94','#363C43']],
  rain:[['#A2ADB8','#71808D','#47535F'],['#828E9A','#56616C','#22282E']],storm:[['#8A88A4','#5A5874','#34334B'],['#75738F','#474561','#1A1928']]};
const rgba=(h,a)=>{const n=parseInt(h.slice(1),16);return `rgba(${n>>16&255},${n>>8&255},${n&255},${Math.max(0,Math.min(1,a)).toFixed(3)})`};
const isDark=()=>css('--phone').toLowerCase()==='#000000';
// a cloud is a flat-bottomed cumulus: a union of puffs filled once, lit from the top (hi to lo), with soft lit
// bumps inside and a 1.5 pt soft rim, drawn offscreen and laid on at one alpha so overlaps never bead up.
const CO=document.createElement('canvas');CO.width=900;CO.height=240;
function cloud(x,cx,cy,w,h,tone,a,t,seed){const [hi,mid,lo]=TONE[tone][isDark()?1:0],o=CO.getContext('2d'),S=2,pad=8,bw=w+pad*2,bh=h*1.5+pad*2;
  if(bw*S>CO.width||bh*S>CO.height)return cy+h*.32;o.setTransform(1,0,0,1,0,0);o.clearRect(0,0,CO.width,CO.height);o.setTransform(S,0,0,S,0,0);
  const ox=pad,oy=pad+h*.55,units=Math.max(1,Math.round(w/(h*2.4))),uw=w/units,P=[],B=[];
  for(let u=0;u<units;u++){const ux=ox+uw*u,j=Math.sin(seed*5+u*2.3),br=k=>1+.05*Math.sin(t/1800+k+seed+u);
    P.push([ux+uw*.24,oy+h*.02,h*.30*br(1)],[ux+uw*.5,oy-h*.16+j*h*.05,h*.42*br(2)],[ux+uw*.76,oy+h*.04,h*.29*br(3)]);
    if(u===0)P.push([ux+uw*.08,oy+h*.16,h*.19*br(4)]);if(u===units-1)P.push([ux+uw*.93,oy+h*.17,h*.17*br(5)]);
    B.push([ux+uw*.46,oy-h*.24+j*h*.05,h*.22],[ux+uw*.22,oy-h*.06,h*.14])}
  const base=oy+h*.3,shape=(g)=>{o.beginPath();P.forEach(([px,py,r])=>{o.moveTo(px+r+g,py);o.arc(px,py,r+g,0,7)});o.roundRect(ox-g,oy-h*.05-g,w+g*2,base-(oy-h*.05)+g*2,h*.2+g)};
  o.save();o.beginPath();o.rect(0,0,bw,base+1.6);o.clip();o.fillStyle=rgba(mid,.3);shape(1.6);o.fill();o.fillStyle=rgba(mid,1);shape(0);o.fill();
  o.globalCompositeOperation='source-atop';const g=o.createLinearGradient(0,oy-h*.6,0,base);g.addColorStop(0,hi);g.addColorStop(.55,mid);g.addColorStop(1,lo);o.fillStyle=g;o.fillRect(0,0,bw,bh);
  B.forEach(([px,py,r])=>{const rg=o.createRadialGradient(px,py,0,px,py,r*1.6);rg.addColorStop(0,rgba(hi,.75));rg.addColorStop(1,rgba(hi,0));o.fillStyle=rg;o.fillRect(px-r*2,py-r*2,r*4,r*4)});o.restore();
  x.save();x.globalAlpha=a;x.drawImage(CO,0,0,bw*S,bh*S,cx-w/2-pad,cy-h*.55-pad,bw,bh);x.restore();return cy+h*.3}
function glint(x,cx,cy,s,col,a){if(s<=.2)return;x.strokeStyle=col;x.globalAlpha=a;x.lineWidth=1;x.lineCap='round';x.beginPath();x.moveTo(cx-s,cy);x.lineTo(cx+s,cy);x.moveTo(cx,cy-s);x.lineTo(cx,cy+s);x.stroke();x.lineWidth=.7;x.beginPath();x.moveTo(cx-s*.4,cy-s*.4);x.lineTo(cx+s*.4,cy+s*.4);x.moveTo(cx-s*.4,cy+s*.4);x.lineTo(cx+s*.4,cy-s*.4);x.stroke();x.globalAlpha=1}
function flake(x,fx,fy,r){x.beginPath();for(let a=0;a<3;a++){const an=a*Math.PI/3;x.moveTo(fx-Math.cos(an)*r,fy-Math.sin(an)*r);x.lineTo(fx+Math.cos(an)*r,fy+Math.sin(an)*r)}x.stroke()}
function letters(el){if(el.dataset.split)return[...el.querySelectorAll('.lt')];el.innerHTML=[...el.textContent].map(ch=>ch===' '?' ':`<span class="lt">${ch}</span>`).join('');el.dataset.split=1;return[...el.querySelectorAll('.lt')]}
function drops(x,L,W,top,bot,n,len,lw,per,slant,col,a,t,seed){x.strokeStyle=col;x.lineWidth=lw;x.lineCap='round';for(let i=0;i<n;i++){const sp=((i*37+seed)%11)/11,u=((t/(per+sp*per*.35))+sp)%1,dx=L+3+((i*23+seed*7)%Math.max(1,W-6)),y=top+u*(bot-top),sx=slant*u;
  x.globalAlpha=a*Math.min(1,(1-u)*6,u*6);x.beginPath();x.moveTo(dx+sx+slant*.25,y);x.lineTo(dx+sx,y+len);x.stroke()}x.globalAlpha=1}
function drawWord(x,el,b,t,xb){// his 12:11 AM: clouds sit level with the word (same height), behind it, a little see-through; never above it
const cl=(cx,cy,w,h,tone,a,t2,seed)=>{const {T:bT,H:bH,L:bL,W:bW}=b,h2=Math.max(h,bH*1.1),cy2=bT+bH*.7+(cy-(bT+bH*.4))*.12;w=Math.min(w,bW*.5);cx=Math.max(bL+w*.5,Math.min(bL+bW-w*.5,cx));xb.save();xb.beginPath();xb.rect(bL-3,bT-1,bW+6,bH+2);xb.clip();cloud(xb,cx,cy2,w,h2,tone,a*(tone==="white"?(isDark()?.5:.9):.62),t2,seed);xb.restore();return bT+bH*.45};
  // soft wisps in front, the fog technique in the cloud's own colour, kept inside the word (his 12:16 AM)
  const puffs=(n,tone,a)=>{const c=TONE[tone][isDark()?1:0][0];x.save();x.beginPath();x.rect(L-3,T-1,W+6,H+2);x.clip();for(let i=0;i<n;i++){const u=((t/(8000+i*2300))+i*.41)%1,cx=L-W*.2+u*W*1.4,cy=T+H*(.4+.18*(i%3)),rw=W*(.22+.06*i),rh=H*.24;x.save();x.translate(cx,cy);x.scale(rw/rh,1);const g=x.createRadialGradient(0,0,0,0,0,rh);g.addColorStop(0,rgba(c,a*Math.sin(u*Math.PI)));g.addColorStop(1,rgba(c,0));x.fillStyle=g;x.beginPath();x.arc(0,0,rh,0,7);x.fill();x.restore()}x.restore()};const {L,T,W,H}=b,k=el.dataset.wx,col=css(el.dataset.c.slice(4,-1)),pg=css('--phone'),base=T+H*1.02;
  const wordCol=c=>{if(el.style.color!==c)el.style.color=c};
  if(k==='clearN'||k==='mostlyN'||k==='partlyN'){const N=k==='clearN'?4:k==='mostlyN'?3:2;for(let i=0;i<N;i++){const per=2600+i*700,u=((t+i*900)%per)/per,s=Math.sin(Math.min(1,u*2.2)*Math.PI)*3.6;glint(x,L+W*(.12+.78*((i*.37+.15)%1)),T+H*(i%2?.2:.06)-2,s,col,.95)}}
  if(k==='mostly'||k==='mostlyN')puffs(2,'white',.3);if(k==='partly'||k==='partlyN')puffs(3,'white',.34);if(k==='overcast')puffs(4,'grey',.4);
  if(k==='mostly')cl(L+W*(.66+.16*Math.sin(t/5200)),T+H*.36,Math.min(52,W*.36),H*.78,'white',1,t,1);
  if(k==='mostlyN')cl(L+W*(.64+.18*Math.sin(t/5600)),T+H*.36,Math.min(50,W*.34),H*.74,'white',.9,t,2);
  if(k==='partly'||k==='partlyN'){const a=k==='partly'?1:.9;cl(L+W*(.3+.12*Math.sin(t/6100)),T+H*.3,Math.min(56,W*.34),H*.78,'white',a,t,3);cl(L+W*(.76+.08*Math.sin(t/4700+1)),T+H*.3,Math.min(52,W*.32),H*.72,'white',a,t,4)}
  if(k==='overcast'){cl(L+W*(.22+.08*Math.sin(t/7000)),T+H*.28,W*.5,H*.82,'grey',.95,t,5);cl(L+W*(.7+.1*Math.sin(t/5400+2)),T+H*.44,W*.5,H*.78,'grey',.92,t,6);cl(L+W*(1.02+.05*Math.sin(t/6300)),T+H*.2,W*.36,H*.7,'grey',.88,t,7)}
  if(k==='fog'){// the word thins where the mist is thick (a moving mask), soft elongated wisps drift past in front and behind
    const m=[0,1,2].map(i=>((t/(6400+i*2100))+i*.37)%1*140-20);el.style.webkitMaskImage=el.style.maskImage=`linear-gradient(90deg,${[...Array(15)].map((_,q)=>{const p=q*100/14;let v=1;m.forEach((c,i)=>{const d=(p-c)/(16+i*5);v-=[.62,.5,.42][i]*Math.exp(-d*d)});return `rgba(0,0,0,${Math.max(.3,v).toFixed(2)}) ${p.toFixed(1)}%`}).join(',')})`;
    const fc=css('--fog'),wisp=(c,cx,cy,rw,rh,a)=>{c.save();c.translate(cx,cy);c.scale(rw/rh,1);const g=c.createRadialGradient(0,0,0,0,0,rh);g.addColorStop(0,rgba(pg,a));g.addColorStop(.5,rgba(pg,a*.6));g.addColorStop(1,rgba(pg,0));c.fillStyle=g;c.beginPath();c.arc(0,0,rh,0,7);c.fill();c.restore()},tint=(c,cx,cy,rw,rh,a)=>{c.save();c.translate(cx,cy);c.scale(rw/rh,1);const g=c.createRadialGradient(0,0,0,0,0,rh);g.addColorStop(0,rgba(fc,a));g.addColorStop(1,rgba(fc,0));c.fillStyle=g;c.beginPath();c.arc(0,0,rh,0,7);c.fill();c.restore()};
    for(let i=0;i<3;i++){const u=((t/(9000+i*2500))+i*.33)%1;tint(xb,L-W*.3+u*W*1.6,T+H*(.35+.2*i),W*.5,H*.36,.32)}
    for(let i=0;i<4;i++){const u=((t/(7000+i*1700))+i*.27)%1,a=Math.sin(u*Math.PI)*.8;wisp(x,L-W*.35+u*W*1.7,T+H*(.3+.16*i)+Math.sin(t/1500+i)*1.5,W*(.32+.08*i),H*.2,a)}}
  const rc=()=>T-2;// his 12:16 AM: no clouds on rain, snow or storms, only the weather itself
  if(k==='drizzle'){const cb=rc('rain',.8);drops(x,L,W,cb,base,16,3,.9,1050,0,col,.75,t,1)}
  if(k==='rain'){const cb=rc('rain',.88);drops(x,L,W,cb,base,11,7,1.3,640,0,col,.85,t,2)}
  if(k==='heavy'){const cb=rc('rain',.95);drops(x,L,W,cb,base,20,9,1.4,480,-3,col,.9,t,3);x.strokeStyle=col;x.lineWidth=1;for(let i=0;i<5;i++){const u=((t/520)+i*.2)%1,sx=L+W*((i*.31+.1)%1);if(u<.35){x.globalAlpha=.8*(1-u/.35);x.beginPath();x.moveTo(sx-1-u*8,base-u*6);x.lineTo(sx,base);x.lineTo(sx+1+u*8,base-u*6);x.stroke()}}x.globalAlpha=1}
  if(k==='fdrizzle'||k==='frain'){const cb=rc('rain',.85);drops(x,L,W,cb,base,k==='frain'?11:16,k==='frain'?7:3,k==='frain'?1.3:.9,k==='frain'?640:1050,0,col,.85,t,4);
    const gy=T+H*.97;x.strokeStyle=col;x.lineWidth=1.2;x.globalAlpha=.7;x.beginPath();x.moveTo(L,gy);x.lineTo(L+W,gy);x.stroke();const u=(t%3200)/3200,gx=L+u*W;x.strokeStyle=isDark()?'#FFFFFF':'#FFFFFF';x.lineWidth=1.6;x.globalAlpha=Math.sin(u*Math.PI);x.beginPath();x.moveTo(gx-7,gy);x.lineTo(gx+7,gy);x.stroke();glint(x,gx,gy,2.6*Math.sin(u*Math.PI),col,.9)}
  if(k==='snow'||k==='hsnow'){const cb=rc('grey',.82),n=k==='snow'?9:17;x.strokeStyle=col;x.lineWidth=1.1;x.lineCap='round';for(let i=0;i<n;i++){const sp=((i*41)%13)/13,u=((t/(2600+sp*1400))+sp)%1,fx=L+4+((i*27)%Math.max(1,W-8))+Math.sin(t/800+i)*4,fy=cb+u*(base-cb+6);x.globalAlpha=.95*Math.sin(u*Math.PI);flake(x,fx,fy,1.6+(i%3)*.5)}x.globalAlpha=1;
    if(k==='hsnow'){const g=.5+.5*Math.sin(t/3000);x.strokeStyle=col;x.lineWidth=1.6;x.globalAlpha=.55+.4*g;x.beginPath();for(let p=0;p<=W;p+=2){const yy=T+H*.2-Math.abs(Math.sin(p/7))*1.4*g;p?x.lineTo(L+p,yy):x.moveTo(L,yy)}x.stroke();x.globalAlpha=1}}
  if(k==='grains'){const cb=rc('grey',.75);x.strokeStyle=col;x.lineWidth=1.2;x.lineCap='round';for(let i=0;i<22;i++){const sp=((i*29)%17)/17,u=((t/(900+sp*300))+sp)%1,gx=L+2+((i*19)%Math.max(1,W-4))+Math.sin(i*7+t/200)*.6,gy=cb+u*(base-cb);x.globalAlpha=.9*Math.min(1,(1-u)*6,u*6);x.beginPath();x.moveTo(gx,gy);x.lineTo(gx,gy+1.6);x.stroke()}x.globalAlpha=1}
  if(k==='storm'||k==='hail'){const cb=rc('storm',.95);drops(x,L,W,cb,base,k==='hail'?6:10,7,1.2,560,-2,col,.7,t,5);
    if(k==='hail'){x.strokeStyle=css('--ice');x.lineWidth=1.1;for(let i=0;i<7;i++){const sp=((i*31)%9)/9,u=((t/(820+sp*200))+sp)%1,hx=L+4+((i*37)%Math.max(1,W-8));let y=cb+u/.8*(base-cb);if(u>.8){const v=(u-.8)/.2;y=base-Math.sin(v*Math.PI)*6}x.globalAlpha=u>.8?1-(u-.8)/.2*.6:Math.min(1,u*8);x.save();x.translate(hx+(u>.8?(u-.8)*20:0),y);x.rotate(u*6);x.strokeRect(-1.3,-1.3,2.6,2.6);x.restore()}x.globalAlpha=1}
    const cyc=Math.floor(t/5200),p=(t%5200)/5200,fl=p<.045||(p>.085&&p<.12);
    if(fl){let bx=L+W*(.25+.5*((cyc*.618)%1)),by=cb-2;x.strokeStyle=css('--bolt');x.lineCap='round';x.lineJoin='round';const pts=[[bx,by]];for(let s=0;s<5;s++){bx+=((s*7+cyc*3)%5-2)*2.6;by+=(base-cb)/5;pts.push([bx,by])}
      [[5,.22],[1.6,1]].forEach(([w,a])=>{x.lineWidth=w;x.globalAlpha=a;x.beginPath();pts.forEach(([px,py],j)=>j?x.lineTo(px,py):x.moveTo(px,py));x.stroke()});x.globalAlpha=1;wordCol('var(--bolt)')}else wordCol(el.dataset.c)}
  if(k==='wind'||k==='windW'){const S=letters(el),amp=k==='wind'?1:1.35;S.forEach((s,i)=>{const g=Math.max(0,Math.sin(t/(k==='wind'?1400:900)-i*.5)),sh=k==='windW'?Math.sin(t/45+i)*.35:0;s.style.transform=`translate(${(g*g*4*amp+sh).toFixed(2)}px,${(-g*g*1.2*amp).toFixed(2)}px) skewX(${(-g*g*12*amp).toFixed(1)}deg) rotate(${(g*g*2*amp).toFixed(1)}deg)`});
    x.strokeStyle=k==='wind'?col:css('--wind');x.lineWidth=1.2;x.lineCap='round';const ng=k==='wind'?5:8;for(let i=0;i<ng;i++){const u=((t/(k==='wind'?1300:850)+i*.13)%1),gx=L-18+u*(W+52),gy=T+H*(.12+.11*i%.9)+Math.sin(t/300+i)*1.2,len=(12+5*(i%3))*(k==='wind'?1:1.6);x.globalAlpha=Math.sin(u*Math.PI)*.8;x.beginPath();x.moveTo(gx,gy);x.quadraticCurveTo(gx+len*.6,gy-2,gx+len,gy);x.stroke()}x.globalAlpha=1}
  if(k==='heat'){const S=letters(el);S.forEach((s,i)=>{s.style.transform=`translateY(${(Math.sin(t/260-i*.7)*1.3).toFixed(2)}px) scaleY(${(1+Math.sin(t/260-i*.7)*.03).toFixed(3)})`});
    x.strokeStyle=col;x.lineWidth=1.1;x.lineCap='round';for(let i=0;i<4;i++){const u=((t/2200)+i*.25)%1,hx=L+W*(.15+.23*i),y0=T+H*.05-u*14;x.globalAlpha=.7*Math.sin(u*Math.PI);x.beginPath();for(let s=0;s<=10;s++){const yy=y0-s,xx=hx+Math.sin(s/2.2+t/180+i)*1.6;s?x.lineTo(xx,yy):x.moveTo(xx,yy)}x.stroke()}x.globalAlpha=1}
  if(k==='cold'){x.strokeStyle=col;x.lineCap='round';for(let i=0;i<7;i++){const per=3800,u=((t+i*540)%per)/per,s=Math.sin(Math.min(1,u*1.6)*Math.PI)*3.4,fx=L+W*(.06+.14*i),fy=i%2?T+H*.14:base+1;x.globalAlpha=.9;x.lineWidth=1;if(s>.3){flake(x,fx,fy,s);x.lineWidth=.7;for(let a=0;a<6;a++){const an=a*Math.PI/3,mx=fx+Math.cos(an)*s*.6,my=fy+Math.sin(an)*s*.6;x.beginPath();x.moveTo(mx,my);x.lineTo(mx+Math.cos(an+.6)*s*.35,my+Math.sin(an+.6)*s*.35);x.stroke()}}}x.globalAlpha=1}}
function drawSet(cv,root,t,bk){const R_=root.getBoundingClientRect(),k=cv===$('wxfx')?402/R_.width:1;if(cv!==$('wxfx')){const w=Math.round(R_.width*2),h=Math.round(R_.height*2);[cv,bk].forEach(c=>{if(c.width!==w||c.height!==h){c.width=w;c.height=h}})}
  const x=cv.getContext('2d'),xb=bk.getContext('2d');[x,xb].forEach(c=>{c.setTransform(2,0,0,2,0,0);c.clearRect(0,0,cv.width,cv.height)});if(RM)return;
  [...root.querySelectorAll('.wx')].filter(el=>!el.closest('[data-cover]')).forEach(el=>{const b=el.getBoundingClientRect();if(!b.width||b.bottom<0||b.top>innerHeight)return;drawWord(x,el,{L:(b.left-R_.left)*k,T:(b.top-R_.top)*k,W:b.width*k,H:b.height*k},t,xb)})}

function drawWx(t){drawSet($('wxfx'),$('ph'),t,$('wxbk'))}
const w=(k,txt)=>{const c=WXC.find(x=>x[0]===k);return wxSpan(k,c[1],txt||c[2])};
$('hl').innerHTML=`${w('overcast')} now, ${w('rain')} from 4 PM.`;
$('hl2').innerHTML=`${w('heavy')} after 6 PM, clearing by midnight.`;
$('hl2').querySelector('.wx').style.fontWeight=600;
const HRS=[['4 PM',57,'rain','Rain'],['5 PM',56,'rain','Rain'],['6 PM',55,'heavy','Heavy'],['7 PM',54,'heavy','Heavy'],['8 PM',53,'rain','Rain'],['9 PM',52,'drizzle','Drizzle'],['10 PM',51,'overcast','Cloudy'],['11 PM',50,'overcast','Cloudy'],['12 AM',49,'partlyN','Clearing'],['1 AM',48,'clearN','Clear'],['2 AM',47,'clearN','Clear'],['3 AM',47,'clearN','Clear']];
const colOf=k=>WXC.find(x=>x[0]===k)[1];
const hrsHTML=H=>H.map(([h,tp,k,word])=>`<div class="hr"><span class="n" style="font-size:13px;color:var(--ink2)">${h}</span><span class="n" style="font-size:24px;font-weight:300;line-height:30px">${tp}°</span><span style="font-size:13px;font-weight:600;color:var(--${colOf(k)})">${word}</span></div>`).join('');
$('hrs').innerHTML=hrsHTML(HRS);
function pager(W,R,n){let i=0,sx=null,sy=null,lock=null;const step=59*3,max=Math.max(0,Math.ceil((n-6)/3));const go=()=>{R.style.transform=`translateX(${-i*step}px)`};
  W.addEventListener('pointerdown',e=>{sx=e.clientX;sy=e.clientY;lock=null;W.setPointerCapture(e.pointerId);R.style.transition='none'});
  W.addEventListener('pointermove',e=>{if(sx==null)return;const dx=e.clientX-sx,dy=e.clientY-sy;if(!lock&&Math.hypot(dx,dy)>10)lock=Math.abs(dx)>Math.abs(dy)?'x':'y';const d=lock==='x'?dx:lock==='y'?dy:0;R.style.transform=`translateX(${-i*step+d}px)`});
  W.addEventListener('pointerup',e=>{if(sx==null)return;const d=lock==='x'?e.clientX-sx:lock==='y'?e.clientY-sy:0;sx=null;R.style.transition='';if(Math.abs(d)>30)i=Math.max(0,Math.min(max,i+(d<0?1:-1)));go()});
  W.tabIndex=0;W.addEventListener('keydown',e=>{if(e.key==='ArrowRight')i=Math.min(max,i+1);if(e.key==='ArrowLeft')i=Math.max(0,i-1);go()})}
pager($('hrsW'),$('hrs'),HRS.length);
const DAYS={Saturday:{k:'clear',hi:63,lo:48,s:`${w('clear')} all day, a light breeze.`,sun:'7:22 AM',set:'6:10 PM',h:[['9 AM',52,'clear','Sunny'],['12 PM',60,'clear','Sunny'],['3 PM',63,'clear','Sunny'],['6 PM',58,'clear','Sunny'],['9 PM',53,'clearN','Clear'],['12 AM',49,'clearN','Clear']]},
 Sunday:{k:'partly',hi:61,lo:47,s:`${w('partly')} from midday.`,sun:'7:23 AM',set:'6:09 PM',h:[['9 AM',50,'mostly','Mostly'],['12 PM',58,'partly','Partly'],['3 PM',61,'partly','Partly'],['6 PM',56,'overcast','Cloudy'],['9 PM',51,'partlyN','Partly'],['12 AM',48,'clearN','Clear']]},
 Monday:{k:'wind',hi:56,lo:45,s:`${w('wind')} in the afternoon, gusts to <span class="n">30</span> mph.`,sun:'7:24 AM',set:'6:07 PM',h:[['9 AM',49,'overcast','Cloudy'],['12 PM',54,'wind','Windy'],['3 PM',56,'wind','Windy'],['6 PM',52,'wind','Windy'],['9 PM',48,'overcast','Cloudy'],['12 AM',46,'overcast','Cloudy']]},
 Tuesday:{k:'rain',hi:54,lo:46,s:`${w('rain')} most of the day, heaviest at 2 PM.`,sun:'7:25 AM',set:'6:06 PM',h:[['9 AM',48,'drizzle','Drizzle'],['12 PM',52,'rain','Rain'],['2 PM',54,'heavy','Heavy'],['6 PM',51,'rain','Rain'],['9 PM',48,'drizzle','Drizzle'],['12 AM',46,'overcast','Cloudy']]},
 Thursday:{k:'cold',hi:41,lo:2,s:`${w('cold')} overnight, feels like <span class="n">2°</span>.`,sun:'7:27 AM',set:'6:03 PM',h:[['9 AM',30,'mostly','Mostly'],['12 PM',38,'clear','Sunny'],['3 PM',41,'clear','Sunny'],['6 PM',30,'clearN','Clear'],['9 PM',14,'clearN','Clear'],['12 AM',4,'cold','Cold']]}};
const door=(d,k,txt)=>`<button class="tap" data-day="${d}" style="min-height:34px;display:inline;font-weight:inherit">${w(k,txt)}</button>`;
$('wk').innerHTML=`Saturday is ${door('Saturday','clear')}, Sunday ${door('Sunday','partly')}, Monday ${door('Monday','wind')}. Tuesday brings ${door('Tuesday','rain')} again, and Thursday a ${door('Thursday','cold')}.`;
const day=$('day');function openDay(d){const D=DAYS[d];$('dT').textContent=d;$('dHi').textContent=D.hi+'°';$('dLo').textContent=D.lo+'°';$('dHi').style.color=`var(--${colOf(D.k)})`;$('dS').innerHTML=D.s;$('dHrs').innerHTML=hrsHTML(D.h);$('dSun').innerHTML=`Sunrise <span class="n">${D.sun}</span>, sunset <span class="n">${D.set}</span>.`;
  day.hidden=false;$('land').dataset.cover=1;if(!RM){day.style.transform='translateX(100%)';day.offsetWidth;day.style.transition='transform .42s cubic-bezier(.2,.9,.25,1.04)';day.style.transform=''}}
function closeDay(){delete $('land').dataset.cover;if(RM){day.hidden=true;return}day.style.transform='translateX(100%)';setTimeout(()=>{day.hidden=true;day.style.transition='';day.style.transform=''},420)}
$('wk').querySelectorAll('[data-day]').forEach(b=>b.onclick=()=>openDay(b.dataset.day));$('back').onclick=closeDay;
(()=>{let sx=null;day.addEventListener('pointerdown',e=>{const r=$('ph').getBoundingClientRect();sx=(e.clientX-r.left)*402/r.width<24?e.clientX:null});day.addEventListener('pointerup',e=>{if(sx!=null&&e.clientX-sx>60)closeDay();sx=null})})();
let undoT;$('alert').onclick=()=>{const on=$('alert').dataset.on!=='1';$('alert').dataset.on=on?'1':'0';$('alert').textContent=on?'Rain alert on':'Rain alert';$('rc').innerHTML=(on?'You’ll hear 30 minutes before rain.':'Rain alert off.')+' <button class="tap" id="undo" style="color:var(--acc);font-weight:600;margin-left:6px">Undo</button>';$('undo').onclick=()=>{$('alert').click();$('rc').textContent=''};clearTimeout(undoT);undoT=setTimeout(()=>$('rc').textContent='',10000)};
$('fromHome').onclick=()=>{closeDay();const L=$('land');if(RM)return;L.style.clipPath='circle(0% at 78% 30%)';L.offsetWidth;L.style.transition='clip-path .6s cubic-bezier(.2,.9,.25,1)';L.style.clipPath='circle(140% at 78% 30%)';setTimeout(()=>{L.style.transition='';L.style.clipPath=''},650)};
$('th').onclick=()=>{document.documentElement.dataset.theme='dark';CC={}};$('tw').onclick=()=>{document.documentElement.dataset.theme='light';CC={}};matchMedia('(prefers-color-scheme: dark)').addEventListener('change',()=>{CC={}});
function fit(){const f=document.querySelector('.fit'),s=f.clientWidth/402;$('ph').style.transform=`scale(${s})`}addEventListener('resize',fit);fit();
(function loop(t){drawWx(t);requestAnimationFrame(loop)})(performance.now());
})();
