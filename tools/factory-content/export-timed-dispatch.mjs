// Repository-authored timed dispatch gate. Uses the existing offline asset pipeline.
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
const out=new URL('../../client/assets/factory/grid-controls/',import.meta.url);
const g=new THREE.Group();
g.name='Timed dispatch gate with recessed clock dial';
armoredHousing(g,M.teal,.72);
armoredPort(g,0,true);
armoredPort(g,2,false);
outletGlyph(g,0);
function dial(radius,y,height,material){
  const disc=new THREE.Mesh(new THREE.CylinderGeometry(radius,radius,height,16),material);
  disc.position.set(-.045,y,0);
  g.add(disc);
}
dial(.213,.624,.047,M.steel);
dial(.18,.651,.013,M.dark);
for(const [x,z] of [[-.191,0],[.101,0],[-.045,-.146],[-.045,.146]]){
  box(g,[x,.66,z],[.028,.009,.028],M.light);
}
box(g,[-.045,.663,-.049],[.029,.013,.111],M.amber);
box(g,[.012,.666,0],[.123,.013,.029],M.amber);
const scene=new THREE.Scene();
scene.add(batchStatic(g));
scene.updateMatrixWorld(true);
const bounds=new THREE.Box3().setFromObject(scene);
if(bounds.min.x < -.50001 || bounds.max.x > .50001 || bounds.min.z < -.50001 || bounds.max.z > .50001 || bounds.min.y < -1e-6)throw Error('Timed dispatch gate exceeds 1×1 footprint');
const bytes=Buffer.from(await new GLTFExporter().parseAsync(scene,{binary:true}));
const hash=data=>crypto.createHash('sha256').update(data).digest('hex');
const sources={};
for(const path of ['tools/factory-content/export-timed-dispatch.mjs','tools/factory-content/routing-parts.mjs','tools/visual-studies/web-topdown-3d/parts.mjs','tools/visual-studies/web-topdown-3d/factory.mjs','tools/visual-studies/web-topdown-3d/node_modules/three/package.json']){
  sources[path]=hash(await fs.readFile(new URL('../../'+path,import.meta.url)));
}
await fs.mkdir(out,{recursive:true});
await fs.writeFile(new URL('timed-dispatch.glb',out),bytes);
const manifest={source:'Project-authored 1×1 timed dispatch gate with a single item route',files:{'timed-dispatch.glb':{
  bytes:bytes.length,sha256:hash(bytes),footprint:[1,1],bounds:{min:bounds.min.toArray(),max:bounds.max.toArray()}}},sources};
await fs.writeFile(new URL('timed-dispatch-manifest.json',out),JSON.stringify(manifest,null,2)+'\n');
console.log('Exported timed dispatch gate:',bytes.length,'bytes');
