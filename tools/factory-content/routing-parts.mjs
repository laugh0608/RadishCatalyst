import * as THREE from '../visual-studies/web-topdown-3d/node_modules/three/build/three.module.js';
import {M,box,cylinder} from '../visual-studies/web-topdown-3d/parts.mjs';

export function armoredHousing(g,cover,depth=.88){
  box(g,[0,.051,0],[.88,.1,depth],M.dark);
  box(g,[0,.46,0],[.84,.25,depth-.04],M.dark);
  box(g,[0,.591,0],[.8,.03,depth-.08],cover);
  const cornerZ=depth*.5-.12;
  for(const x of [-.32,.32])for(const z of [-cornerZ,cornerZ]){
    box(g,[x,.29,z],[.22,.4,.22],M.steel);
    box(g,[x,.568,z],[.2,.075,.2],M.light);
    cylinder(g,[x,.615,z],.029,.02,M.dark,8);
  }
}

export function armoredPort(g,side,outgoing){
  const port=new THREE.Group();port.rotation.y=-side*Math.PI/2;g.add(port);
  box(port,[.31,.145,0],[.38,.15,.39],M.rubber);
  box(port,[.36,.318,0],[.23,.067,.36],outgoing?M.amber:M.teal);
  for(const z of [-.192,.192])box(port,[.375,.19,z],[.25,.19,.036],M.dark);
  for(const x of [.37,.46]){
    const roller=cylinder(port,[x,.22,0],.022,.31,M.steel,10);
    roller.rotation.x=Math.PI/2;
  }
}

export function outletGlyph(g,side){
  const tip=new THREE.Shape();
  tip.moveTo(.255,0);tip.lineTo(.145,.076);tip.lineTo(.145,-.076);tip.closePath();
  const glyph=new THREE.Mesh(new THREE.ShapeGeometry(tip),M.amber);
  glyph.rotation.set(-Math.PI/2,0,-side*Math.PI/2);
  glyph.position.y=.63;g.add(glyph);
}
