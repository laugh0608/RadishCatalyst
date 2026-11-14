// Repository-authored one-in/one-out mechanical admission gate; no external assets.
import fs from 'node:fs/promises';
import crypto from 'node:crypto';
import * as THREE from '../visual-studies/web-topdown-3d/node_modules/three/build/three.module.js';
import {GLTFExporter} from '../visual-studies/web-topdown-3d/node_modules/three/examples/jsm/exporters/GLTFExporter.js';
import {M,box} from '../visual-studies/web-topdown-3d/parts.mjs';
import {batchStatic} from '../visual-studies/web-topdown-3d/factory.mjs';
import {armoredHousing,armoredPort,outletGlyph} from './routing-parts.mjs';

globalThis.FileReader=class {
  readAsArrayBuffer(blob){blob.arrayBuffer().then(result=>{this.result=result;this.onloadend?.();});}
};
const out=new URL('../../client/assets/factory/admission/',import.meta.url);
const gate=new THREE.Group();gate.name='Armored single-item admission gate';
armoredHousing(gate,M.teal,.70);
armoredPort(gate,0,true);
armoredPort(gate,2,false);
box(gate,[0,.614,0],[.56,.021,.42],M.dark);
box(gate,[-.132,.626,0],[.25,.007,.05],M.light);
box(gate,[.10,.626,0],[.19,.007,.05],M.amber);
outletGlyph(gate,0);
// A pair of grille bars crosses the single route where the gate meters items.
for(const x of [-.035,.035])box(gate,[x,.65,0],[.042,.045,.23],M.steel);
for(const z of [-.14,.14])box(gate,[0,.643,z],[.17,.044,.06],M.light);
const scene=new THREE.Scene();scene.add(batchStatic(gate));scene.updateMatrixWorld(true);
const bounds=new THREE.Box3().setFromObject(scene);
if(bounds.min.x<-.50001||bounds.max.x>.50001||bounds.min.z<-.50001||bounds.max.z>.50001||bounds.min.y<0)throw new Error('Admission gate footprint overflow');
await fs.mkdir(out,{recursive:true});
const bytes=Buffer.from(await new GLTFExporter().parseAsync(scene,{binary:true}));
await fs.writeFile(new URL('admission-gate.glb',out),bytes);
let triangles=0,meshes=0;
scene.traverse(o=>{if(o.isMesh){meshes++;triangles+=(o.geometry.index?.count??o.geometry.attributes.position.count)/3;}});
const manifest={source:'Repository-authored mechanical admission gate; offline existing Three.js',files:{'admission-gate.glb':{bytes:bytes.length,sha256:crypto.createHash('sha256').update(bytes).digest('hex'),footprint:[1,1],bounds:{min:bounds.min.toArray(),max:bounds.max.toArray()},meshes,triangles}},sources:{}};
for(const relative of ['tools/factory-content/export-admission-asset.mjs','tools/factory-content/routing-parts.mjs','tools/visual-studies/web-topdown-3d/parts.mjs','tools/visual-studies/web-topdown-3d/factory.mjs','tools/visual-studies/web-topdown-3d/node_modules/three/package.json']){
  manifest.sources[relative]=crypto.createHash('sha256').update(await fs.readFile(new URL(`../../${relative}`,import.meta.url))).digest('hex');
}
await fs.writeFile(new URL('source-manifest.json',out),JSON.stringify(manifest,null,2)+'\n');
console.log(`Exported admission gate: ${meshes} meshes, ${triangles} triangles, ${bytes.length} bytes.`);
