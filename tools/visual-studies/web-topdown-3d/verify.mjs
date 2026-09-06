import test from 'node:test';
import assert from 'node:assert/strict';
import * as THREE from 'three';
import {createFactory,createEngineer} from './factory.mjs';
import {newState,SPOTS,PLAYER,MACHINES,blocked,move,tick} from './world-model.mjs';
import {createServer} from './server.mjs';

test('static factory uses bounded real geometry and hollow glass',()=>{
  const scene=new THREE.Scene(),factory=createFactory(scene),engineer=createEngineer(scene);
  scene.updateMatrixWorld(true);let meshes=0,triangles=0;
  scene.traverse(o=>{if(o.isMesh){meshes++;triangles+=(o.geometry.index?.count??o.geometry.attributes.position.count)/3;}});
  assert.equal(MACHINES.length,7);assert.ok(meshes<100);assert.ok(triangles>30000&&triangles<100000);
  const bounds=new THREE.Box3().setFromObject(engineer.root);
  assert.ok(Math.abs(bounds.min.y)<1e-6);assert.ok(bounds.max.y<=PLAYER.height);
  assert.ok(2.4-.27>bounds.max.y+.3);
  assert.equal(factory.glass.children.length,24);
  for(const pipe of factory.glass.children){assert.equal(pipe.geometry.parameters.openEnded,true);assert.equal(pipe.material.depthWrite,false);}
  factory.setGlass(false);assert.ok(factory.glass.children.every(p=>!p.material.transparent&&p.castShadow));
  factory.setGlass(true);assert.ok(factory.glass.children.every(p=>p.material.transparent&&!p.castShadow));
});
test('device corners, supports and low utility pipe block movement',()=>{
  assert.equal(blocked(1.48,-2.6),true);assert.equal(blocked(-4,-.65),true);assert.equal(blocked(0,-7.2),true);
  for(const spot of Object.values(SPOTS))assert.equal(blocked(spot.x,spot.z),false);
  const s={...newState(),...SPOTS.reactorFront};
  for(let i=0;i<90;i++)move(s,0,-1,.06);
  assert.ok(s.z>=-2.26&&s.z<-1.9);assert.equal(blocked(s.x,s.z),false);
});
test('diagonal speed and rotated camera controls remain consistent',()=>{
  const a=newState(),b=newState();move(a,1,0,.05);move(b,1,1,.05);
  assert.ok(Math.abs(Math.hypot(b.x-SPOTS.entry.x,b.z-SPOTS.entry.z)-(a.x-SPOTS.entry.x))<1e-8);
  const c=newState();tick(c,new Set(['w']),.05,Math.PI/2);assert.ok(c.x<SPOTS.entry.x);assert.ok(Math.abs(c.z-SPOTS.entry.z)<1e-6);
});
test('manual movement cancels click target; idle stops gait',()=>{
  const s=newState();s.target={x:8,z:8};tick(s,new Set(['d']),.05,0);assert.equal(s.target,null);assert.equal(s.moving,true);
  tick(s,new Set(),.05,0);assert.equal(s.moving,false);
  assert.throws(()=>move(s,NaN,0,.01),TypeError);
});
test('engineer turns and changes limb transforms while moving',()=>{
  const scene=new THREE.Scene(),engineer=createEngineer(scene),s=newState();
  engineer.update(s);const before=engineer.root.children[0].children.map(o=>o.rotation.x);
  move(s,1,0,.05);engineer.update(s);
  assert.equal(engineer.root.rotation.y,Math.PI/2);
  assert.notDeepEqual(engineer.root.children[0].children.map(o=>o.rotation.x),before);
});
test('HTTP serves only selected local modules and rejects writes',async t=>{
  const server=createServer();await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
  t.after(()=>new Promise(resolve=>server.close(resolve)));const origin=`http://127.0.0.1:${server.address().port}`;
  for(const route of ['/','/app.mjs','/vendor/three.module.js','/vendor/three.core.js','/addons/environments/RoomEnvironment.js','/addons/utils/BufferGeometryUtils.js'])assert.equal((await fetch(origin+route)).status,200);
  for(const route of ['/.git/config','/package-lock.json','/../AGENTS.md','/addons/../server.mjs'])assert.equal((await fetch(origin+route)).status,404);
  assert.equal((await fetch(origin,{method:'POST'})).status,405);
  const home=await fetch(origin);assert.match(home.headers.get('content-security-policy'),/sha256-/);
});
