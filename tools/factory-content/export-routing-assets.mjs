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
function makeMerger(g){
  box(g,[0,.051,0],[.88,.1,.88],M.dark);
  box(g,[0,.46,0],[.84,.25,.84],M.dark);
  box(g,[0,.591,0],[.8,.03,.8],M.teal);
  for(const x of [-.32,.32])for(const z of [-.32,.32]){
    box(g,[x,.29,z],[.22,.4,.22],M.steel);
    box(g,[x,.568,z],[.2,.075,.2],M.light);
    cylinder(g,[x,.615,z],.029,.02,M.dark,8);
  }
  for(let side=0;side<4;side++){
    const port=new THREE.Group();port.rotation.y=-side*Math.PI/2;g.add(port);
    box(port,[.31,.145,0],[.38,.15,.39],M.rubber);
    box(port,[.36,.318,0],[.23,.067,.36],side===0?M.amber:M.teal);
    for(const z of [-.192,.192])box(port,[.375,.19,z],[.25,.19,.036],M.dark);
    for(const x of [.37,.46]){
      const roller=cylinder(port,[x,.22,0],.022,.31,M.steel,10);
      roller.rotation.x=Math.PI/2;
    }
  }
  // A recessed-looking routing plate carries one shared junction and one exit.
  box(g,[0,.614,0],[.56,.021,.56],M.dark);
  box(g,[-.105,.626,0],[.31,.007,.043],M.light);
  box(g,[0,.626,0],[.043,.007,.51],M.light);
  box(g,[.096,.626,0],[.19,.007,.052],M.amber);
  const tip=new THREE.Shape();
  tip.moveTo(.255,0);tip.lineTo(.145,.076);tip.lineTo(.145,-.076);tip.closePath();
  const glyph=new THREE.Mesh(new THREE.ShapeGeometry(tip),M.amber);
  glyph.rotation.x=-Math.PI/2;glyph.position.y=.63;g.add(glyph);
}
function make(kind){
  const g=new THREE.Group();g.name=kind==='splitter'?'Three-way distribution hub':'Armored three-inlet collecting chamber';
  if(kind==='merger'){
    makeMerger(g);
    return g;
  }
  // Four feet and a compact cast base stay within the exact 1x1 footprint.
  cylinder(g,[0,.08,0],.34,.13,M.dark,24);
  for(const x of [-.22,.22])for(const z of [-.22,.22])box(g,[x,.055,z],[.14,.11,.14],M.steel);
  for(let side=0;side<4;side++)port(g,side,side!==2);
  cylinder(g,[0,.43,0],.28,.5,M.teal,24);
  cylinder(g,[0,.68,0],.3,.09,M.light,24);
  const dome=new THREE.Mesh(new THREE.SphereGeometry(.24,24,12,0,Math.PI*2,0,Math.PI/2),M.light);
  dome.position.y=.72;dome.scale.y=.52;g.add(dome);
  cylinder(g,[0,.835,0],.085,.055,M.amber,16);
  for(const side of [0,1,3]){
    const a=side*Math.PI/2;
    rod(g,[Math.cos(a)*.1,.75,Math.sin(a)*.1],[Math.cos(a)*.24,.73,Math.sin(a)*.24],.02,M.amber);
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
