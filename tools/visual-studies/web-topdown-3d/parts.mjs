import * as THREE from 'three';

export const material=(color,metalness=0,roughness=.65)=>new THREE.MeshStandardMaterial({color,metalness,roughness});
export const M={
  teal:material('#377b7c',.35,.4), light:material('#c7c9ab',.25,.52), steel:material('#788e8e',.7,.32),
  dark:material('#273b40',.5,.42), rubber:material('#202b2c',.05,.92), amber:material('#d29945',.5,.35),
  orange:material('#a75d37',.25,.65), floor:material('#78857d',.08,.92), edge:material('#4b5e59',.12,.8),
  soil:material('#434e49',0,.99), cyan:new THREE.MeshStandardMaterial({color:'#5bd6c8',emissive:'#248577',emissiveIntensity:.65,roughness:.32}),
};
export function mesh(parent,geo,mat,at=[0,0,0]) {
  const obj=new THREE.Mesh(geo,mat); obj.position.set(...at); obj.castShadow=true; obj.receiveShadow=true;parent.add(obj);return obj;
}
export const box=(p,at,size,mat)=>mesh(p,new THREE.BoxGeometry(...size),mat,at);
export const cylinder=(p,at,r,h,mat,segments=24)=>mesh(p,new THREE.CylinderGeometry(r,r,h,segments),mat,at);
export function sphere(p,at,size,mat) {const s=mesh(p,new THREE.SphereGeometry(1,24,12),mat,at);s.scale.set(...size);return s;}
export function ring(p,at,r,t,mat) {const s=mesh(p,new THREE.TorusGeometry(r,t,8,32),mat,at);return s;}
export function rod(p,a,b,r,mat,segments=12) {
  const start=new THREE.Vector3(...a),end=new THREE.Vector3(...b),d=end.clone().sub(start);
  const obj=cylinder(p,start.clone().add(end).multiplyScalar(.5).toArray(),r,d.length(),mat,segments);
  obj.quaternion.setFromUnitVectors(new THREE.Vector3(0,1,0),d.normalize());return obj;
}
export function bolts(p,y,r,count=8) {
  for(let i=0;i<count;i++) {const a=i/count*Math.PI*2;cylinder(p,[Math.cos(a)*r,y,Math.sin(a)*r],.055,.09,M.light,6);}
}
export function plinth(p,w,d) {
  box(p,[0,.12,0],[w,.24,d],M.dark);box(p,[0,.29,0],[w-.15,.1,d-.15],M.steel);
  for(const x of [-1,1])for(const z of [-1,1])box(p,[x*(w/2-.22),.16,z*(d/2-.22)],[.42,.3,.42],M.light);
}
export function controlPanel(p,at) {
  const g=new THREE.Group();g.position.set(...at);p.add(g);
  box(g,[0,0,0],[.62,1.05,.32],M.light);box(g,[0,.19,.18],[.46,.36,.03],M.dark);
  box(g,[0,.2,.205],[.32,.17,.025],M.cyan);
  for(const x of [-.16,0,.16])sphere(g,[x,-.09,.185],[.043,.043,.026],x===0?M.orange:M.amber);
  for(const y of [-.25,-.34,-.43])box(g,[0,y,.171],[.38,.025,.025],M.dark);
}
export function reactor(p,x,z,index) {
  const g=new THREE.Group();g.position.set(x,0,z);p.add(g);g.name=`reactor-${index}`;plinth(g,3,2.9);
  cylinder(g,[0,1.62,0],1.02,2.32,M.teal);sphere(g,[0,2.77,0],[1.02,.48,1.02],M.light);
  sphere(g,[0,.55,0],[1.02,.3,1.02],M.steel);
  for(const y of [.64,1.02,2.53])cylinder(g,[0,y,0],1.055,.13,y===1.02?M.dark:M.steel);
  cylinder(g,[0,3.15,0],.5,.17,M.dark);cylinder(g,[0,3.25,0],.45,.12,M.amber);bolts(g,3.35,.34);
  for(const side of [-1,1]) {box(g,[side*1.15,1.32,.56],[.18,1.95,.19],M.light);rod(g,[side*.72,.8,-.76],[side*.72,2.65,-.76],.075,M.steel);}
  const door=cylinder(g,[0,1.22,1.015],.45,.15,M.amber);door.rotation.x=Math.PI/2;
  const inner=cylinder(g,[0,1.22,1.11],.34,.08,M.dark);inner.rotation.x=Math.PI/2;
  const wheel=ring(g,[0,1.22,1.2],.23,.035,M.steel);
  box(g,[0,1.22,1.2],[.43,.035,.035],M.steel);box(g,[0,1.22,1.2],[.035,.43,.035],M.steel);
  controlPanel(g,[1.15,1.24,1.05]);
  rod(g,[-.62,2.7,0],[-.62,3.55,0],.14,M.amber);rod(g,[-.62,3.55,0],[.05,3.55,0],.14,M.amber);
  box(g,[-.5,1.9,1.05],[.42,.17,.025],M.light);return g;
}
export function compressor(p,x,z,index) {
  const g=new THREE.Group();g.position.set(x,0,z);p.add(g);g.name=`compressor-${index}`;plinth(g,3.2,2.65);
  box(g,[0,1.03,0],[2.65,1.35,1.95],M.teal);box(g,[0,1.79,0],[2.76,.18,2.07],M.light);
  box(g,[0,1.06,1.01],[2.25,.98,.06],M.dark);
  for(let i=0;i<9;i++)box(g,[-.95+i*.24,1.06,1.06],[.075,.72,.07],M.steel);
  for(const x2 of [-.69,.69]) {
    cylinder(g,[x2,1.98,0],.47,.23,M.dark);cylinder(g,[x2,2.12,0],.4,.06,M.steel);
    for(let i=0;i<6;i++) {const blade=box(g,[x2,2.16,0],[.7,.025,.08],M.dark);blade.rotation.y=i*Math.PI/3;}
  }
  controlPanel(g,[1.3,1.15,.9]);rod(g,[-1.55,.65,-.6],[-1.55,1.55,-.6],.16,M.amber);return g;
}
export function storage(p,x,z,index) {
  const g=new THREE.Group();g.position.set(x,0,z);p.add(g);g.name=`storage-${index}`;plinth(g,2.4,2.4);
  cylinder(g,[0,1.46,0],.87,2.1,M.light);sphere(g,[0,2.49,0],[.87,.33,.87],M.light);
  for(const y of [.6,2.3])cylinder(g,[0,y,0],.91,.16,M.dark);
  cylinder(g,[0,2.82,0],.28,.25,M.amber);box(g,[0,1.42,.87],[.65,.8,.04],M.teal);
  box(g,[0,1.43,.901],[.18,.54,.02],M.cyan);
  for(const y of [1.0,1.2,1.4,1.6,1.8,2.0])rod(g,[-.4,y,-.91],[.4,y,-.91],.025,M.steel);
  return g;
}
