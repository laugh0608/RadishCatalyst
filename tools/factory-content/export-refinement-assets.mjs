// Two inexpensive, repository-authored shape studies. Runtime loads GLB only.
import fs from 'node:fs/promises';
import crypto from 'node:crypto';
import * as THREE from '../visual-studies/web-topdown-3d/node_modules/three/build/three.module.js';
import {GLTFExporter} from '../visual-studies/web-topdown-3d/node_modules/three/examples/jsm/exporters/GLTFExporter.js';
import {RoundedBoxGeometry} from '../visual-studies/web-topdown-3d/node_modules/three/examples/jsm/geometries/RoundedBoxGeometry.js';
import {M,mesh,cylinder,sphere,ring,rod,controlPanel} from '../visual-studies/web-topdown-3d/parts.mjs';
import {batchStatic} from '../visual-studies/web-topdown-3d/factory.mjs';
globalThis.FileReader=class {readAsArrayBuffer(blob){blob.arrayBuffer().then(result=>{this.result=result;this.onloadend?.();});}};
const out=new URL('../../client/assets/factory/refinement/',import.meta.url);
const rounded=(g,at,size,mat,r=.1)=>mesh(g,new RoundedBoxGeometry(...size,2,r),mat,at);
function base(g,w,d){rounded(g,[0,.16,0],[w,.32,d],M.dark);rounded(g,[0,.34,0],[w-.12,.12,d-.12],M.steel,.04);}
function reactor(){
  const g=new THREE.Group();base(g,2.9,2.9);
  cylinder(g,[-.25,1.65,-.2],.8,2.0,M.light,24);
  sphere(g,[-.25,2.65,-.2],[.8,.36,.8],M.light);
  for(const y of [.7,2.45])cylinder(g,[-.25,y,-.2],.84,.16,M.teal,24);
  cylinder(g,[-.25,2.99,-.2],.34,.2,M.dark,16);
  rounded(g,[-.25,3.15,-.2],[.6,.18,.48],M.amber,.07);
  // External process loop and bolted pressure hatch make the chemistry readable.
  rod(g,[.7,.7,-.45],[.7,2.85,-.45],.085,M.steel);
  rod(g,[.7,2.85,-.45],[-.1,2.85,-.45],.085,M.steel);
  rounded(g,[.97,1.14,-.25],[.58,1.38,.9],M.teal,.16);
  for(const y of [.86,1.02,1.18,1.34])rounded(g,[1.28,y,-.25],[.035,.04,.6],M.dark,.01);
  const hatch=cylinder(g,[-.25,1.57,.63],.35,.15,M.steel,24);hatch.rotation.x=Math.PI/2;
  const face=cylinder(g,[-.25,1.57,.72],.26,.08,M.dark,24);face.rotation.x=Math.PI/2;
  ring(g,[-.25,1.57,.8],.2,.032,M.amber);
  rod(g,[-.45,1.57,.8],[-.05,1.57,.8],.025,M.steel);
  rod(g,[-.25,1.37,.8],[-.25,1.77,.8],.025,M.steel);
  controlPanel(g,[.94,1.2,.95]);
  for(const x of [-1.22,1.22]){
    rounded(g,[x,.65,1.0],[.48,.4,.74],x<0?M.teal:M.amber,.07);
    rounded(g,[x,.87,1.0],[.48,.05,.6],M.dark,.02);
  }
  for(const y of [1.1,1.3,1.5,1.7,1.9,2.1])rounded(g,[-.72,y,.58],[.12,.045,.04],M.teal,.01);
  return g;
}
function junction(){
  const g=new THREE.Group();base(g,.9,.9);
  rounded(g,[0,.78,0],[.62,.82,.5],M.light,.12);
  rounded(g,[0,1.63,0],[.17,1.0,.2],M.steel,.05);
  for(const y of [1.93,2.05,2.17])cylinder(g,[0,y,0],.32,.055,M.dark,24);
  sphere(g,[0,2.26,0],[.33,.15,.33],M.teal);
  rounded(g,[0,.86,.26],[.35,.38,.04],M.dark,.035);
  rounded(g,[0,.92,.29],[.22,.055,.025],M.amber,.01);
  for(const x of [-.2,.2])rod(g,[x,.44,-.3],[x,1.18,-.3],.035,M.steel);
  return g;
}
await fs.mkdir(out,{recursive:true});
const manifest={purpose:'Isolated refinement demo; no production asset replacement',files:{},sources:{}};
for(const [name,make,w] of [['reactor',reactor,3],['power-junction',junction,1]]){
  const scene=new THREE.Scene();scene.add(batchStatic(make()));scene.updateMatrixWorld(true);
  const b=new THREE.Box3().setFromObject(scene);
  if(b.min.x < -w/2 || b.max.x>w/2 || b.min.z < -w/2 || b.max.z>w/2)throw new Error(name+' footprint overflow');
  const bytes=Buffer.from(await new GLTFExporter().parseAsync(scene,{binary:true}));
  await fs.writeFile(new URL(name+'.glb',out),bytes);
  let triangles=0,meshes=0;scene.traverse(o=>{if(o.isMesh){meshes++;triangles+=(o.geometry.index?.count??o.geometry.attributes.position.count)/3;}});
  manifest.files[name+'.glb']={bytes:bytes.length,sha256:crypto.createHash('sha256').update(bytes).digest('hex'),meshes,triangles};
}
for(const path of ['tools/factory-content/export-refinement-assets.mjs','tools/visual-studies/web-topdown-3d/parts.mjs','tools/visual-studies/web-topdown-3d/factory.mjs','tools/visual-studies/web-topdown-3d/node_modules/three/package.json']){
  manifest.sources[path]=crypto.createHash('sha256').update(await fs.readFile(new URL('../../'+path,import.meta.url))).digest('hex');
}
await fs.writeFile(new URL('source-manifest.json',out),JSON.stringify(manifest,null,2)+'\n');
console.log(JSON.stringify(manifest.files));
