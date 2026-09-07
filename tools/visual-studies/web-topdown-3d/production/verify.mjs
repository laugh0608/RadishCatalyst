import test from 'node:test';
import assert from 'node:assert/strict';
import {createState,place,advance,salvage,deposit,rotate,materialBalance,inputConnected,feedback,entityAt,INITIAL_KITS,RULES,blockedForActor,moveActor,extendBeltPath,placeBeltPath,beltInputs,DIRS} from './model.mjs';
import {createServer} from '../server.mjs';
import * as THREE from 'three';
import {createBeltGeometry,beltTravelPosition} from './scene.mjs';

function add(s,t,x,z,dir=0){const r=place(s,t,x,z,dir);assert.equal(r.ok,true,r.reason);return r.entity;}
function line(){const s=createState(),collector=add(s,'collector',-8,-1),reactor=add(s,'reactor',-1,-2),storage=add(s,'storage',6,-1);
  for(const x of [-6,-5,-4,-3,-2,2,3,4,5])add(s,'belt',x,0);return {s,collector,reactor,storage};}
function conserved(s){const b=materialBalance(s);assert.equal(b.generated,b.equivalent,JSON.stringify(b));
  for(const [type,count] of Object.entries(INITIAL_KITS))assert.equal(s.kits[type]+s.entities.filter(e=>e.type===type).length,count);
  for(const e of s.entities){if(e.type==='collector')assert.ok(e.buffer>=0&&e.buffer<=50);if(e.type==='reactor')assert.ok(e.input>=0&&e.input<=2&&e.output>=0&&e.output<=1);}
}
test('empty start, footprint, ore and actor checks reject atomically',()=>{
  const s=createState();assert.equal(s.entities.length,0);assert.equal(s.generated,0);
  for(const [type,x,z] of [['collector',-7,-1],['reactor',9,0],['belt',NaN,0],['unknown',0,0]]){const before=structuredClone(s);assert.equal(place(s,type,x,z).ok,false);assert.deepEqual(s,before);}
  const before=structuredClone(s);assert.equal(place(s,'storage',1,1,0,{x:1.2,z:1.2}).ok,false);assert.deepEqual(s,before);
  add(s,'reactor',-1,-2);assert.equal(place(s,'belt',0,0).ok,false);conserved(s);
});
test('full line delivers actual recipe output with material and kit conservation',()=>{
  const {s,reactor,storage}=line();assert.equal(inputConnected(s,reactor),true);
  advance(s,20);assert.equal(storage.catalyst,0);
  advance(s,40);assert.ok(storage.catalyst>=3);assert.equal(s.delivered,storage.catalyst);assert.equal(s.lesson.firstDelivery,true);conserved(s);
});
test('disconnect drains existing buffers, starves, and requires a newly made batch to recover',()=>{
  const {s,reactor,storage}=line();advance(s,45);const cut=entityAt(s,-2,0);
  assert.equal(salvage(s,cut.id).ok,true);assert.equal(s.lesson.cut,true);assert.equal(inputConnected(s,reactor),false);
  advance(s,40);assert.equal(s.lesson.starved,true);assert.equal(feedback(s,reactor).label,'缺少晶体');
  const count=storage.catalyst;advance(s,20);assert.equal(storage.catalyst,count);conserved(s);
  add(s,'belt',-2,0);advance(s,2);assert.equal(s.lesson.recovered,false);
  advance(s,25);assert.equal(s.lesson.recovered,true);assert.ok(storage.catalyst>count);conserved(s);
});
test('blocked output stops new consumption and resumes without losses',()=>{
  const {s,reactor}=line();salvage(s,entityAt(s,2,0).id);advance(s,90);
  assert.equal(reactor.output,1);assert.equal(reactor.processing,false);assert.equal(reactor.input,2);
  const completed=s.completed;advance(s,20);assert.equal(s.completed,completed);conserved(s);
  add(s,'belt',2,0);advance(s,30);assert.ok(s.delivered>0);assert.ok(s.completed>completed);conserved(s);
});
test('wrong device side and opposing belt direction cannot silently connect',()=>{
  const {s,reactor,storage}=line();rotate(s,entityAt(s,-2,0).id);rotate(s,entityAt(s,-2,0).id);
  assert.equal(inputConnected(s,reactor),false);advance(s,90);assert.equal(storage.catalyst,0);assert.equal(reactor.input,0);conserved(s);
  const wrong=createState();const c=add(wrong,'collector',-8,-1),r=add(wrong,'reactor',-1,-2);
  for(const x of [-6,-5,-4,-3,-2])add(wrong,'belt',x,-1);advance(wrong,60);assert.equal(r.input,0);assert.equal(c.buffer,50);conserved(wrong);
});
test('a routed orthogonal corner transports cargo at one cell per second',()=>{
  const s=createState();add(s,'collector',-8,-1);const r=add(s,'reactor',-1,-2);add(s,'storage',6,-1);
  add(s,'belt',-6,0);add(s,'belt',-5,0,1);add(s,'belt',-5,1,0);
  for(const x of [-4,-3])add(s,'belt',x,1);add(s,'belt',-2,1,3);add(s,'belt',-2,0,0);
  for(const x of [2,3,4,5])add(s,'belt',x,0);
  assert.equal(inputConnected(s,r),true);advance(s,70);assert.ok(s.delivered>=3);conserved(s);
});
test('salvage returns in-flight work; full recovery bag leaves entity and cargo untouched',()=>{
  const {s,reactor}=line();advance(s,10);assert.equal(reactor.processing,true);
  const before=materialBalance(s);const r=salvage(s,reactor.id);assert.ok(r.items.crystal>=2);assert.deepEqual(materialBalance(s),before);conserved(s);
  add(s,'reactor',-1,-2);const target=s.entities.find(e=>e.type==='reactor');assert.equal(deposit(s,target.id).ok,true);conserved(s);
  const fixture=createState(),c=add(fixture,'collector',-8,-1);advance(fixture,50);fixture.bag.crystal=200;fixture.generated+=200;
  const unchanged=structuredClone(fixture);assert.equal(salvage(fixture,c.id).ok,false);assert.deepEqual(fixture,unchanged);conserved(fixture);
});
test('two continuously supplied inputs share a merging belt fairly without duplicating cargo',()=>{
  const s=createState(),west=add(s,'belt',-1,0),north=add(s,'belt',0,-1,1);
  add(s,'belt',0,0);const storage=add(s,'storage',1,-1),sent=[0,0];
  for(let tick=0;tick<1000;tick++){
    for(const source of [west,north])if(!source.cargo){source.cargo='crystal';source.progress=0;s.generated++;}
    advance(s,.05);
    for(const [i,source] of [west,north].entries())if(!source.cargo)sent[i]++;
    conserved(s);
  }
  assert.ok(Math.min(...sent)>=10,JSON.stringify(sent));
  assert.ok(Math.abs(sent[0]-sent[1])<=1,JSON.stringify(sent));
  assert.ok(storage.crystal>=20);
});
test('fixed steps produce the same world under different render frame intervals',()=>{
  const a=line().s,b=line().s;advance(a,60);for(let i=0;i<3600;i++)advance(b,1/60);
  assert.deepEqual(a.entities,b.entities);assert.equal(a.generated,b.generated);assert.equal(a.delivered,b.delivered);conserved(a);conserved(b);
  for(const dt of [-1,Infinity,NaN,121])assert.throws(()=>advance(a,dt),RangeError);
});
test('salvage and relay stress retains all material during hundreds of topology edits',()=>{
  const {s}=line();let n=123;
  for(let i=0;i<700;i++){n=(Math.imul(n,1664525)+1013904223)>>>0;const x=[-5,-3,3,4][n%4],e=entityAt(s,x,0);
    if(n%7===0){if(e)salvage(s,e.id);else place(s,'belt',x,0);}
    if(n%11===0){const storage=s.entities.find(e=>e.type==='storage');deposit(s,storage.id);}
    advance(s,(n%10+1)/10);conserved(s);
  }
});
test('engineer collision follows placed and removed footprints while belts remain walkable',()=>{
  const s=createState(),e=add(s,'storage',0,0);assert.equal(blockedForActor(s,1,1),true);
  const a={x:-1,z:1,walk:0,angle:0};for(let i=0;i<90;i++)moveActor(s,a,1,0,.05);assert.ok(a.x<-.28);
  salvage(s,e.id);add(s,'belt',0,0);assert.equal(blockedForActor(s,.5,.5),false);
});
test('play route serves explicit modules and never exposes simulation or dependency files',async t=>{
  const server=createServer();await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));t.after(()=>new Promise(resolve=>server.close(resolve)));
  const root=`http://127.0.0.1:${server.address().port}`;
  for(const path of ['/play/','/play/app.mjs','/play/model.mjs','/play/scene.mjs','/play/style.css','/factory.mjs'])assert.equal((await fetch(root+path)).status,200);
  for(const path of ['/play/verify.mjs','/play/../package.json','/production/model.mjs','/node_modules/three/package.json'])assert.equal((await fetch(root+path)).status,404);
  assert.equal((await fetch(root+'/play/',{method:'POST'})).status,405);
});

test('drag paths fill skipped cells, turn, retrace, and deliver through the actual ports',()=>{
  const s=createState();add(s,'collector',-8,-1);const r=add(s,'reactor',-1,-2);add(s,'storage',6,-1);
  let path=[];
  for(const [x,z] of [[-6,0],[-5,0],[-5,2],[-5,1],[-2,1],[-2,0]]){
    const preview=extendBeltPath(s,path,{x,z});assert.equal(preview.ok,true);path=preview.path;
  }
  // Final short north leg needs an east exit into the adjacent reactor.
  const first=placeBeltPath(s,path);assert.equal(first.ok,true);
  assert.deepEqual(first.entities.map(e=>[e.x,e.z,e.dir]),[[-6,0,0],[-5,0,1],[-5,1,0],[-4,1,0],[-3,1,0],[-2,1,3],[-2,0,3]]);
  assert.equal(rotate(s,first.entities.at(-1).id).ok,true);
  assert.equal(inputConnected(s,r),true);
  const output=extendBeltPath(s,[{x:2,z:0}],{x:5,z:0});assert.equal(placeBeltPath(s,output.path).ok,true);
  advance(s,70);assert.ok(s.delivered>=3);conserved(s);
});
test('drag previews stop at obstacles, bounds and inventory; they never mutate the world',()=>{
  const s=createState();add(s,'storage',0,0);const before=structuredClone(s);
  const blocked=extendBeltPath(s,[{x:-3,z:0}],{x:4,z:0});
  assert.equal(blocked.ok,false);assert.deepEqual(blocked.path,[{x:-3,z:0},{x:-2,z:0},{x:-1,z:0}]);
  assert.deepEqual(s,before);
  assert.equal(extendBeltPath(s,[{x:8,z:4}],{x:30,z:4}).path.length,2);
  s.kits.belt=2;const limited=extendBeltPath(s,[],{x:-5,z:3});
  const full=extendBeltPath(s,limited.path,{x:0,z:3});assert.equal(full.ok,false);assert.equal(full.path.length,2);
  assert.equal(extendBeltPath(s,full.path,{x:-5,z:3}).path.length,1);
});
test('invalid or stale drag commits leave kits, entities and revision completely unchanged',()=>{
  const s=createState();
  for(const path of [[],[{x:0,z:0},{x:2,z:0}],[{x:0,z:0},{x:1,z:1}],[{x:0,z:0},{x:1,z:0},{x:0,z:0}],[{x:NaN,z:0}]]){
    const before=structuredClone(s);assert.equal(placeBeltPath(s,path).ok,false);assert.deepEqual(s,before);
  }
  const path=extendBeltPath(s,[{x:0,z:0}],{x:4,z:0}).path;add(s,'belt',3,0);
  const before=structuredClone(s);assert.equal(placeBeltPath(s,path).ok,false);assert.deepEqual(s,before);
  s.kits.belt=1;const fewer=structuredClone(s);assert.equal(placeBeltPath(s,[{x:0,z:2},{x:1,z:2}]).ok,false);assert.deepEqual(s,fewer);
});

test('all eight corner shapes carry the actual cargo curve on the belt, clear of rails',()=>{
  for(let dir=0;dir<4;dir++)for(const side of [(dir+1)%4,(dir+3)%4]){
    const g=createBeltGeometry(dir,[side]);assert.equal(g.name,'belt-corner');g.updateMatrixWorld(true);
    const surfaces=[],rails=[];g.traverse(o=>{if(o.name==='belt-surface')surfaces.push(o);if(o.name==='belt-rail')rails.push(o);});
    const start=beltTravelPosition(DIRS[side],dir,0),end=beltTravelPosition(DIRS[side],dir,1);
    for(let axis=0;axis<2;axis++){assert.ok(Math.abs(start[axis]-DIRS[side][axis]*.5)<1e-8);assert.ok(Math.abs(end[axis]-DIRS[dir][axis]*.5)<1e-8);}
    for(let i=1;i<20;i++){
      const [x,z]=beltTravelPosition(DIRS[side],dir,i/20),ray=new THREE.Raycaster(new THREE.Vector3(x,2,z),new THREE.Vector3(0,-1,0));
      assert.ok(ray.intersectObjects(surfaces).length>0,`${side} to ${dir} at ${i}`);
      assert.equal(ray.intersectObjects(rails).length,0);
    }
    g.traverse(o=>{if(o.isMesh)o.geometry.dispose();});
  }
});
test('visible belt inputs follow actual device ports, neighbours, rotation and removal',()=>{
  const s=createState();add(s,'collector',-8,-1);const b=add(s,'belt',-6,0,1);
  assert.deepEqual(beltInputs(s,b),[2]);assert.equal(createBeltGeometry(b.dir,beltInputs(s,b)).name,'belt-corner');
  const wrong=add(s,'belt',-6,-1,0);assert.deepEqual(beltInputs(s,b),[2]);
  rotate(s,wrong.id);assert.deepEqual(beltInputs(s,b),[2,3]);
  assert.equal(createBeltGeometry(b.dir,beltInputs(s,b)).name,'belt-junction');
  salvage(s,wrong.id);assert.deepEqual(beltInputs(s,b),[2]);
  salvage(s,s.entities.find(e=>e.type==='collector').id);assert.deepEqual(beltInputs(s,b),[]);
  assert.equal(createBeltGeometry(b.dir,[]).name,'belt-straight');
  const opposing=add(s,'belt',-6,1,3);assert.deepEqual(beltInputs(s,b),[]);
  assert.deepEqual(beltInputs(s,opposing),[]);
});
