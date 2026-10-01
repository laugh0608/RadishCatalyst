// Builds an independent oracle from the unchanged Web model; Godot replays inputs.
import fs from 'node:fs/promises';
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import * as W from '../../web-topdown-3d/production/model.mjs';
import {beltTravelPosition} from '../../web-topdown-3d/production/scene.mjs';
const output=new URL('../../../runtime-intake/check-runs/godot-production-line/',import.meta.url);
await fs.mkdir(output,{recursive:true});
const manifest=JSON.parse(await fs.readFile(new URL('./assets/manifest.json',import.meta.url),'utf8'));
for(const [name,hash] of Object.entries(manifest.sources)){
  const bytes=await fs.readFile(new URL(`../../web-topdown-3d/${name}`,import.meta.url));
  assert.equal(crypto.createHash('sha256').update(bytes).digest('hex'),hash,`Stale shared mesh source: ${name}`);
}
for(const [name,info] of Object.entries(manifest.files)){
  const bytes=await fs.readFile(new URL(`./assets/${name}`,import.meta.url));
  assert.equal(crypto.createHash('sha256').update(bytes).digest('hex'),info.sha256,`Changed asset: ${name}`);
}
const scenarios=[];
const line=[['collector',-8,-1],['reactor',-1,-2],['storage',6,-1],...[-6,-5,-4,-3,-2,2,3,4,5].map(x=>['belt',x,0])].map(([type,x,z,dir=0])=>({op:'place',type,x,z,dir}));
const at=(s,c)=>W.entityAt(s,c.x,c.z)?.id??-1;
function snapshot(s,actor,result){
  return {entities:s.entities.map(e=>({id:e.id,type:e.type,x:e.x,z:e.z,dir:e.dir,
    ...(e.type==='collector'?{buffer:e.buffer,progress:e.progress}:{}),
    ...(e.type==='reactor'?{input:e.input,output:e.output,processing:e.processing,progress:e.progress,output_batch:e.outputBatch??0}:{}),
    ...(e.type==='storage'?{crystal:e.crystal,catalyst:e.catalyst}:{}),
    ...(e.type==='belt'?{cargo:e.cargo??'',progress:e.progress,entry:e.entry,cursor:e.cursor,batch:e.batch??0,inputs:W.beltInputs(s,e)}:{}),
    feedback:W.feedback(s,e),contents:W.contents(e)})),kits:s.kits,bag:s.bag,next_id:s.nextId,revision:s.revision,
    time:s.time,remainder:s.remainder,generated:s.generated,completed:s.completed,delivered:s.delivered,delivered_batch:s.deliveredBatch,
    lesson:{first_delivery:s.lesson.firstDelivery,cut:s.lesson.cut,starved:s.lesson.starved,recovered:s.lesson.recovered,batch_at_starve:s.lesson.batchAtStarve},
    balance:W.materialBalance(s),connected:s.entities.filter(e=>e.type==='reactor').map(e=>W.inputConnected(s,e)),actor,result};
}
function scenario(name,commands){
  const s=W.createState(),actor={x:-3.5,z:5.7,angle:0,walk:0,moving:false},steps=[];
  for(const c of commands){
    let result={ok:true};
    switch(c.op){
      case 'place':result=W.place(s,c.type,c.x,c.z,c.dir??0,c.actor??null);break;
      case 'advance':W.advance(s,c.seconds);break;
      case 'salvage':result=W.salvage(s,at(s,c));break;
      case 'deposit':result=W.deposit(s,at(s,c));break;
      case 'rotate':result=W.rotate(s,at(s,c));break;
      case 'path':result=W.placeBeltPath(s,c.path.map(([x,z])=>({x,z})),c.dir??0);break;
      case 'preview':{const r=W.extendBeltPath(s,c.path.map(([x,z])=>({x,z})),{x:c.x,z:c.z});result={...r,path:r.path.map(p=>[p.x,p.z])};break;}
      case 'fixture':{
        if(c.bag){s.generated+=c.bag.crystal+2*c.bag.catalyst-s.bag.crystal-2*s.bag.catalyst;s.bag={...c.bag};}
        if(c.entity){const e=W.entityAt(s,c.x,c.z);Object.assign(e,c.entity);if(c.entity.cargo)s.generated+=c.entity.cargo==='catalyst'?2:1;}
        if(c.actor)Object.assign(actor,c.actor);break;
      }
      case 'feed':{for(const [x,z] of c.sources){const e=W.entityAt(s,x,z);if(!e.cargo){e.cargo='crystal';e.progress=0;s.generated++;}}break;}
      case 'move':W.moveActor(s,actor,c.dx,c.dz,c.dt);break;
      default:throw Error(c.op);
    }
    result={ok:result.ok,...(result.reason?{reason:result.reason}:{}),...(result.path?{path:result.path}:{}),...(result.amount?{amount:result.amount}:{}),...(result.items?{items:result.items,type:result.type}:{})};
    steps.push({command:c,expected:structuredClone(snapshot(s,actor,result))});
    assert.equal(W.materialBalance(s).generated,W.materialBalance(s).equivalent,`Web conservation ${name}`);
    for(const [type,count] of Object.entries(W.INITIAL_KITS))assert.equal(s.kits[type]+s.entities.filter(e=>e.type===type).length,count);
  }
  scenarios.push({name,steps});return s;
}
scenario('placement and movement',[{op:'place',type:'collector',x:-7,z:-1},{op:'place',type:'reactor',x:9,z:0},{op:'place',type:'unknown',x:0,z:0},
  {op:'place',type:'storage',x:0,z:0,actor:{x:1,z:1}},{op:'place',type:'storage',x:0,z:0,dir:8},{op:'place',type:'storage',x:0,z:0},
  {op:'place',type:'belt',x:0,z:0},{op:'fixture',actor:{x:-1,z:1}},...Array.from({length:40},()=>({op:'move',dx:1,dz:0,dt:.05})),
  {op:'salvage',x:0,z:0},{op:'place',type:'belt',x:0,z:0},...Array.from({length:30},()=>({op:'move',dx:1,dz:0,dt:.05}))]);
const recovered=scenario('production cut and new batch recovery',[...line,{op:'advance',seconds:20},{op:'advance',seconds:25},{op:'rotate',x:-3,z:0},
  {op:'salvage',x:-2,z:0},{op:'advance',seconds:40},{op:'advance',seconds:20},{op:'place',type:'belt',x:-2,z:0},
  {op:'advance',seconds:2},{op:'advance',seconds:25},{op:'deposit',x:6,z:-1}]);assert.ok(recovered.lesson.recovered);
const blocked=scenario('output backpressure and recovery',[...line,{op:'salvage',x:2,z:0},{op:'advance',seconds:90},{op:'advance',seconds:20},
  {op:'place',type:'belt',x:2,z:0},{op:'advance',seconds:30}]);assert.ok(blocked.delivered>0);
scenario('atomic in-process salvage and capacity',[...line,{op:'advance',seconds:10},{op:'salvage',x:-1,z:-2},
  {op:'place',type:'reactor',x:-1,z:-2},{op:'deposit',x:-1,z:-2},{op:'fixture',bag:{crystal:200,catalyst:0}},
  {op:'advance',seconds:60},{op:'salvage',x:-8,z:-1},{op:'deposit',x:6,z:-1},{op:'advance',seconds:120},{op:'deposit',x:6,z:-1}]);
scenario('drag skips backtracks obstacles atomic commit',[{op:'preview',path:[],x:-6,z:0},
  {op:'preview',path:[[-6,0]],x:-2,z:0},{op:'preview',path:[[-6,0],[-5,0],[-4,0]],x:-5,z:0},
  {op:'preview',path:[[-6,0],[-5,0]],x:-3,z:2},{op:'place',type:'storage',x:-3,z:0},
  {op:'preview',path:[[-6,0]],x:1,z:0},{op:'path',path:[[-6,0],[-4,0]]},
  {op:'path',path:[[-6,0],[-5,0],[-6,0]]},{op:'path',path:[[-6,0],[-5,0],[-4,0],[-3,0]]},
  {op:'path',path:[[-6,0],[-5,0],[-4,0]]},{op:'preview',path:[],x:10,z:0},
  {op:'preview',path:[[-10,-6]],x:9,z:6}]);
scenario('four curved output corners',[...line.slice(0,8),{op:'path',path:[[2,0],[2,1],[2,2],[3,2],[4,2],[4,1],[4,0],[5,0]]},
  {op:'advance',seconds:75},{op:'salvage',x:2,z:1},{op:'advance',seconds:2},{op:'place',type:'belt',x:2,z:1,dir:1},{op:'advance',seconds:30}]);
scenario('opposition and false side ports',[...line,{op:'rotate',x:-2,z:0},{op:'rotate',x:-2,z:0},{op:'advance',seconds:90}]);
scenario('fixed fine steps',[...line,...Array.from({length:120},()=>({op:'advance',seconds:1/60}))]);
scenario('fair merge',[{op:'place',type:'belt',x:-1,z:0},{op:'place',type:'belt',x:0,z:-1,dir:1},
  {op:'place',type:'belt',x:0,z:0},{op:'place',type:'storage',x:1,z:-1},
  ...Array.from({length:600},()=>[{op:'feed',sources:[[-1,0],[0,-1]]},{op:'advance',seconds:.05}]).flat()]);
let n=123;const edits=[...line];
// Commands decide from deterministic topology bookkeeping, not Godot internals.
const occupied=new Set([-5,-3,3,4]);
for(let i=0;i<300;i++){
  n=(Math.imul(n,1664525)+1013904223)>>>0;const x=[-5,-3,3,4][n%4];
  if(n%7===0){edits.push({op:occupied.has(x)?'salvage':'place',type:'belt',x,z:0});if(occupied.has(x))occupied.delete(x);else occupied.add(x);}
  if(n%11===0)edits.push({op:'deposit',x:6,z:-1});edits.push({op:'advance',seconds:(n%10+1)/10});
}
scenario('repeated salvage and relay conservation',edits);
const curves=[];for(let dir=0;dir<4;dir++)for(let entry=0;entry<4;entry++)if(dir!==entry&&(dir+2)%4!==entry){
  for(const progress of [0,.25,.5,.75,1])curves.push({dir,entry,progress,position:beltTravelPosition(W.DIRS[entry],dir,progress)});
}
await fs.writeFile(new URL('parity-fixtures.json',output),JSON.stringify({scenarios,curves})+'\n');
console.log(`Web oracle: ${scenarios.length} scenarios, ${scenarios.reduce((n,s)=>n+s.steps.length,0)} state checkpoints, ${curves.length} curve positions; shared mesh hashes verified.`);
