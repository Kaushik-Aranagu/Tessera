const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium'});const pg=await b.newPage({viewport:{width:402,height:874}});const errs=[];pg.on('pageerror',e=>errs.push(e.message));
await pg.goto('file://'+__dirname+'/index.html');await pg.waitForTimeout(600);
const cls=s=>pg.evaluate(s=>{const e=document.querySelector(s);return e?e.className:'none'},s);
// cook: set out, then tap again: the strike pulls back before the line clears
await pg.evaluate(()=>go('cook'));await pg.waitForTimeout(900);
let t=await pg.evaluate(()=>{const e=document.querySelector('[data-a="ig0"]').getBoundingClientRect();return [e.x+30,e.y+e.height/2]});
await pg.mouse.click(t[0],t[1]);await pg.waitForTimeout(600);
await pg.mouse.click(t[0],t[1]);await pg.waitForTimeout(120);
const mid=await cls('[data-a="ig0"]');
const ang=await pg.evaluate(()=>{const a=document.querySelector('[data-a="ig0"]').getAnimations({subtree:true}).find(x=>x.animationName==='tkunstrike');if(!a)return 'none';a.pause();a.currentTime=130;return getComputedStyle(document.querySelector('[data-a="ig0"]'),'::after').transform+' origin '+getComputedStyle(document.querySelector('[data-a="ig0"]'),'::after').transformOrigin});
await pg.screenshot({path:'UN1.png'});
await pg.evaluate(()=>document.getAnimations().forEach(a=>a.play()));
await pg.waitForTimeout(500);const end=await cls('[data-a="ig0"]');
console.log('cook mid:',mid,'|',ang,'| end:',end);
// shop: got, then Undo on the receipt
await pg.evaluate(()=>go('shop'));await pg.waitForTimeout(900);
await pg.evaluate(()=>__sh.got());await pg.waitForTimeout(500);
const row=await pg.evaluate(()=>{const r=document.querySelector('.tl.got');return r&&r.dataset.a});
const u=await pg.evaluate(()=>{const b=[...document.querySelectorAll('.receipt button')].find(x=>x.offsetParent);const r=b.getBoundingClientRect();return [r.x+r.width/2,r.y+r.height/2]});
await pg.mouse.click(u[0],u[1]);await pg.waitForTimeout(100);
const smid=await cls('[data-a="'+row+'"]');await pg.waitForTimeout(400);const send=await cls('[data-a="'+row+'"]');
console.log('shop',row,'mid:',smid,'| end:',send,errs);await b.close()})();
