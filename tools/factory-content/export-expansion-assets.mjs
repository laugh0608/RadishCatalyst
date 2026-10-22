// E1 repository-authored imported meshes; runs offline with the existing Three.js.
import fs from 'node:fs/promises';
import crypto from 'node:crypto';
import * as THREE from '../visual-studies/web-topdown-3d/node_modules/three/build/three.module.js';
import {GLTFExporter} from '../visual-studies/web-topdown-3d/node_modules/three/examples/jsm/exporters/GLTFExporter.js';
import {M,box,cylinder,rod,ring,plinth,mesh,material} from '../visual-studies/web-topdown-3d/parts.mjs';
import {batchStatic} from '../visual-studies/web-topdown-3d/factory.mjs';

globalThis.FileReader=class {
  readAsArrayBuffer(blob){blob.arrayBuffer().then(result=>{this.result=result;this.onloadend?.();});}
};
const out=new URL('../../client/assets/factory/expansion/',import.meta.url);
const rust=material('#b77b57',.3,.7), coal=material('#535b64',.3,.6), slag=material('#8d9272',.15,.86);
function dock(g,w,d,cell,normal,output=false,byproduct=false){
  const p=new THREE.Group();
  p.position.set(cell[0]+.5-w/2,.33,cell[1]+.5-d/2);
  p.rotation.y=normal[0]===1?0:normal[0]===-1?Math.PI:Math.PI/2;
  g.add(p);
  box(p,[.26,0,0],[.48,.12,.56],M.dark);
  for(const z of [-.28,.28])box(p,[.26,.12,z],[.48,.12,.05],output?(byproduct?slag:M.amber):M.cyan);
  for(const x of [.1,.23,.36,.46]){const r=cylinder(p,[x,.09,0],.04,.46,M.steel,10);r.rotation.x=Math.PI/2;}
  const shape=new THREE.Shape();
  shape.moveTo(-.13,-.07);shape.lineTo(.02,-.07);shape.lineTo(.02,-.13);shape.lineTo(.17,0);shape.lineTo(.02,.13);shape.lineTo(.02,.07);shape.lineTo(-.13,.07);shape.closePath();
  const arrow=new THREE.Mesh(new THREE.ShapeGeometry(shape),output?M.amber:M.cyan);
  arrow.rotation.x=-Math.PI/2;arrow.rotation.z=output?0:Math.PI;arrow.position.set(.22,.16,0);p.add(arrow);
}
function panel(g,x,y,z){
  box(g,[x,y,z],[.36,.43,.08],M.light);box(g,[x,y+.06,z+.045],[.25,.17,.025],M.dark);
  box(g,[x,y+.07,z+.06],[.19,.09,.02],M.cyan);cylinder(g,[x,y+.26,z],.045,.055,M.amber,8);
}
function crusher(){
  const g=new THREE.Group();g.name='Twin-roll crusher';plinth(g,1.86,1.86);
  box(g,[0,.67,-.08],[1.44,.68,1.22],M.teal);
  box(g,[0,1.06,-.08],[1.5,.14,1.3],M.light);
  box(g,[0,1.15,-.08],[1.08,.14,.91],M.dark);
  for(const x of [-.25,.25]){
    const roll=cylinder(g,[x,1.29,-.08],.2,.86,M.steel,12);roll.rotation.x=Math.PI/2;
    for(const z of [-.4,-.2,0,.2]){const teeth=ring(g,[x,1.29,z],.21,.035,M.dark);}
  }
  for(const x of [-.65,.65])box(g,[x,1.39,-.08],[.12,.62,1.32],M.light).rotation.z=-x*.45;
  box(g,[0,1.46,-.69],[1.44,.66,.13],M.teal);
  cylinder(g,[.58,.7,.58],.22,.43,M.amber,12).rotation.x=Math.PI/2;
  panel(g,-.45,.72,.62);
  dock(g,2,2,[0,1],[-1,0]);dock(g,2,2,[1,1],[1,0],true);
  return g;
}
function refinery(){
  const g=new THREE.Group();g.name='Dual-output refining furnace';plinth(g,1.86,2.86);
  box(g,[0,.65,0],[1.46,.68,2.28],M.dark);
  cylinder(g,[0,1.45,-.32],.67,1.58,M.teal,20);
  for(const y of [.77,1.96,2.2])cylinder(g,[0,y,-.32],.72,.12,M.steel,20);
  cylinder(g,[0,2.3,-.32],.5,.21,M.light,16);
  cylinder(g,[0,2.54,-.32],.22,.32,M.amber,12);
  for(const x of [-.48,.48])rod(g,[x,.72,-.88],[x,2.04,-.88],.06,M.light);
  box(g,[0,1.05,.77],[1.24,.85,.72],M.light);
  const door=cylinder(g,[0,1.07,1.15],.33,.08,M.dark,16);door.rotation.x=Math.PI/2;
  ring(g,[0,1.07,1.2],.25,.05,M.amber);
  for(const x of [-.14,0,.14])box(g,[x,1.07,1.21],[.05,.29,.025],M.orange);
  panel(g,.61,1.6,.82);
  dock(g,2,3,[0,0],[-1,0]);dock(g,2,3,[0,2],[-1,0]);
  dock(g,2,3,[1,0],[1,0],true);dock(g,2,3,[1,2],[1,0],true,true);
  return g;
}
function assembler(){
  const g=new THREE.Group();g.name='Gantry construction pack assembler';plinth(g,2.86,1.86);
  box(g,[0,.53,0],[2.4,.38,1.4],M.teal);box(g,[0,.78,0],[2.3,.12,1.3],M.steel);
  for(const x of [-1.04,1.04])box(g,[x,1.37,-.17],[.2,1.38,.92],M.light);
  box(g,[0,2.04,-.17],[2.3,.26,.96],M.teal);
  for(const x of [-.64,-.32,0,.32,.64])box(g,[x,2.19,-.17],[.13,.045,.64],M.dark);
  rod(g,[-.8,1.79,.1],[.8,1.79,.1],.065,M.steel);
  box(g,[0,1.62,.1],[.56,.34,.46],M.amber);rod(g,[0,1.5,.1],[0,1.19,.1],.07,M.steel);
  box(g,[0,1.03,.12],[.55,.4,.46],M.light);
  for(const x of [-.16,.16])box(g,[x,1.03,.36],[.055,.4,.025],M.teal);
  panel(g,1.12,1.16,.61);
  dock(g,3,2,[0,0],[-1,0]);dock(g,3,2,[0,1],[-1,0]);dock(g,3,2,[1,0],[0,-1]);dock(g,3,2,[2,1],[1,0],true);
  return g;
}
function ore(kind){
  const g=new THREE.Group();g.name=kind+' mineral site';
  cylinder(g,[0,.025,0],.92,.05,M.soil,12);
  const locations=[[-.42,.24,-.32,.32],[.24,.35,-.17,.43],[-.12,.25,.37,.33],[.53,.2,.4,.24]];
  for(const [x,y,z,r] of locations){
    const geo=kind==='iron'?new THREE.DodecahedronGeometry(r,0):new THREE.IcosahedronGeometry(r,0);
    const rock=mesh(g,geo,kind==='iron'?rust:coal,[x,y,z]);rock.scale.set(1,.8,1);
    for(const k of [-1,1])box(g,[x+k*r*.3,y+r*.48,z],[r*.18,.025,r*.8],kind==='iron'?M.amber:M.steel).rotation.y=k*.5;
  }
  return g;
}
await fs.mkdir(out,{recursive:true});
const manifest={source:'Repository-authored E1 machinery and mineral sites; offline existing Three.js',files:{},sources:{}};
for(const [name,w,d,build] of [['crusher',2,2,crusher],['refinery',2,3,refinery],['assembler',3,2,assembler],['iron-ore',2,2,()=>ore('iron')],['carbon-ore',2,2,()=>ore('carbon')]]){
  const scene=new THREE.Scene();scene.add(batchStatic(build()));scene.updateMatrixWorld(true);
  const bounds=new THREE.Box3().setFromObject(scene);
  if(bounds.min.x < -w/2-1e-5 || bounds.max.x > w/2+1e-5 || bounds.min.z < -d/2-1e-5 || bounds.max.z > d/2+1e-5 || bounds.min.y < -1e-5)throw Error(name+' footprint overflow '+JSON.stringify(bounds));
  const bytes=Buffer.from(await new GLTFExporter().parseAsync(scene,{binary:true}));await fs.writeFile(new URL(name+'.glb',out),bytes);
  let meshes=0,triangles=0;scene.traverse(o=>{if(o.isMesh){meshes++;triangles+=(o.geometry.index?.count??o.geometry.attributes.position.count)/3;}});
  manifest.files[name+'.glb']={bytes:bytes.length,sha256:crypto.createHash('sha256').update(bytes).digest('hex'),footprint:[w,d],bounds:{min:bounds.min.toArray(),max:bounds.max.toArray()},meshes,triangles};
  console.log(`${name}: ${meshes} meshes, ${triangles} triangles, ${bytes.length} bytes`);
}
const icons={
  iron_ore:['#b77b57','<path d="m19 59 7-28 25-14 26 17 7 30-25 17-29-5Z" fill="#b77b57"/><path d="m26 31 23 14 28-11M49 45l10 36M19 59l30-14" fill="none"/><path d="m35 35 10-6 11 6-10 6Z" fill="#edc97e"/><path d="m60 48 13-5 4 12-12 6Z" fill="#cbd0ba"/>'],
  carbon_ore:['#87909c','<path d="m14 64 12-33 24-14 25 16 9 31-24 17-32-4Z" fill="#535b64"/><path d="m26 31 24 17 25-15M50 48l10 33M14 64l36-16" fill="none" stroke="#87909c"/><path d="m31 35 15-9 9 5-16 9Zm29 22 13-8 4 6-15 10Z" fill="#b0bac3" stroke="none"/>'],
  iron_powder:['#d39b79','<path d="M31 18h34l-5 15 15 15 4 32c-16 7-46 7-62 0l4-32 15-15Z" fill="#c9d0bb"/><path d="M29 48h38v28H29Z" fill="#b77b57"/><path d="m48 51 13 20H35Z" fill="#e6b48b"/><path d="M32 28h32M28 39h40" fill="none"/><circle cx="41" cy="65" r="2" fill="#b77b57" stroke="none"/><circle cx="49" cy="61" r="2" fill="#b77b57" stroke="none"/><circle cx="53" cy="68" r="2" fill="#b77b57" stroke="none"/>'],
  carbon_powder:['#a1abb4','<path d="M31 18h34l-5 15 15 15 4 32c-16 7-46 7-62 0l4-32 15-15Z" fill="#c9d0bb"/><path d="M29 48h38v28H29Z" fill="#535b64"/><path d="m48 51 13 20H35Z" fill="#99a6af"/><path d="M32 28h32M28 39h40" fill="none"/><circle cx="41" cy="65" r="2" fill="#535b64" stroke="none"/><circle cx="49" cy="61" r="2" fill="#535b64" stroke="none"/><circle cx="53" cy="68" r="2" fill="#535b64" stroke="none"/>'],
  metal_plate:['#a5cfda','<path d="m15 63 46-22 22 14v12L37 89 15 75Z" fill="#64838c"/><path d="m15 63 46-22 22 14-46 22Z" fill="#afc7cd"/><path d="m15 46 46-22 22 14v12L37 72 15 58Z" fill="#64838c"/><path d="m15 46 46-22 22 14-46 22Z" fill="#d3e1d5"/><path d="m29 45 34-16M37 60v12" stroke="#f0f2dc" fill="none"/>'],
  mineral_slag:['#a9ae88','<path d="m16 66 10-19 23-7 5 32-17 10Z" fill="#82886b"/><path d="m42 52 5-28 19-8 17 24-7 22-19 8Z" fill="#a4a784"/><path d="m47 24 18 19 18-3M65 43l-8 27" fill="none"/><path d="m28 47 9 15 12-22" fill="none"/><circle cx="63" cy="33" r="3" fill="#4f6153"/><circle cx="60" cy="54" r="4" fill="#4f6153"/><circle cx="32" cy="68" r="4" fill="#4f6153"/>'],
  porous_carrier:['#d8c999','<path d="M21 34h54v38c0 17-54 17-54 0Z" fill="#ad9f73"/><ellipse cx="48" cy="34" rx="27" ry="16" fill="#e3d8b0"/><ellipse cx="35" cy="29" rx="5" ry="3" fill="#4b655e"/><ellipse cx="51" cy="26" rx="5" ry="3" fill="#4b655e"/><ellipse cx="64" cy="34" rx="5" ry="3" fill="#4b655e"/><ellipse cx="47" cy="39" rx="5" ry="3" fill="#4b655e"/><path d="M30 53v14M43 58v17M57 58v17M69 51v14" fill="none" stroke="#526d63" stroke-width="4"/>'],
  construction_pack:['#7cd7c6','<path d="m17 33 32-15 30 15v43L48 90 17 75Z" fill="#517d78"/><path d="m17 33 31 16 31-16-30-15Z" fill="#c8d2b8"/><path d="M48 49v41M17 33l31 16 31-16" fill="none"/><path d="m31 26 31 15v41l-10 4V46L22 31Z" fill="#e0b361"/><path d="m23 49 16 8v19l-16-8Z" fill="#c6e8dc"/><path d="m27 55 8 4v10l-8-4Z" fill="#377b7c" stroke="none"/>'],
};
for(const [name,[accent,content]] of Object.entries(icons)){
  const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 96 96">\n<ellipse cx="48" cy="85" rx="33" ry="6" fill="#06191c" opacity=".35"/>\n<g stroke="#203c3e" stroke-width="2.5" stroke-linejoin="round">${content}</g>\n</svg>\n`;
  const relative=`../../icons/factory_${name}.svg`;await fs.writeFile(new URL(relative,out),svg);
  manifest.files[relative]={bytes:Buffer.byteLength(svg),sha256:crypto.createHash('sha256').update(svg).digest('hex'),size:[96,96],accent};
}
for(const relative of ['tools/factory-content/export-expansion-assets.mjs','tools/visual-studies/web-topdown-3d/parts.mjs','tools/visual-studies/web-topdown-3d/factory.mjs','tools/visual-studies/web-topdown-3d/node_modules/three/package.json']){
  manifest.sources[relative]=crypto.createHash('sha256').update(await fs.readFile(new URL(`../../${relative}`,import.meta.url))).digest('hex');
}
await fs.writeFile(new URL('source-manifest.json',out),JSON.stringify(manifest,null,2)+'\n');
