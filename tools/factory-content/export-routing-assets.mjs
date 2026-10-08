// Repository-authored single-cell routing machinery; runtime loads exported GLB only.
import fs from 'node:fs/promises';
import crypto from 'node:crypto';
import * as THREE from '../visual-studies/web-topdown-3d/node_modules/three/build/three.module.js';
import {GLTFExporter} from '../visual-studies/web-topdown-3d/node_modules/three/examples/jsm/exporters/GLTFExporter.js';
import {M,box,cylinder,rod} from '../visual-studies/web-topdown-3d/parts.mjs';
import {batchStatic} from '../visual-studies/web-topdown-3d/factory.mjs';

globalThis.FileReader=class {
  readAsArrayBuffer(blob){blob.arrayBuffer().then(result=>{this.result=result;this.onloadend?.();});}
};
const out=new URL('../../client/assets/factory/routing/',import.meta.url);
const manifest={source:'Repository-authored splitter and merger; offline existing Three.js export',files:{},sources:{}};
function flowArrow(parent,outgoing){
  const shape=new THREE.Shape();
  shape.moveTo(-.06,-.035);shape.lineTo(.025,-.035);shape.lineTo(.025,-.08);
  shape.lineTo(.11,0);shape.lineTo(.025,.08);shape.lineTo(.025,.035);shape.lineTo(-.06,.035);shape.closePath();
  const mesh=new THREE.Mesh(new THREE.ShapeGeometry(shape),outgoing?M.amber:M.light);
  mesh.rotation.x=-Math.PI/2;mesh.rotation.z=outgoing?0:Math.PI;
  mesh.position.set(.35,.247,0);parent.add(mesh);
}
function port(parent,side,outgoing){
  const g=new THREE.Group();g.rotation.y=-side*Math.PI/2;parent.add(g);
  box(g,[.335,.15,0],[.33,.19,.25],M.dark);
  box(g,[.345,.22,0],[.31,.04,.2],M.rubber);
  for(const z of [-.14,.14]){
    box(g,[.345,.275,z],[.3,.12,.04],outgoing?M.teal:M.light);
    rod(g,[.25,.35,z],[.475,.35,z],.019,M.steel);
  }
  for(const x of [.26,.36,.46]){
    const roller=cylinder(g,[x,.205,0],.03,.22,M.steel,10);roller.rotation.x=Math.PI/2;
  }
  flowArrow(g,outgoing);
}
function make(kind){
  const g=new THREE.Group();g.name=kind==='splitter'?'Three-way distribution hub':'Three-inlet collecting chamber';
  // Four feet and a compact cast base stay within the exact 1x1 footprint.
  cylinder(g,[0,.08,0],.34,.13,M.dark,24);
  for(const x of [-.22,.22])for(const z of [-.22,.22])box(g,[x,.055,z],[.14,.11,.14],M.steel);
  for(let side=0;side<4;side++)port(g,side,kind==='splitter'?side!==2:side===0);
  if(kind==='splitter'){
    cylinder(g,[0,.43,0],.28,.5,M.teal,24);
    cylinder(g,[0,.68,0],.3,.09,M.light,24);
    const dome=new THREE.Mesh(new THREE.SphereGeometry(.24,24,12,0,Math.PI*2,0,Math.PI/2),M.light);
    dome.position.y=.72;dome.scale.y=.52;g.add(dome);
    cylinder(g,[0,.835,0],.085,.055,M.amber,16);
    for(const side of [0,1,3]){
      const a=side*Math.PI/2;
      rod(g,[Math.cos(a)*.1,.75,Math.sin(a)*.1],[Math.cos(a)*.24,.73,Math.sin(a)*.24],.02,M.amber);
    }
  }else{
    // A long chamber narrowing toward the single east outlet differs in silhouette.
    const chamber=new THREE.Mesh(new THREE.CylinderGeometry(.17,.3,.55,24),M.teal);
    chamber.rotation.z=-Math.PI/2;chamber.position.set(0,.48,0);g.add(chamber);
    for(const x of [-.2,0,.19]){
      const band=cylinder(g,[x,.48,0],.3-(x+.275)*.13/.55+.018,.045,x===.19?M.amber:M.light,24);
      band.rotation.z=Math.PI/2;
    }
    box(g,[-.08,.76,0],[.29,.1,.19],M.light);
    for(const z of [-.055,.055])box(g,[-.08,.817,z],[.17,.017,.021],M.dark);
  }
  return g;
}
await fs.mkdir(out,{recursive:true});
for(const name of ['splitter','merger']){
  const scene=new THREE.Scene();scene.add(batchStatic(make(name)));scene.updateMatrixWorld(true);
  const bounds=new THREE.Box3().setFromObject(scene);
  if(bounds.min.x<-.50001||bounds.max.x>.50001||bounds.min.z<-.50001||bounds.max.z>.50001||bounds.min.y<0)throw new Error(`${name}: footprint overflow`);
  const bytes=Buffer.from(await new GLTFExporter().parseAsync(scene,{binary:true}));
  await fs.writeFile(new URL(`${name}.glb`,out),bytes);
  let triangles=0,meshes=0;
  scene.traverse(o=>{if(o.isMesh){meshes++;triangles+=(o.geometry.index?.count??o.geometry.attributes.position.count)/3;}});
  manifest.files[`${name}.glb`]={bytes:bytes.length,sha256:crypto.createHash('sha256').update(bytes).digest('hex'),footprint:[1,1],bounds:{min:bounds.min.toArray(),max:bounds.max.toArray()},meshes,triangles};
}
for(const relative of ['tools/factory-content/export-routing-assets.mjs','tools/visual-studies/web-topdown-3d/parts.mjs','tools/visual-studies/web-topdown-3d/factory.mjs','tools/visual-studies/web-topdown-3d/node_modules/three/package.json']){
  manifest.sources[relative]=crypto.createHash('sha256').update(await fs.readFile(new URL(`../../${relative}`,import.meta.url))).digest('hex');
}
await fs.writeFile(new URL('source-manifest.json',out),JSON.stringify(manifest,null,2)+'\n');
console.log('Exported 2 routing GLB assets with bounds and source hashes.');
