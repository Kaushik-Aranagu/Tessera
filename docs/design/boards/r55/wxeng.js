// ---------- every weather word (his 11:51 PM): one effect per forecast case, Core's WeatherCondition list
// Clouds are soft layered puffs (shade under, body, lit top) that breathe and drift; the word's colour follows the cloud.
// Thin strokes only, never pixels or filled dots. Reduce Motion: no effect, the word keeps its colour.
const WXC=[
 ['clear','sun','Sunny',' until 4 PM.','clear (0), day'],
 ['clearN','moon','Clear',' tonight.','clear (0), night'],
 ['mostly','sun','Mostly sunny',' today.','mainlyClear (1), day'],
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
const TONE={white:[['#FFFFFF','#EEF0F3','#A3ABB4'],['#F2F4F7','#C3C9D0','#454C54']],grey:[['#E3E6EA','#B5BCC4','#78818B'],['#B4BBC3','#838B94','#363C43']],
  rain:[['#A2ADB8','#71808D','#47535F'],['#828E9A','#56616C','#22282E']],storm:[['#8A88A4','#5A5874','#34334B'],['#75738F','#474561','#1A1928']]};
const rgba=(h,a)=>{const n=parseInt(h.slice(1),16);return `rgba(${n>>16&255},${n>>8&255},${n&255},${Math.max(0,Math.min(1,a)).toFixed(3)})`};
const isDark=()=>css('--phone').toLowerCase()==='#000000';
function cloud(x,cx,cy,w,h,tone,a,t,seed){const [hi,mid,lo]=TONE[tone][isDark()?1:0],n=Math.max(3,Math.round(w/(h*.9))),P=[];
  for(let i=0;i<n;i++){const f=n>1?i/(n-1):.5,r=h*(.36+.30*Math.sin(f*Math.PI)+.06*Math.sin(seed*3+i*2.1))*(1+.05*Math.sin(t/1900+i*1.7+seed)),px=cx-w/2+w*(i+.5)/n+Math.sin(t/2300+i+seed)*1.2;P.push([px,cy+h*.12-r*.45,r])}
  P.forEach(([px,py,r])=>{const g=x.createRadialGradient(px,py+r*.5,0,px,py+r*.5,r*1.15);g.addColorStop(0,rgba(lo,a*.55));g.addColorStop(1,rgba(lo,0));x.fillStyle=g;x.beginPath();x.arc(px,py+r*.5,r*1.15,0,7);x.fill()});
  P.forEach(([px,py,r])=>{const g=x.createRadialGradient(px-r*.25,py-r*.3,r*.05,px,py,r);g.addColorStop(0,rgba(hi,a));g.addColorStop(.55,rgba(mid,a*.92));g.addColorStop(.85,rgba(mid,a*.5));g.addColorStop(1,rgba(mid,0));x.fillStyle=g;x.beginPath();x.arc(px,py,r,0,7);x.fill()});
  return cy+h*.32}
function glint(x,cx,cy,s,col,a){if(s<=.2)return;x.strokeStyle=col;x.globalAlpha=a;x.lineWidth=1;x.lineCap='round';x.beginPath();x.moveTo(cx-s,cy);x.lineTo(cx+s,cy);x.moveTo(cx,cy-s);x.lineTo(cx,cy+s);x.stroke();x.lineWidth=.7;x.beginPath();x.moveTo(cx-s*.4,cy-s*.4);x.lineTo(cx+s*.4,cy+s*.4);x.moveTo(cx-s*.4,cy+s*.4);x.lineTo(cx+s*.4,cy-s*.4);x.stroke();x.globalAlpha=1}
function flake(x,fx,fy,r){x.beginPath();for(let a=0;a<3;a++){const an=a*Math.PI/3;x.moveTo(fx-Math.cos(an)*r,fy-Math.sin(an)*r);x.lineTo(fx+Math.cos(an)*r,fy+Math.sin(an)*r)}x.stroke()}
function letters(el){if(el.dataset.split)return[...el.children];el.innerHTML=[...el.textContent].map(ch=>`<span class="lt"${ch===' '?' style="white-space:pre"':''}>${ch}</span>`).join('');el.dataset.split=1;return[...el.children]}
function drops(x,L,W,top,bot,n,len,lw,per,slant,col,a,t,seed){x.strokeStyle=col;x.lineWidth=lw;x.lineCap='round';for(let i=0;i<n;i++){const sp=((i*37+seed)%11)/11,u=((t/(per+sp*per*.35))+sp)%1,dx=L+3+((i*23+seed*7)%Math.max(1,W-6)),y=top+u*(bot-top),sx=slant*u;
  x.globalAlpha=a*Math.min(1,(1-u)*6,u*6);x.beginPath();x.moveTo(dx+sx+slant*.25,y);x.lineTo(dx+sx,y+len);x.stroke()}x.globalAlpha=1}
function drawWord(x,el,b,t){const {L,T,W,H}=b,k=el.dataset.wx,col=css(el.dataset.c.slice(4,-1)),pg=css('--phone'),base=T+H*.86;
  const wordCol=c=>{if(el.style.color!==c)el.style.color=c};
  if(k==='clearN'||k==='mostlyN'||k==='partlyN'){const N=k==='clearN'?4:k==='mostlyN'?3:2;for(let i=0;i<N;i++){const per=2600+i*700,u=((t+i*900)%per)/per,s=Math.sin(Math.min(1,u*2.2)*Math.PI)*3.6;glint(x,L+W*(.12+.78*((i*.37+.15)%1)),T+H*(i%2?.2:.06)-2,s,col,.95)}}
  if(k==='mostly')cloud(x,L+W*(.62+.18*Math.sin(t/5200)),T+H*.42,Math.min(46,W*.34),H*.5,'white',.9,t,1);
  if(k==='mostlyN')cloud(x,L+W*(.6+.2*Math.sin(t/5600)),T+H*.42,Math.min(44,W*.3),H*.48,'white',.75,t,2);
  if(k==='partly'||k==='partlyN'){const a=k==='partly'?.95:.8;cloud(x,L+W*(.3+.1*Math.sin(t/6100)),T+H*.48,W*.38,H*.62,'white',a,t,3);cloud(x,L+W*(.74+.08*Math.sin(t/4700+1)),T+H*.34,W*.3,H*.5,'white',a,t,4)}
  if(k==='overcast'){cloud(x,L+W*(.2+.08*Math.sin(t/7000)),T+H*.38,W*.5,H*.62,'grey',.9,t,5);cloud(x,L+W*(.62+.1*Math.sin(t/5400+2)),T+H*.52,W*.55,H*.66,'grey',.85,t,6);cloud(x,L+W*(.95+.06*Math.sin(t/6300)),T+H*.3,W*.34,H*.5,'grey',.8,t,7)}
  if(k==='fog'){for(let i=0;i<4;i++){const y=T+H*(.22+.19*i),u=((t/(5200+i*1300))+i*.29)%1,cx=L-W*.4+u*(W*1.8),w=W*.7;const g=x.createLinearGradient(cx-w/2,0,cx+w/2,0);g.addColorStop(0,rgba(pg,0));g.addColorStop(.5,rgba(pg,.78));g.addColorStop(1,rgba(pg,0));x.fillStyle=g;x.fillRect(cx-w/2,y-2.6,w,5.2)}
    x.strokeStyle=col;x.lineWidth=1;x.lineCap='round';for(let i=0;i<2;i++){x.globalAlpha=.55;x.beginPath();const y=T+H*(.5+.32*i);for(let p=0;p<=W+16;p+=3){const yy=y+Math.sin((p+t/40*(i?1:-1))/9)*1.2;p?x.lineTo(L-8+p,yy):x.moveTo(L-8,yy)}x.stroke()}x.globalAlpha=1}
  const rc=(tone,a)=>cloud(x,L+W*(.5+.05*Math.sin(t/4800)),T+H*.02,W*.92,H*.5,tone,a,t,8);
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
  if(k==='wind'||k==='windW'){const S=letters(el),amp=k==='wind'?1:1.8;S.forEach((s,i)=>{const g=Math.max(0,Math.sin(t/(k==='wind'?1400:900)-i*.5)),sh=k==='windW'?Math.sin(t/45+i)*.35:0;s.style.transform=`translate(${(g*g*4*amp+sh).toFixed(2)}px,${(-g*g*1.2*amp).toFixed(2)}px) skewX(${(-g*g*12*amp).toFixed(1)}deg) rotate(${(g*g*2*amp).toFixed(1)}deg)`});
    x.strokeStyle=k==='wind'?col:css('--wind');x.lineWidth=1.2;x.lineCap='round';const ng=k==='wind'?5:8;for(let i=0;i<ng;i++){const u=((t/(k==='wind'?1300:850)+i*.13)%1),gx=L-18+u*(W+52),gy=T+H*(.12+.11*i%.9)+Math.sin(t/300+i)*1.2,len=(12+5*(i%3))*(k==='wind'?1:1.6);x.globalAlpha=Math.sin(u*Math.PI)*.8;x.beginPath();x.moveTo(gx,gy);x.quadraticCurveTo(gx+len*.6,gy-2,gx+len,gy);x.stroke()}x.globalAlpha=1}
  if(k==='heat'){const S=letters(el);S.forEach((s,i)=>{s.style.transform=`translateY(${(Math.sin(t/260-i*.7)*1.3).toFixed(2)}px) scaleY(${(1+Math.sin(t/260-i*.7)*.03).toFixed(3)})`});
    x.strokeStyle=col;x.lineWidth=1.1;x.lineCap='round';for(let i=0;i<4;i++){const u=((t/2200)+i*.25)%1,hx=L+W*(.15+.23*i),y0=T+H*.05-u*14;x.globalAlpha=.7*Math.sin(u*Math.PI);x.beginPath();for(let s=0;s<=10;s++){const yy=y0-s,xx=hx+Math.sin(s/2.2+t/180+i)*1.6;s?x.lineTo(xx,yy):x.moveTo(xx,yy)}x.stroke()}x.globalAlpha=1}
  if(k==='cold'){x.strokeStyle=col;x.lineCap='round';for(let i=0;i<7;i++){const per=3800,u=((t+i*540)%per)/per,s=Math.sin(Math.min(1,u*1.6)*Math.PI)*3.4,fx=L+W*(.06+.14*i),fy=i%2?T+H*.14:base+1;x.globalAlpha=.9;x.lineWidth=1;if(s>.3){flake(x,fx,fy,s);x.lineWidth=.7;for(let a=0;a<6;a++){const an=a*Math.PI/3,mx=fx+Math.cos(an)*s*.6,my=fy+Math.sin(an)*s*.6;x.beginPath();x.moveTo(mx,my);x.lineTo(mx+Math.cos(an+.6)*s*.35,my+Math.sin(an+.6)*s*.35);x.stroke()}}}x.globalAlpha=1}}
function drawSet(cv,root,t){const R_=root.getBoundingClientRect(),k=cv===$('wxfx')?402/R_.width:1;if(cv!==$('wxfx')){const w=Math.round(R_.width*2),h=Math.round(R_.height*2);if(cv.width!==w||cv.height!==h){cv.width=w;cv.height=h}}
  const x=cv.getContext('2d');x.setTransform(2,0,0,2,0,0);x.clearRect(0,0,cv.width,cv.height);if(RM)return;
  root.querySelectorAll('.wx').forEach(el=>{const b=el.getBoundingClientRect();if(b.bottom<0||b.top>innerHeight)return;drawWord(x,el,{L:(b.left-R_.left)*k,T:(b.top-R_.top)*k,W:b.width*k,H:b.height*k},t)})}
function drawWx(t){drawSet($('wxfx'),$('ph'),t);const G=$('wxG');if(G)drawSet($('wxGc'),G,t)}
$('wxG').innerHTML=WXC.map(([k,c,w,r,cap])=>`<div class="wxc"><div class="wxl">${wxSpan(k,c,w)}${r}</div><div class="wxk">${cap}</div></div>`).join('')+'<canvas id="wxGc" style="position:absolute;inset:0;width:100%;height:100%;pointer-events:none"></canvas>';
