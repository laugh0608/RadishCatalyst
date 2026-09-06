import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';
import { M,material,mesh,box,cylinder,sphere,ring,rod,reactor,compressor,storage } from './parts.mjs';
import { MACHINES,SUPPORTS } from './world-model.mjs';

function batchStatic(source) {
  source.updateMatrixWorld(true); const batches=new Map();
  source.traverse(obj=>{
    if(!obj.isMesh) return;
    const key=`${obj.material.uuid}/${obj.castShadow}/${obj.receiveShadow}`;
    if(!batches.has(key))batches.set(key,{mat:obj.material,cast:obj.castShadow,receive:obj.receiveShadow,geometries:[]});
    const geometry=obj.geometry.index?obj.geometry.toNonIndexed():obj.geometry.clone();
    batches.get(key).geometries.push(geometry.applyMatrix4(obj.matrixWorld));
  });
  const result=new THREE.Group();result.name='Batched static factory';
  for(const b of batches.values()) {
    const geo=mergeGeometries(b.geometries,false); if(!geo)throw new Error('Static mesh merge failed');
    const obj=new THREE.Mesh(geo,b.mat);obj.castShadow=b.cast;obj.receiveShadow=b.receive;result.add(obj);
    b.geometries.forEach(g=>g.dispose());
  }
  source.traverse(o=>{if(o.isMesh)o.geometry.dispose();}); return result;
}

export function createFactory(scene) {
  const root=new THREE.Group();
  box(root,[0,-.45,0],[24,.85,18],M.edge);
  const soil=box(root,[0,-.93,0],[100,.12,100],M.soil);soil.castShadow=false;
  const floors=[M.floor,material('#7c877e',.05,.94),material('#738178',.05,.94)];
  for(let x=0;x<12;x++)for(let z=0;z<9;z++) {
    const tile=box(root,[-11+x*2,-.018,-8+z*2],[1.975,.035,1.975],floors[(x*13+z*7)%3]);tile.castShadow=false;
  }
  // Authored geometry at the perimeter makes the slab height readable.
  for(let i=0;i<24;i++) {
    const a=i*2.399, r=14+(i%4)*.7;
    const rock=mesh(root,new THREE.DodecahedronGeometry(.45+(i%3)*.24),M.edge,[Math.cos(a)*r,-.55,Math.sin(a)*r*.75]);
    rock.scale.set(1.3,.65,1);rock.rotation.set(i*.12,i*.71,i*.09);
  }
  for(const z of [-7.5,7.6])box(root,[0,.012,z],[22,.012,.055],M.light).castShadow=false;
  for(let x=-10;x<=10;x+=1)box(root,[x,.014,.55],[.46,.015,.09],M.amber).castShadow=false;
  for(const x of [-3.4,3.4])box(root,[x,.011,3.2],[.045,.012,6.7],M.light).castShadow=false;
  MACHINES.forEach((m,i)=>({reactor,compressor,storage})[m.type](root,m.x,m.z,i));
  for(const x of [-10.7,10.7])for(const z of [-7,0,7]) {
    cylinder(root,[x,.35,z],.11,.7,M.dark);cylinder(root,[x,.75,z],.15,.2,M.amber);
    cylinder(root,[x,.87,z],.11,.05,M.cyan);
  }
  // Low utility main behind the equipment; outside the walking corridor.
  rod(root,[-10,.55,-7.2],[10,.55,-7.2],.12,M.orange);
  for(const x of [-9,-5,0,5,9]) {
    box(root,[x,.22,-7.2],[.22,.44,.5],M.dark);
    const cuff=cylinder(root,[x,.55,-7.2],.19,.12,M.steel);cuff.rotation.z=Math.PI/2;
  }
  for(const [x,z] of SUPPORTS) {
    for(const dz of [-.55,.55]) {
      box(root,[x,.065,z+dz],[.52,.13,.38],M.steel);
      box(root,[x,1.03,z+dz],[.15,1.95,.15],M.dark);
      cylinder(root,[x+.14,.16,z+dz],.04,.07,M.amber,6);
    }
    box(root,[x,2.04,z],[.2,.16,1.3],M.light);
  }
  const glassMaterial=new THREE.MeshPhysicalMaterial({color:'#b7ece8',metalness:.12,roughness:.12,
    transparent:true,opacity:.23,side:THREE.DoubleSide,depthWrite:false,clearcoat:1,clearcoatRoughness:.1});
  const opaqueMaterial=material('#5e9392',.45,.35);
  const glass=new THREE.Group();glass.name='Elevated hollow glass';
  const contents=new THREE.Group();contents.name='Static pipe contents';
  const contentsMaterial=material('#298f9c',.25,.24);
  function span(a,b) {
    const va=new THREE.Vector3(...a),vb=new THREE.Vector3(...b),delta=vb.clone().sub(va),length=delta.length();
    const rotation=new THREE.Quaternion().setFromUnitVectors(new THREE.Vector3(0,1,0),delta.clone().normalize());
    const pipe=mesh(glass,new THREE.CylinderGeometry(.27,.27,length,32,1,true),glassMaterial,va.clone().add(vb).multiplyScalar(.5).toArray());
    pipe.quaternion.copy(rotation);pipe.castShadow=false;pipe.renderOrder=2;
    // Inner wall provides a finite hollow section. No end caps or fake decals.
    const inner=mesh(glass,new THREE.CylinderGeometry(.245,.245,length,32,1,true),glassMaterial,pipe.position.toArray());
    inner.quaternion.copy(rotation);inner.castShadow=false;inner.renderOrder=2;
    // A separate low core is an optional static material sample, not fluid simulation.
    const core=rod(contents,[a[0],a[1]-.09,a[2]],[b[0],b[1]-.09,b[2]],.12,contentsMaterial,16);core.castShadow=false;
    for(const point of [va,vb]) {
      const flange=ring(root,point.toArray(),.285,.065,M.steel);
      flange.quaternion.setFromUnitVectors(new THREE.Vector3(0,0,1),delta.clone().normalize());
      for(let i=0;i<6;i++) {
        const v=new THREE.Vector3(Math.cos(i*Math.PI/3)*.33,0,Math.sin(i*Math.PI/3)*.33).applyQuaternion(rotation).add(point);
        const bolt=cylinder(root,v.toArray(),.035,.14,M.amber,6);bolt.quaternion.copy(rotation);
      }
    }
  }
  for(const [a,b] of [[-7,-4],[-4,0],[0,3.5],[3.5,7],[7,9.5]])span([a,2.4,-1.2],[b,2.4,-1.2]);
  for(const x of [-7,0,7]) {span([x,2.4,-4],[x,2.4,-1.2]);sphere(root,[x,2.4,-1.2],[.3,.3,.3],M.steel);}
  span([9.5,2.4,-1.2],[9.5,2.4,2.5]);span([9.5,2.4,2.5],[9.5,2.4,6]);
  for(const z of [2.5,6]) {span([9.5,2.4,z],[7,2.4,z]);sphere(root,[9.5,2.4,z],[.3,.3,.3],M.steel);}
  sphere(root,[9.5,2.4,-1.2],[.3,.3,.3],M.steel);
  // Short nontransparent utility connections make the front row part of the plant.
  for(const x of [-7,0]) {
    rod(root,[x+1.4,1,3],[x+2.0,1,3],.12,M.orange);
    rod(root,[x+2,1,3],[x+2,1,1.3],.12,M.orange);
  }
  scene.add(batchStatic(root),glass,contents); contents.visible=false;
  return {glass,contents,setGlass(enabled){glass.traverse(o=>{if(o.isMesh){o.material=enabled?glassMaterial:opaqueMaterial;o.castShadow=!enabled;o.renderOrder=enabled?2:0;}});}};
}

export function createEngineer(scene) {
  const root=new THREE.Group();root.name='Engineer';root.scale.setScalar(.9);scene.add(root);
  const body=new THREE.Group();root.add(body);
  sphere(body,[0,1.1,0],[.3,.38,.22],M.teal);
  box(body,[0,1.1,-.24],[.37,.46,.2],M.dark);
  box(body,[0,.9,.035],[.5,.14,.35],M.amber);
  sphere(body,[0,1.53,0],[.31,.29,.28],M.light);
  sphere(body,[0,1.47,.205],[.24,.135,.1],M.dark);
  box(body,[0,1.54,.287],[.29,.055,.04],M.amber);
  const limbs=[];
  for(const side of [-1,1]) {
    const leg=new THREE.Group();leg.position.set(side*.14,.81,0);body.add(leg);
    box(leg,[0,-.3,0],[.2,.59,.23],M.teal);box(leg,[0,-.72,.075],[.24,.18,.4],M.dark);
    box(leg,[0,-.36,.13],[.2,.15,.06],M.light);limbs.push(leg);
    const arm=new THREE.Group();arm.position.set(side*.35,1.26,0);body.add(arm);
    sphere(arm,[0,-.22,0],[.105,.28,.12],M.teal);sphere(arm,[0,-.44,.02],[.11,.12,.12],M.dark);limbs.push(arm);
  }
  return {root,update(s){root.position.set(s.x,0,s.z);root.rotation.y=s.angle;
    const gait=s.moving?Math.sin(s.walk*7)*.48:0;
    limbs.forEach((l,i)=>{l.rotation.x=gait*(i<2?1:-1)*(i%2===0?1:-1);});
    body.position.y=s.moving?Math.abs(Math.sin(s.walk*7))*.035:0;
  }};
}
