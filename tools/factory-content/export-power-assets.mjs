// Authored offline meshes. Runtime loads only the exported GLB resources.
import fs from 'node:fs/promises';
import crypto from 'node:crypto';
import * as THREE from '../visual-studies/web-topdown-3d/node_modules/three/build/three.module.js';
import {GLTFExporter} from '../visual-studies/web-topdown-3d/node_modules/three/examples/jsm/exporters/GLTFExporter.js';
import {M,box,cylinder,rod,plinth,controlPanel} from '../visual-studies/web-topdown-3d/parts.mjs';
import {batchStatic} from '../visual-studies/web-topdown-3d/factory.mjs';

globalThis.FileReader=class {
  readAsArrayBuffer(blob){blob.arrayBuffer().then(result=>{this.result=result;this.onloadend?.();});}
};
const out=new URL('../../client/assets/factory/power/',import.meta.url);
const manifest={source:'Repository-authored D1 power candidates; offline Three.js export',files:{},sources:{}};
function socket(g,x,y,z){
  const base=cylinder(g,[x,y,z],.15,.14,M.dark,12);
  base.rotation.x=Math.PI/2;
  const rim=cylinder(g,[x,y,z+.08],.11,.05,M.amber,12);
  rim.rotation.x=Math.PI/2;
  const hole=cylinder(g,[x,y,z+.11],.065,.03,M.rubber,12);
  hole.rotation.x=Math.PI/2;
}
function source(){
  const g=new THREE.Group();g.name='Sealed power source';plinth(g,2.8,2.8);
  // Low horizontal sealed modules distinguish the source from tall process tanks.
  box(g,[0,.65,0],[2.35,.65,2.22],M.dark);
  for(const x of [-.56,.56]){
    const module=cylinder(g,[x,1.15,-.08],.44,1.86,M.light,16);
    module.rotation.x=Math.PI/2;
    for(const z of [-.85,.65]){
      const band=cylinder(g,[x,1.15,z],.47,.13,M.teal,16);band.rotation.x=Math.PI/2;
    }
    for(const z of [-.35,.02,.38])box(g,[x,1.59,z],[.6,.07,.15],M.steel);
    box(g,[x,.77,.93],[.36,.55,.14],M.amber);
  }
  // Visible radiator spine and recessed connector cabinet, without fake live lights.
  box(g,[0,1.33,-1.06],[2.38,1.68,.2],M.teal);
  for(let i=0;i<11;i++)box(g,[-1.05+i*.21,1.39,-1.2],[.07,1.28,.14],M.steel);
  box(g,[0,.96,1.04],[.48,1.15,.35],M.teal);
  socket(g,0,1.04,1.245);
  box(g,[0,1.62,1.02],[.42,.13,.34],M.amber);
  controlPanel(g,[-1.04,.97,.98]);
  for(const x of [-1.23,1.23])rod(g,[x,.42,-.95],[x,.42,.9],.055,M.steel);
  return g;
}
function junction(){
  const g=new THREE.Group();g.name='Power junction';plinth(g,.86,.86);
  box(g,[0,.76,0],[.5,.87,.42],M.teal);
  box(g,[0,1.64,0],[.17,1.18,.18],M.steel);
  box(g,[0,2.17,0],[.9,.16,.3],M.light);
  for(const x of [-.3,0,.3]){
    cylinder(g,[x,2.31,0],.09,.18,M.dark,12);
    cylinder(g,[x,2.42,0],.11,.07,M.amber,12);
  }
  box(g,[0,.8,.23],[.35,.5,.045],M.light);
  socket(g,0,.86,.26);
  box(g,[0,1.22,.245],[.32,.08,.05],M.amber);
  return g;
}
await fs.mkdir(out,{recursive:true});
for(const [name,make,footprint] of [['power-source',source,[3,3]],['power-junction',junction,[1,1]]]){
  const scene=new THREE.Scene();scene.add(batchStatic(make()));
  scene.updateMatrixWorld(true);
  const bounds=new THREE.Box3().setFromObject(scene);
  if(bounds.min.x < -footprint[0]/2 || bounds.max.x > footprint[0]/2 ||
     bounds.min.z < -footprint[1]/2 || bounds.max.z > footprint[1]/2)throw new Error(`${name}: footprint overflow`);
  const bytes=Buffer.from(await new GLTFExporter().parseAsync(scene,{binary:true}));
  await fs.writeFile(new URL(`${name}.glb`,out),bytes);
  let triangles=0,meshes=0;
  scene.traverse(o=>{if(o.isMesh){meshes++;triangles+=(o.geometry.index?.count??o.geometry.attributes.position.count)/3;}});
  manifest.files[`${name}.glb`]={bytes:bytes.length,sha256:crypto.createHash('sha256').update(bytes).digest('hex'),footprint,bounds:{min:bounds.min.toArray(),max:bounds.max.toArray()},meshes,triangles};
}
for(const relative of ['tools/factory-content/export-power-assets.mjs','tools/visual-studies/web-topdown-3d/parts.mjs','tools/visual-studies/web-topdown-3d/factory.mjs','tools/visual-studies/web-topdown-3d/node_modules/three/package.json']){
  const bytes=await fs.readFile(new URL(`../../${relative}`,import.meta.url));
  manifest.sources[relative]=crypto.createHash('sha256').update(bytes).digest('hex');
}
await fs.writeFile(new URL('source-manifest.json',out),JSON.stringify(manifest,null,2)+'\n');
console.log('Exported 2 power GLB candidates with footprint bounds and source hashes.');
