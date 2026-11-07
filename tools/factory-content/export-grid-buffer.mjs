// Repository-authored grid buffer. Uses the existing offline asset pipeline.
import fs from 'node:fs/promises';
import crypto from 'node:crypto';
import * as THREE from '../visual-studies/web-topdown-3d/node_modules/three/build/three.module.js';
import {GLTFExporter} from '../visual-studies/web-topdown-3d/node_modules/three/examples/jsm/exporters/GLTFExporter.js';
import {M,box,plinth} from '../visual-studies/web-topdown-3d/parts.mjs';
import {batchStatic} from '../visual-studies/web-topdown-3d/factory.mjs';

globalThis.FileReader=class {
  readAsArrayBuffer(blob){blob.arrayBuffer().then(result=>{this.result=result;this.onloadend?.();});}
};
const out=new URL('../../client/assets/factory/grid-controls/',import.meta.url);
const g=new THREE.Group();
g.name='Grid buffer with three capacitor modules';
plinth(g,1.86,1.86);
box(g,[0,.49,0],[1.57,.38,1.48],M.dark);
for(const x of [-.49,0,.49]){
  box(g,[x,.69,-.08],[.41,.47,1.2],M.teal);
  box(g,[x,.942,-.08],[.42,.048,1.24],M.light);
  box(g,[x,.97,-.08],[.14,.024,.72],M.amber);
  box(g,[x,.67,.54],[.26,.24,.055],M.steel);
}
box(g,[0,.59,.71],[1.27,.22,.2],M.dark);
box(g,[0,.62,.817],[.96,.075,.023],M.teal);
for(const x of [-.75,.75])box(g,[x,.52,0],[.09,.29,1.29],M.steel);
const scene=new THREE.Scene();
scene.add(batchStatic(g));
scene.updateMatrixWorld(true);
const bounds=new THREE.Box3().setFromObject(scene);
if(bounds.min.x < -1 || bounds.max.x > 1 || bounds.min.z < -1 || bounds.max.z > 1 || bounds.min.y < -1e-6)throw Error('Grid buffer exceeds 2×2 footprint');
const bytes=Buffer.from(await new GLTFExporter().parseAsync(scene,{binary:true}));
const hash=data=>crypto.createHash('sha256').update(data).digest('hex');
const sources={};
for(const path of ['tools/factory-content/export-grid-buffer.mjs','tools/visual-studies/web-topdown-3d/parts.mjs','tools/visual-studies/web-topdown-3d/factory.mjs','tools/visual-studies/web-topdown-3d/node_modules/three/package.json']){
  sources[path]=hash(await fs.readFile(new URL('../../'+path,import.meta.url)));
}
await fs.mkdir(out,{recursive:true});
await fs.writeFile(new URL('grid-buffer.glb',out),bytes);
const manifest={source:'Project-authored 2×2 buffer with no item ports',files:{'grid-buffer.glb':{
  bytes:bytes.length,sha256:hash(bytes),footprint:[2,2],bounds:{min:bounds.min.toArray(),max:bounds.max.toArray()}}},sources};
await fs.writeFile(new URL('grid-buffer-manifest.json',out),JSON.stringify(manifest,null,2)+'\n');
console.log('Exported grid buffer:',bytes.length,'bytes');
