const cirS=(c,r)=>`<circle cx="${c.x.toFixed(1)}" cy="${c.y.toFixed(1)}" r="${r}"/>`;
function capS(a,ra,b,rb){const dx=b.x-a.x,dy=b.y-a.y,d=Math.hypot(dx,dy)||1,nx=-dy/d,ny=dx/d;
 const q=[[a.x+nx*ra,a.y+ny*ra],[b.x+nx*rb,b.y+ny*rb],[b.x-nx*rb,b.y-ny*rb],[a.x-nx*ra,a.y-ny*ra]].map(p=>p[0].toFixed(1)+','+p[1].toFixed(1)).join(' ');
 return `<polygon points="${q}"/>${cirS(a,ra)}${cirS(b,rb)}`}
function sil(shapes){return `<g fill="${INK}" stroke="${INK}" stroke-width="4.6" stroke-linejoin="round">${shapes}</g><g fill="${PAN}" stroke="none">${shapes}</g>`}
function frame(t){const {h,e}=state(t);
 const wx=204-8*h,wy=(S.y-101)+h*(113-(S.y-101)),W={x:wx,y:wy};
 const dx=W.x-S.x,dy=W.y-S.y,d=Math.hypot(dx,dy),a=(L1*L1-L2*L2+d*d)/(2*d),hh=Math.sqrt(Math.max(L1*L1-a*a,0));
 const P={x:S.x+a*dx/d,y:S.y+a*dy/d};
 const c1={x:P.x+(-dy)/d*hh,y:P.y+(dx)/d*hh},c2={x:P.x-(-dy)/d*hh,y:P.y-(dx)/d*hh};
 const El=c1.x<c2.x?c1:c2;
 const pa=.30+.55*e,sa=.2+.38*e,pt=(A,B,k)=>({x:A.x+(B.x-A.x)*k,y:A.y+(B.y-A.y)*k});
 const hip={x:112,y:143},knee={x:60,y:114},ank={x:46,y:190};
 const legs=sil(capS(hip,15,knee,9.5)+capS(knee,9.5,ank,6)+cirS({x:62,y:134},10)+capS({x:46,y:192},6,{x:70,y:194},5));
 const torso=sil(capS(hip,14,{x:146,y:143},12)+capS({x:146,y:143},12,{x:184,y:141},17.5)+capS({x:184,y:141},17.5,{x:204,y:141},12)+cirS({x:113,y:147},15)+capS({x:206,y:140},9,{x:226,y:138},7)+cirS({x:240,y:137},14.5)+cirS({x:241,y:122},3.4));
 const hand=pt(El,W,1);
 const arm=sil(cirS({x:S.x,y:S.y-2},12)+capS(S,9.8,El,7.6)+capS(El,7.6,W,5.4)+cirS(pt(El,W,.25),8.4));
 const hair=`<path d="M236 123C249 122 257 131 255 143C251 139 247 134 241 132Z" fill="${INK}"/>`;
 const lines=`<g fill="none" stroke="${INK}" stroke-opacity=".38" stroke-width="1.3" stroke-linecap="round"><path d="M176 143C184 149 196 148 204 143"/><path d="M98 136C84 130 74 124 66 118"/><path d="M52 118C56 124 58 128 56 132"/><path d="M236 138C238 140 241 140 243 138"/><path d="M148 138V146"/></g>`;
 const hook=`<rect x="283" y="94" width="14" height="6" rx="2" fill="${PAN}" stroke="${INK}" stroke-width="2"/>`;
 return `<defs><linearGradient id="fl" x1="0" x2="0" y1="0" y2="1"><stop offset="0" stop-color="#EFEEEA"/><stop offset="1" stop-color="#E4E2DC"/></linearGradient></defs><rect x="0" y="10" width="342" height="200" fill="url(#fl)"/>
 <path d="M0 200H342" stroke="${INK}" stroke-opacity=".4" stroke-width="1.5"/><ellipse cx="160" cy="201" rx="100" ry="4" fill="${INK}" fill-opacity=".1"/>
 <rect x="296" y="52" width="9" height="148" rx="2" fill="${PAN}" stroke="${INK}" stroke-width="2.2"/><rect x="284" y="196" width="34" height="5" rx="2" fill="${INK}"/>${hook}
 <rect x="102" y="170" width="7" height="30" fill="${PAN}" stroke="${INK}" stroke-width="2"/><rect x="214" y="170" width="7" height="30" fill="${PAN}" stroke="${INK}" stroke-width="2"/><rect x="92" y="197" width="28" height="4" rx="2" fill="${INK}"/><rect x="204" y="197" width="28" height="4" rx="2" fill="${INK}"/>
 <circle cx="204" cy="${S.y-101}" r="19" fill="none" stroke="${INK}" stroke-opacity=".22" stroke-width="1.4" stroke-dasharray="3 4"/><circle cx="196" cy="113" r="19" fill="none" stroke="${INK}" stroke-opacity=".22" stroke-width="1.4" stroke-dasharray="3 4"/>
 ${legs}${torso}${hair}
 <rect x="84" y="156" width="154" height="15" rx="7" fill="${PAN}" stroke="${INK}" stroke-width="2.2"/><path d="M96 163H226" stroke="${INK}" stroke-opacity=".3" stroke-width="1.2"/>
 <ellipse cx="${S.x-12}" cy="${S.y-6}" rx="21" ry="10" fill="rgb(${TNT})" fill-opacity="${pa}"/>
 ${lines}
 <circle cx="${W.x-3}" cy="${W.y-2}" r="19" fill="${INK}" fill-opacity=".35"/>
 ${arm}
 <path d="M${S.x} ${S.y}L${El.x} ${El.y}" stroke="rgb(${TNT})" stroke-opacity="${sa}" stroke-width="9" stroke-linecap="round"/>
 <circle cx="${S.x}" cy="${S.y-2}" r="9" fill="rgb(${TNT})" fill-opacity="${sa}"/>
 <circle cx="${W.x}" cy="${W.y}" r="19.5" fill="${INK}"/><circle cx="${W.x}" cy="${W.y}" r="13.5" fill="none" stroke="${PAN}" stroke-opacity=".5" stroke-width="1.4"/><circle cx="${W.x}" cy="${W.y}" r="6" fill="${PAN}"/><circle cx="${W.x}" cy="${W.y}" r="2.4" fill="${INK}"/>
 <circle cx="${W.x}" cy="${W.y+1}" r="6.8" fill="${PAN}" stroke="${INK}" stroke-width="2.2"/>`}
