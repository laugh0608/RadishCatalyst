// Independent, finite Web study. Core recipe, footprints and ports mirror the
// Godot slice; terminal storage and atomic salvage are explicitly scoped here.
export const RULES=Object.freeze({step:.05,collectTime:1,collectorCapacity:50,batchTime:10,inputCapacity:2,outputCapacity:1,storageCapacity:200,bagCapacity:200});
export const DIRS=Object.freeze([[1,0],[0,1],[-1,0],[0,-1]]);
export const CATALOG=Object.freeze({
  collector:{name:'晶体采集器',w:2,d:2,output:[1,1]},
  reactor:{name:'基础反应器',w:3,d:3,input:[0,2],output:[2,2]},
  storage:{name:'终端仓',w:2,d:2,input:[0,1]},
  belt:{name:'传送带',w:1,d:1},
});
export const AREA=Object.freeze({minX:-10,maxX:10,minZ:-6,maxZ:7});
export const ORE=Object.freeze({x:-8,z:-1});
export const REFERENCE=Object.freeze({collector:{x:-8,z:-1},reactor:{x:-1,z:-2},storage:{x:6,z:-1}});
export const INITIAL_KITS=Object.freeze({collector:1,reactor:1,storage:1,belt:24});
const key=(x,z)=>`${x},${z}`;
const ok=(extra={})=>({ok:true,...extra});
const no=reason=>({ok:false,reason});
export function createState(){return {entities:[],kits:{...INITIAL_KITS},bag:{crystal:0,catalyst:0},nextId:1,revision:0,time:0,remainder:0,generated:0,completed:0,delivered:0,deliveredBatch:0,
  lesson:{firstDelivery:false,cut:false,starved:false,recovered:false,batchAtStarve:0},events:[]};}
export function cells(e){const {w,d}=CATALOG[e.type];return Array.from({length:w*d},(_,i)=>({x:e.x+i%w,z:e.z+Math.floor(i/w)}));}
export function entityAt(s,x,z){return s.entities.find(e=>x>=e.x&&x<e.x+CATALOG[e.type].w&&z>=e.z&&z<e.z+CATALOG[e.type].d);}
export function port(e,role){const offset=CATALOG[e.type][role];if(!offset)return null;return {x:e.x+offset[0],z:e.z+offset[1],dx:role==='input'?-1:1,dz:0};}
export function placement(s,type,x,z,actor=null){
  if(!CATALOG[type]||![x,z].every(Number.isInteger))return no('请选择有效构件和格位');
  if(s.kits[type]<1)return no('构件已用完；可拆回已有构件重新放置');
  const {w,d}=CATALOG[type];
  if(x<AREA.minX||x+w>AREA.maxX||z<AREA.minZ||z+d>AREA.maxZ)return no('超出可建造厂坪');
  if(type==='collector'&&(x!==ORE.x||z!==ORE.z))return no('采集器需要完整覆盖青色晶体矿点');
  for(const c of cells({type,x,z}))if(entityAt(s,c.x,c.z))return no('这里已有设备或传送带');
  if(actor&&type!=='belt'&&actor.x>x-.3&&actor.x<x+w+.3&&actor.z>z-.3&&actor.z<z+d+.3)return no('工程师站在这里，先移开再放置');
  return ok();
}
export function place(s,type,x,z,dir=0,actor=null){
  const valid=placement(s,type,x,z,actor);if(!valid.ok)return valid;
  if(!Number.isInteger(dir)||dir<0||dir>3)return no('传送带方向无效');
  const e={id:s.nextId++,type,x,z,dir:type==='belt'?dir:0};
  if(type==='collector')Object.assign(e,{buffer:0,progress:0});
  if(type==='reactor')Object.assign(e,{input:0,output:0,processing:false,progress:0});
  if(type==='storage')Object.assign(e,{crystal:0,catalyst:0});
  if(type==='belt')Object.assign(e,{cargo:null,progress:0,entry:[-DIRS[dir][0],-DIRS[dir][1]],cursor:0});
  s.entities.push(e);s.kits[type]--;s.revision++;return ok({entity:e});
}
// Preview follows orthogonal pointer segments; it never routes around obstacles.
export function extendBeltPath(s,path,target){
  const next=path.map(c=>({...c}));
  if(!target||![target.x,target.z].every(Number.isInteger))return no('请选择有效格位');
  const back=next.findIndex(c=>c.x===target.x&&c.z===target.z);
  if(back>=0)return ok({path:next.slice(0,back+1)});
  const append=c=>{
    const valid=placement(s,'belt',c.x,c.z);if(!valid.ok)return valid;
    if(next.length>=s.kits.belt)return no('传送带构件不足；松开铺下已预览部分');
    const previous=next.findIndex(p=>p.x===c.x&&p.z===c.z);
    if(previous>=0)next.splice(previous+1);else next.push(c);
    return ok();
  };
  if(!next.length){const result=append({...target});return {...result,path:next};}
  let cursor={...next.at(-1)};
  const axes=Math.abs(target.x-cursor.x)>=Math.abs(target.z-cursor.z)?['x','z']:['z','x'];
  for(const axis of axes)while(cursor[axis]!==target[axis]){
    cursor={...cursor,[axis]:cursor[axis]+Math.sign(target[axis]-cursor[axis])};
    const result=append({...cursor});if(!result.ok)return {...result,path:next};
  }
  return ok({path:next});
}
export function beltPathDirections(path,dir){
  return path.map((cell,i)=>{
    const next=path[i+1];
    if(next)return DIRS.findIndex(([dx,dz])=>next.x-cell.x===dx&&next.z-cell.z===dz);
    if(i>0){const previous=path[i-1];return DIRS.findIndex(([dx,dz])=>cell.x-previous.x===dx&&cell.z-previous.z===dz);}
    return dir;
  });
}
export function placeBeltPath(s,path,dir=0){
  if(!Array.isArray(path)||!path.length)return no('拖动经过空格后再松开铺设');
  if(path.length>s.kits.belt)return no('传送带构件不足');
  const seen=new Set();
  for(const c of path){
    const valid=placement(s,'belt',c?.x,c?.z);if(!valid.ok)return valid;
    if(seen.has(key(c.x,c.z)))return no('路径不能重复经过同一格');seen.add(key(c.x,c.z));
  }
  const directions=beltPathDirections(path,dir);
  if(directions.some(d=>!Number.isInteger(d)||d<0||d>3))return no('路径必须逐格正交相连');
  // All checks precede mutation; this synchronous batch cannot interleave production.
  const entities=path.map((c,i)=>place(s,'belt',c.x,c.z,directions[i]).entity);
  return ok({entities});
}
export function contents(e){
  if(e.type==='collector')return {crystal:e.buffer,catalyst:0};
  if(e.type==='reactor')return {crystal:e.input+(e.processing?2:0),catalyst:e.output};
  if(e.type==='storage')return {crystal:e.crystal,catalyst:e.catalyst};
  return {crystal:e.cargo==='crystal'?1:0,catalyst:e.cargo==='catalyst'?1:0};
}
export function salvage(s,id){
  const e=s.entities.find(e=>e.id===id);if(!e)return no('构件已经不存在');
  const items=contents(e),count=items.crystal+items.catalyst;
  if(s.bag.crystal+s.bag.catalyst+count>RULES.bagCapacity)return no('回收箱已满；先把物品放入设备或终端仓');
  const hadInput=s.entities.some(r=>r.type==='reactor'&&inputConnected(s,r));
  s.bag.crystal+=items.crystal;s.bag.catalyst+=items.catalyst;s.kits[e.type]++;
  s.entities=s.entities.filter(x=>x!==e);s.revision++;
  if(e.type==='belt'&&s.lesson.firstDelivery&&hadInput&&s.entities.some(r=>r.type==='reactor'&&!inputConnected(s,r)))s.lesson.cut=true;
  return ok({items,type:e.type});
}
export function deposit(s,id){
  const e=s.entities.find(e=>e.id===id);if(!e)return no('设备已经不存在');
  let amount=0;
  for(const item of ['crystal','catalyst']){
    let room=0;
    if(e.type==='collector'&&item==='crystal')room=50-e.buffer;
    if(e.type==='reactor'&&item==='crystal')room=2-e.input;
    if(e.type==='storage')room=200-e.crystal-e.catalyst;
    const n=Math.min(s.bag[item],room);if(n<=0)continue;
    s.bag[item]-=n;amount+=n;
    if(e.type==='collector')e.buffer+=n;else if(e.type==='reactor')e.input+=n;else e[item]+=n;
  }
  return amount?ok({amount}):no('没有可投入的物品，或设备缓冲已满');
}
export function rotate(s,id){
  const e=s.entities.find(e=>e.id===id);if(e?.type!=='belt')return no('只有传送带可以转向');
  if(e.cargo)return no('带上有货物；请拆回货物和构件后重新放置');
  e.dir=(e.dir+1)%4;e.entry=[-DIRS[e.dir][0],-DIRS[e.dir][1]];s.revision++;return ok();
}
function index(s){return new Map(s.entities.flatMap(e=>cells(e).map(c=>[key(c.x,c.z),e])));}
function acceptsBelt(target,dx,dz){return target.dir!==((DIRS.findIndex(d=>d[0]===dx&&d[1]===dz)+2)%4);}
export function beltInputs(s,b){
  const inputs=[];
  for(const [side,[dx,dz]] of DIRS.entries()){
    if(side===b.dir)continue;
    const source=entityAt(s,b.x+dx,b.z+dz);if(!source)continue;
    if(source.type==='belt'){
      const [sx,sz]=DIRS[source.dir];
      if(source.x+sx===b.x&&source.z+sz===b.z)inputs.push(side);
    }else{
      const p=port(source,'output');
      if(p&&p.x+p.dx===b.x&&p.z+p.dz===b.z)inputs.push(side);
    }
  }
  return inputs;
}
function sinkAccepts(e,source,item){
  const p=port(e,'input');if(!p||source.x!==p.x-1||source.z!==p.z||source.dir!==0)return false;
  return e.type==='reactor'?item==='crystal'&&e.input<2:e.type==='storage'&&e.crystal+e.catalyst<200;
}
function sendable(e){return e.type==='collector'&&e.buffer>0?'crystal':e.type==='reactor'&&e.output>0?'catalyst':null;}
function event(s,message){s.events.unshift({time:s.time,message});s.events.length=Math.min(5,s.events.length);}
function step(s,dt){
  s.time+=dt;
  for(const e of s.entities){
    if(e.type==='collector'&&e.buffer<50){e.progress+=dt;if(e.progress>=1-1e-9){e.buffer++;s.generated++;e.progress-=1;}}
    if(e.type==='reactor'){
      if(!e.processing&&e.input>=2&&e.output===0){e.input-=2;e.processing=true;e.progress=0;}
      if(e.processing){e.progress+=dt;if(e.progress>=10-1e-9){e.output++;e.outputBatch=++s.completed;e.processing=false;e.progress=0;}}
    }
  }
  const map=index(s),belts=s.entities.filter(e=>e.type==='belt'),occupied=new Set(belts.filter(b=>b.cargo).map(b=>b.id)),contenders=new Map();
  for(const b of belts){
    if(!b.cargo)continue;b.progress=Math.min(1,b.progress+dt);if(b.progress<1-1e-9)continue;
    const [dx,dz]=DIRS[b.dir],next=map.get(key(b.x+dx,b.z+dz));if(!next)continue;
    if(next.type==='belt'){
      if(occupied.has(next.id)||!acceptsBelt(next,dx,dz))continue;
      if(!contenders.has(next))contenders.set(next,[]);contenders.get(next).push(b);
    }else if(sinkAccepts(next,b,b.cargo)){
      if(next.type==='reactor')next.input++;else{next[b.cargo]++;if(b.cargo==='catalyst'){s.delivered++;s.deliveredBatch=Math.max(s.deliveredBatch,b.batch||0);if(!s.lesson.firstDelivery){s.lesson.firstDelivery=true;event(s,'第一件催化剂已通过传送带进入终端仓');}}}
      b.cargo=null;b.progress=0;
    }
  }
  for(const [target,list] of contenders){
    list.sort((a,b)=>a.id-b.id);const winner=list.find(b=>b.id>target.cursor)||list[0];
    target.cargo=winner.cargo;target.batch=winner.batch;target.progress=0;target.entry=[winner.x-target.x,winner.z-target.z];target.cursor=winner.id;
    winner.cargo=null;winner.progress=0;
  }
  for(const e of s.entities){
    const item=sendable(e);if(!item)continue;const p=port(e,'output'),b=map.get(key(p.x+1,p.z));
    if(b?.type!=='belt'||b.cargo||b.dir===2)continue;
    b.cargo=item;b.batch=e.type==='reactor'?e.outputBatch:0;b.progress=0;b.entry=[-1,0];if(e.type==='collector')e.buffer--;else e.output--;
  }
  const r=s.entities.find(e=>e.type==='reactor');
  if(s.lesson.cut&&!s.lesson.starved&&r&&!r.processing&&r.input<2&&r.output===0&&!inputConnected(s,r)){
    s.lesson.starved=true;s.lesson.batchAtStarve=s.completed;event(s,'输入断路：反应器已耗尽供料，等待修复');
  }
  if(s.lesson.starved&&!s.lesson.recovered&&r&&inputConnected(s,r)&&s.deliveredBatch>s.lesson.batchAtStarve){
    s.lesson.recovered=true;event(s,'修复成功：新的催化剂再次到达终端仓');
  }
}
export function advance(s,seconds){
  if(!Number.isFinite(seconds)||seconds<0||seconds>120)throw new RangeError('Advance must be 0–120 seconds');
  s.remainder+=seconds;
  while(s.remainder>=RULES.step-1e-9){step(s,RULES.step);s.remainder-=RULES.step;}
}
export function inputConnected(s,reactor){
  const map=index(s),goal=port(reactor,'input');
  for(const source of s.entities.filter(e=>e.type==='collector')){
    const p=port(source,'output');let b=map.get(key(p.x+1,p.z)),dx=1,dz=0;const visited=new Set();
    while(b?.type==='belt'&&!visited.has(b.id)&&acceptsBelt(b,dx,dz)){
      visited.add(b.id);[dx,dz]=DIRS[b.dir];
      if(b.x+dx===goal.x&&b.z+dz===goal.z&&dx===1)return true;
      b=map.get(key(b.x+dx,b.z+dz));
    }
  }
  return false;
}
export function beltBlocked(s,b){
  if(!b.cargo||b.progress<1-1e-9)return false;
  const [dx,dz]=DIRS[b.dir],n=entityAt(s,b.x+dx,b.z+dz);
  if(!n)return true;if(n.type==='belt')return !!n.cargo||!acceptsBelt(n,dx,dz);
  return !sinkAccepts(n,b,b.cargo);
}
export function feedback(s,e){
  if(e.type==='collector')return e.buffer>=50?{kind:'blocked',label:'缓冲已满'}:{kind:'running',label:'正在采集'};
  if(e.type==='reactor')return e.processing?{kind:'running',label:'加工中'}:e.output?{kind:'blocked',label:'等待出料'}:{kind:'waiting',label:'缺少晶体'};
  if(e.type==='storage')return e.crystal+e.catalyst>=200?{kind:'blocked',label:'仓储已满'}:{kind:'ready',label:'接收物料'};
  return beltBlocked(s,e)?{kind:'blocked',label:'前方堵塞'}:{kind:e.cargo?'running':'ready',label:e.cargo?'运输中':'等待物料'};
}
export function materialBalance(s){let crystal=s.bag.crystal,catalyst=s.bag.catalyst;
  for(const e of s.entities){const c=contents(e);crystal+=c.crystal;catalyst+=c.catalyst;}
  return {generated:s.generated,crystal,catalyst,equivalent:crystal+2*catalyst};
}
export function blockedForActor(s,x,z){
  if(Math.abs(x)>11.4||Math.abs(z)>8.2)return true;
  return s.entities.some(e=>e.type!=='belt'&&Math.hypot(Math.max(e.x-x,0,x-e.x-CATALOG[e.type].w),Math.max(e.z-z,0,z-e.z-CATALOG[e.type].d))<.29);
}
export function moveActor(s,a,dx,dz,dt){
  if(![dx,dz,dt].every(Number.isFinite)||dt<0)throw new TypeError('Invalid movement');
  a.moving=false;const length=Math.hypot(dx,dz);if(!length)return;
  const distance=3.3*Math.min(dt,.06),steps=Math.max(1,Math.ceil(distance/.06));
  for(let i=0;i<steps;i++){
    const x=a.x+dx/length*distance/steps,z=a.z+dz/length*distance/steps;
    if(!blockedForActor(s,x,a.z)){a.x=x;a.moving=true;}
    if(!blockedForActor(s,a.x,z)){a.z=z;a.moving=true;}
  }
  if(a.moving){a.angle=Math.atan2(dx,dz);a.walk+=distance;}
}
