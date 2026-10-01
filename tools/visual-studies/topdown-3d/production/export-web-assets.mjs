// Rebuild only with the existing Web study's pinned Three.js installation.
// These are repository-authored meshes, not downloaded or generated art.
import fs from 'node:fs/promises';
import crypto from 'node:crypto';
import * as THREE from '../../web-topdown-3d/node_modules/three/build/three.module.js';
import {GLTFExporter} from '../../web-topdown-3d/node_modules/three/examples/jsm/exporters/GLTFExporter.js';
import {createYard,createEngineer,batchStatic} from '../../web-topdown-3d/factory.mjs';
import {M,material,box,cylinder,mesh,rod,reactor,compressor,storage} from '../../web-topdown-3d/parts.mjs';
import {createBeltGeometry} from '../../web-topdown-3d/production/scene.mjs';
import {ORE,CATALOG,REFERENCE,port} from '../../web-topdown-3d/production/model.mjs';

// GLTFExporter uses FileReader for binary Blob assembly; Node provides Blob.
globalThis.FileReader=class {
  readAsArrayBuffer(blob){blob.arrayBuffer().then(result=>{this.result=result;this.onloadend?.();});}
  readAsDataURL(blob){blob.arrayBuffer().then(result=>{this.result=`data:${blob.type};base64,${Buffer.from(result).toString('base64')}`;this.onloadend?.();});}
};
const output=new URL('./assets/',import.meta.url);
await fs.mkdir(output,{recursive:true});
const exporter=new GLTFExporter();
const manifest={source:'Existing Web production geometry; no external assets',files:{},sources:{}};
async function save(name,root,batched=true){
  const scene=new THREE.Scene();scene.add(batched?batchStatic(root):root);
  const bytes=Buffer.from(await exporter.parseAsync(scene,{binary:true}));
  await fs.writeFile(new URL(`${name}.glb`,output),bytes);
  manifest.files[`${name}.glb`]={bytes:bytes.length,sha256:crypto.createHash('sha256').update(bytes).digest('hex')};
}
function arrow(parent,x,z,size=.48){
  const g=new THREE.Group();g.position.set(x,.36,z);parent.add(g);
  box(g,[-size*.15,0,0],[size*.75,.025,size*.16],M.light);
  const head=mesh(g,new THREE.ConeGeometry(size*.34,size*.48,3),M.light,[size*.39,0,0]);head.rotation.z=-Math.PI/2;head.rotation.x=Math.PI/2;
}
for(const [type,build,scale] of [['collector',compressor,[.58,.85,.68]],['reactor',reactor,[.94,1,.94]],['storage',storage,[.79,.85,.79]]]){
  const root=new THREE.Group(),model=build(root,0,0,0);model.scale.set(...scale);
  const def=CATALOG[type],e={type,x:0,z:0};
  for(const role of ['input','output']){
    const p=port(e,role);if(!p)continue;
    const socket=new THREE.Group();socket.position.set(p.x+.5-def.w/2+p.dx*.5,0,p.z+.5-def.d/2);root.add(socket);
    const accent=role==='input'?M.cyan:M.amber;
    box(socket,[p.dx*.08,.18,0],[.66,.24,.82],M.dark);
    for(const z of [-.38,.38])box(socket,[0,.52,z],[.22,.62,.1],accent);
    box(socket,[0,.85,0],[.22,.1,.86],accent);
    box(socket,[-p.dx*.14,.52,0],[.08,.48,.66],M.rubber);
    arrow(socket,p.dx*.27,0);
    box(socket,[0,.92,0],[.5,.07,.78],M.dark);
  }
  await save(type,root);
}
const yard=createYard();
for(const x of [-9,-3,3,9]){
  box(yard,[x,1.17,-7.5],[.17,2.34,.17],M.dark);box(yard,[x,.07,-7.5],[.55,.14,.5],M.steel);
  cylinder(yard,[x,2.42,-7.5],.25,.16,M.amber).rotation.z=Math.PI/2;
}
const glass=new THREE.MeshStandardMaterial({color:'#b7ece8',metalness:.12,roughness:.12,transparent:true,opacity:.23,side:THREE.DoubleSide,depthWrite:false});
rod(yard,[-9,2.42,-7.5],[9,2.42,-7.5],.21,glass,24).castShadow=false;
await save('yard',yard);
const ore=new THREE.Group(),crystal=material('#70c8d1',.32,.24);
for(let i=0;i<12;i++){
  const c=mesh(ore,new THREE.ConeGeometry(.18,.38+(i%3)*.12,5),crystal,[ORE.x+.22+(i%4)*.49,.22,ORE.z+.23+Math.floor(i/4)*.65]);c.rotation.z=(i%3-1)*.18;
}
await save('ore',ore);
for(const mask of [2,4,6,8,10,12,14]){
  const inputs=[1,2,3].filter(side=>mask&(1<<side));
  await save(`belt-${mask}`,createBeltGeometry(0,inputs));
}
const cargo=new THREE.Group();mesh(cargo,new THREE.OctahedronGeometry(.19),crystal);await save('cargo',cargo);
const engineerScene=new THREE.Scene(),engineer=createEngineer(engineerScene);
engineer.root.name='Engineer';const body=engineer.root.children[0];body.name='Body';
body.children.filter(x=>x.isGroup).forEach((limb,i)=>{limb.name=`Limb${i}`;});
await save('engineer',engineer.root,false);
for(const file of ['parts.mjs','factory.mjs','production/scene.mjs','production/model.mjs']){
  const bytes=await fs.readFile(new URL(`../../web-topdown-3d/${file}`,import.meta.url));
  manifest.sources[file]=crypto.createHash('sha256').update(bytes).digest('hex');
}
manifest.reference=REFERENCE;
await fs.writeFile(new URL('manifest.json',output),JSON.stringify(manifest,null,2)+'\n');
console.log(`Exported ${Object.keys(manifest.files).length} shared Web mesh assets.`);
