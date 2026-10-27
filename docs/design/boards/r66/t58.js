// 314: the list's count rolls. Tap rows done, then undo one; header frames; ends whole.
const {chromium}=require('/opt/node22/lib/node_modules/playwright');
const look=process.argv[2]||'paper';
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const p=await b.newPage({viewport:{width:1300,height:1000}});
const errs=[];p.on('pageerror',e=>errs.push(e.message));
await p.goto('file://'+process.cwd()+'/index.html');await p.waitForTimeout(2000);
if(look==='black'){await p.click('#lk-black')}await p.evaluate(()=>{scrollTo(0,0);reset('home');go('list')});await p.waitForTimeout(2500);
const ph=await (await p.$('#phone')).boundingBox();const K=ph.width/402;const clip={x:ph.x+220*K,y:ph.y+50*K,width:182*K,height:40*K};
const hd=()=>p.evaluate(()=>{const e=[...current.children].find(c=>/of 14 left|All done/.test(c.textContent)&&c.children.length<4&&!c.classList.contains('lrow'));return e?JSON.stringify(e.textContent)+' rolling='+e.querySelectorAll('.nr').length:'none'});
const out=['start '+await hd()];
for(let i=0;i<3;i++){const r=await (await p.$$('#phone .lrow:not(.done)'))[0].boundingBox();await p.mouse.click(r.x+30,r.y+r.height/2);await p.waitForTimeout(1500);
 for(const t of [0,100,400]){if(t)await p.waitForTimeout(t===100?100:300);await p.screenshot({path:'L'+look[0]+i+'_'+t+'.png',clip});out.push(i+' +'+t+' '+await hd())}}
const u=await p.$('#phone .receipt button');if(u){await u.click();await p.waitForTimeout(80);await p.screenshot({path:'L'+look[0]+'undo.png',clip});out.push('undo +80 '+await hd());await p.waitForTimeout(800);out.push('undo end '+await hd())}else out.push('no undo button');
console.log(out.join('\n'));console.error(look,JSON.stringify(errs));await b.close()})();
