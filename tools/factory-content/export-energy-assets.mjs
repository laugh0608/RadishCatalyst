// Repository-authored E2 generator and cell icon. Uses existing offline Three.js.
import fs from 'node:fs/promises';
import crypto from 'node:crypto';
import * as THREE from '../visual-studies/web-topdown-3d/node_modules/three/build/three.module.js';
import {GLTFExporter} from '../visual-studies/web-topdown-3d/node_modules/three/examples/jsm/exporters/GLTFExporter.js';
import {M,box,cylinder,rod,plinth} from '../visual-studies/web-topdown-3d/parts.mjs';
import {batchStatic} from '../visual-studies/web-topdown-3d/factory.mjs';

globalThis.FileReader=class { readAsArrayBuffer(blob){blob.arrayBuffer().then(result=>{this.result=result;this.onloadend?.();});} };
const out=new URL('../../client/assets/factory/energy/',import.meta.url);
const g=new THREE.Group();g.name='Industrial cell generator';plinth(g,1.86,1.86);
box(g,[0,.57,0],[1.45,.5,1.48],M.teal);
cylinder(g,[.17,1.27,-.14],.46,1.12,M.dark,20);
for(const y of [.78,.98,1.18,1.38,1.58,1.78])cylinder(g,[.17,y,-.14],.5,.085,M.amber,20);
cylinder(g,[.17,1.9,-.14],.3,.17,M.light,16);
for(const x of [-.43,.76])rod(g,[x,.72,-.14],[x,1.95,-.14],.055,M.steel);
box(g,[-.48,1.04,.51],[.44,.55,.42],M.light);
box(g,[-.48,1.1,.74],[.3,.19,.035],M.dark);
box(g,[-.48,1.11,.765],[.2,.08,.018],M.cyan);
for(const x of [-.36,0,.36]){
  cylinder(g,[x,1,-.65],.1,.55,M.teal,12);
  cylinder(g,[x,1.31,-.65],.065,.07,M.steel,10);
}
// Fixed west input at local cell (0,1), matching the model catalog.
box(g,[-.73,.35,.5],[.48,.12,.56],M.dark);
for(const z of [.22,.78])box(g,[-.73,.47,z],[.48,.1,.045],M.cyan);
for(const x of [-.92,-.79,-.66,-.53])cylinder(g,[x,.44,.5],.04,.46,M.steel,10).rotation.x=Math.PI/2;
const arrow=new THREE.Shape();arrow.moveTo(-.12,-.07);arrow.lineTo(.02,-.07);arrow.lineTo(.02,-.13);arrow.lineTo(.17,0);arrow.lineTo(.02,.13);arrow.lineTo(.02,.07);arrow.lineTo(-.12,.07);
const mark=new THREE.Mesh(new THREE.ShapeGeometry(arrow),M.cyan);mark.rotation.x=-Math.PI/2;mark.position.set(-.72,.52,.5);g.add(mark);
const scene=new THREE.Scene();scene.add(batchStatic(g));scene.updateMatrixWorld(true);
const bounds=new THREE.Box3().setFromObject(scene);
if(bounds.min.x < -1 || bounds.max.x > 1 || bounds.min.z < -1 || bounds.max.z > 1 || bounds.min.y < 0)throw Error('Generator footprint overflow');
const bytes=Buffer.from(await new GLTFExporter().parseAsync(scene,{binary:true}));
await fs.mkdir(out,{recursive:true});await fs.writeFile(new URL('cell_generator.glb',out),bytes);
const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 96 96">
<ellipse cx="48" cy="85" rx="29" ry="6" fill="#06191c" opacity=".35"/>
<g stroke="#203c3e" stroke-width="2.5" stroke-linejoin="round"><path d="M37 12h22v11H37Z" fill="#c8d2b8"/><rect x="24" y="22" width="48" height="61" rx="9" fill="#517d78"/><path d="M25 34h46M25 72h46" fill="none" stroke="#edc97e" stroke-width="5"/><path d="m50 35-16 22h12l-3 16 20-26H51l4-12Z" fill="#f0ca78"/><path d="M31 41v22" stroke="#a9ded3" fill="none"/></g>
</svg>
`;
await fs.writeFile(new URL('../../icons/factory_industrial_cell.svg',out),svg);
let meshes=0,triangles=0;scene.traverse(o=>{if(o.isMesh){meshes++;triangles+=(o.geometry.index?.count??o.geometry.attributes.position.count)/3;}});
const hash=data=>crypto.createHash('sha256').update(data).digest('hex');
const manifest={source:'Repository-authored E2 energy assets; offline existing Three.js',files:{'cell_generator.glb':{bytes:bytes.length,sha256:hash(bytes),footprint:[2,2],bounds:{min:bounds.min.toArray(),max:bounds.max.toArray()},meshes,triangles},'../../icons/factory_industrial_cell.svg':{bytes:Buffer.byteLength(svg),sha256:hash(svg),size:[96,96],accent:'#edc97e'}},sources:{}};
for(const path of ['tools/factory-content/export-energy-assets.mjs','tools/visual-studies/web-topdown-3d/parts.mjs','tools/visual-studies/web-topdown-3d/factory.mjs','tools/visual-studies/web-topdown-3d/node_modules/three/package.json'])manifest.sources[path]=hash(await fs.readFile(new URL('../../'+path,import.meta.url)));
await fs.writeFile(new URL('source-manifest.json',out),JSON.stringify(manifest,null,2)+'\n');
console.log(`cell_generator: ${meshes} meshes, ${triangles} triangles, ${bytes.length} bytes`);
