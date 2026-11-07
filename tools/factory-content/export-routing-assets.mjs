// Repository-authored single-cell routing machinery; runtime loads exported GLB only.
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
const out=new URL('../../client/assets/factory/routing/',import.meta.url);
const manifest={source:'Repository-authored splitter and merger; offline existing Three.js export',files:{},sources:{}};
function make(kind){
  const splitter=kind==='splitter';
  const g=new THREE.Group();
  g.name=splitter?'Armored three-way distribution hub':'Armored three-inlet collecting chamber';
  armoredHousing(g,splitter?M.steel:M.teal);
  for(let side=0;side<4;side++)armoredPort(g,side,splitter?side!==2:side===0);
  box(g,[0,.614,0],[.56,.021,.56],M.dark);
  box(g,[-.105,.626,0],[.31,.007,.043],M.light);
  box(g,[0,.626,0],[.043,.007,splitter?.37:.51],splitter?M.amber:M.light);
  box(g,[.096,.626,0],[.19,.007,.052],M.amber);
  for(const side of (splitter?[0,1,3]:[0]))outletGlyph(g,side);
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
for(const relative of ['tools/factory-content/export-routing-assets.mjs','tools/factory-content/routing-parts.mjs','tools/visual-studies/web-topdown-3d/parts.mjs','tools/visual-studies/web-topdown-3d/factory.mjs','tools/visual-studies/web-topdown-3d/node_modules/three/package.json']){
  manifest.sources[relative]=crypto.createHash('sha256').update(await fs.readFile(new URL(`../../${relative}`,import.meta.url))).digest('hex');
}
await fs.writeFile(new URL('source-manifest.json',out),JSON.stringify(manifest,null,2)+'\n');
console.log('Exported 2 routing GLB assets with bounds and source hashes.');
