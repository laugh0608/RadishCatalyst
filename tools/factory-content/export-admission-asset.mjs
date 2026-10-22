// Repository-authored one-in/one-out mechanical admission gate; no external assets.
import fs from 'node:fs/promises';
import crypto from 'node:crypto';
import * as THREE from '../visual-studies/web-topdown-3d/node_modules/three/build/three.module.js';
import {GLTFExporter} from '../visual-studies/web-topdown-3d/node_modules/three/examples/jsm/exporters/GLTFExporter.js';
import {M,box,cylinder,rod} from '../visual-studies/web-topdown-3d/parts.mjs';
import {batchStatic} from '../visual-studies/web-topdown-3d/factory.mjs';

globalThis.FileReader=class {
  readAsArrayBuffer(blob){blob.arrayBuffer().then(result=>{this.result=result;this.onloadend?.();});}
};
const out=new URL('../../client/assets/factory/admission/',import.meta.url);
const gate=new THREE.Group();gate.name='Single-item mechanical admission gate';
box(gate,[0,.1,0],[.58,.18,.6],M.dark);
for(const side of [0,2]){
  const port=new THREE.Group();port.rotation.y=-side*Math.PI/2;gate.add(port);
  box(port,[.345,.18,0],[.31,.16,.26],M.dark);
  for(const z of [-.15,.15])box(port,[.345,.28,z],[.31,.1,.04],side===0?M.teal:M.light);
  for(const x of [.25,.35,.45]){
    const roller=cylinder(port,[x,.22,0],.025,.23,M.steel,10);roller.rotation.x=Math.PI/2;
  }
  const shape=new THREE.Shape();
  shape.moveTo(-.075,-.035);shape.lineTo(.025,-.035);shape.lineTo(.025,-.07);
  shape.lineTo(.11,0);shape.lineTo(.025,.07);shape.lineTo(.025,.035);shape.lineTo(-.075,.035);shape.closePath();
  const arrow=new THREE.Mesh(new THREE.ShapeGeometry(shape),side===0?M.amber:M.light);
  arrow.rotation.x=-Math.PI/2;arrow.rotation.z=side===0?0:Math.PI;
  arrow.position.set(.35,.271,0);port.add(arrow);
}
// Two upright cheeks and a raised slatted shutter give a distinct narrow silhouette.
for(const z of [-.25,.25]){
  box(gate,[0,.43,z],[.36,.62,.11],M.teal);
  cylinder(gate,[0,.77,z],.07,.12,M.light,16);
  rod(gate,[-.12,.23,z],[.12,.23,z],.022,M.steel);
}
box(gate,[0,.78,0],[.4,.15,.58],M.light);
for(const z of [-.14,-.07,0,.07,.14])box(gate,[0,.51,z],[.065,.4,.027],M.steel);
box(gate,[.03,.87,0],[.19,.035,.22],M.amber);
const scene=new THREE.Scene();scene.add(batchStatic(gate));scene.updateMatrixWorld(true);
const bounds=new THREE.Box3().setFromObject(scene);
if(bounds.min.x<-.50001||bounds.max.x>.50001||bounds.min.z<-.50001||bounds.max.z>.50001||bounds.min.y<0)throw new Error('Admission gate footprint overflow');
await fs.mkdir(out,{recursive:true});
const bytes=Buffer.from(await new GLTFExporter().parseAsync(scene,{binary:true}));
await fs.writeFile(new URL('admission-gate.glb',out),bytes);
let triangles=0,meshes=0;
scene.traverse(o=>{if(o.isMesh){meshes++;triangles+=(o.geometry.index?.count??o.geometry.attributes.position.count)/3;}});
const manifest={source:'Repository-authored mechanical admission gate; offline existing Three.js',files:{'admission-gate.glb':{bytes:bytes.length,sha256:crypto.createHash('sha256').update(bytes).digest('hex'),footprint:[1,1],bounds:{min:bounds.min.toArray(),max:bounds.max.toArray()},meshes,triangles}},sources:{}};
for(const relative of ['tools/factory-content/export-admission-asset.mjs','tools/visual-studies/web-topdown-3d/parts.mjs','tools/visual-studies/web-topdown-3d/factory.mjs','tools/visual-studies/web-topdown-3d/node_modules/three/package.json']){
  manifest.sources[relative]=crypto.createHash('sha256').update(await fs.readFile(new URL(`../../${relative}`,import.meta.url))).digest('hex');
}
await fs.writeFile(new URL('source-manifest.json',out),JSON.stringify(manifest,null,2)+'\n');
console.log(`Exported admission gate: ${meshes} meshes, ${triangles} triangles, ${bytes.length} bytes.`);
