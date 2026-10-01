import * as THREE from 'three';
import {RoomEnvironment} from 'three/addons/environments/RoomEnvironment.js';
import {createYard,batchStatic,createEngineer} from '../factory.mjs';
import {M,material,box,cylinder,mesh,rod,reactor,compressor,storage} from '../parts.mjs';
import {CATALOG,DIRS,ORE,REFERENCE,AREA,port,feedback,placement,beltPathDirections,beltInputs} from './model.mjs';

const STATUS={running:'#77d8c6',ready:'#b2c5b3',waiting:'#e2b365',blocked:'#e58864'};
const crystalMaterial=material('#70c8d1',.32,.24),catalystMaterial=material('#deb25b',.5,.3);
function dispose(root){root.traverse(o=>{if(o.isMesh)o.geometry.dispose();});root.removeFromParent();}
function arrow(parent,x,z,dir,mat,size=.45){
  const g=new THREE.Group();g.position.set(x,.365,z);g.rotation.y=-dir*Math.PI/2;parent.add(g);
  box(g,[-size*.15,0,0],[size*.75,.025,size*.16],mat);
  const head=mesh(g,new THREE.ConeGeometry(size*.34,size*.48,3),mat,[size*.39,0,0]);head.rotation.z=-Math.PI/2;head.rotation.x=Math.PI/2;
  return g;
}
function footprint(parent,x,z,w,d,mat,height=.045){
  const g=new THREE.Group();parent.add(g);
  box(g,[x+w/2,height,z],[w,.035,.04],mat);box(g,[x+w/2,height,z+d],[w,.035,.04],mat);
  box(g,[x,height,z+d/2],[.04,.035,d],mat);box(g,[x+w,height,z+d/2],[.04,.035,d],mat);return g;
}

function cornerArc(entry,dir){
  const out=DIRS[dir],center=[(entry[0]+out[0])*.5,(entry[1]+out[1])*.5];
  const start=Math.atan2(-out[1],-out[0]);
  const sweep=Math.atan2(out[0]*entry[1]-out[1]*entry[0],out[0]*entry[0]+out[1]*entry[1]);
  return {center,start,sweep};
}
export function beltTravelPosition(entry,dir,progress){
  const out=DIRS[dir];
  if(entry[0]*out[0]+entry[1]*out[1]===0){
    const {center,start,sweep}=cornerArc(entry,dir),angle=start+sweep*progress;
    return [center[0]+.5*Math.cos(angle),center[1]+.5*Math.sin(angle)];
  }
  return progress<.5?entry.map(v=>v*(.5-progress)):out.map(v=>v*(progress-.5));
}
function arcStrip(parent,arc,inner,outer,y,height,mat){
  const shape=new THREE.Shape(),points=[];
  for(let i=0;i<=20;i++){const a=arc.start+arc.sweep*i/20;points.push([arc.center[0]+outer*Math.cos(a),arc.center[1]+outer*Math.sin(a)]);}
  for(let i=20;i>=0;i--){const a=arc.start+arc.sweep*i/20;points.push([arc.center[0]+inner*Math.cos(a),arc.center[1]+inner*Math.sin(a)]);}
  points.forEach(([x,z],i)=>i?shape.lineTo(x,-z):shape.moveTo(x,-z));shape.closePath();
  const geometry=new THREE.ExtrudeGeometry(shape,{depth:height,bevelEnabled:false,steps:1});geometry.rotateX(-Math.PI/2);
  return mesh(parent,geometry,mat,[0,y,0]);
}
export function createBeltGeometry(dir,inputs){
  const g=new THREE.Group(),incoming=inputs.length?inputs:[(dir+2)%4];
  if(incoming.length===1&&(incoming[0]+2)%4!==dir){
    const arc=cornerArc(DIRS[incoming[0]],dir);g.name='belt-corner';
    arcStrip(g,arc,.15,.85,.01,.24,M.dark);
    arcStrip(g,arc,.225,.775,.2475,.045,M.rubber).name='belt-surface';
    for(const radius of [.15,.85])arcStrip(g,arc,radius-.025,radius+.025,.23,.12,M.steel).name='belt-rail';
    for(const t of [.12,.36,.64,.88]){
      const a=arc.start+arc.sweep*t;
      const roller=box(g,[arc.center[0]+.5*Math.cos(a),.3,arc.center[1]+.5*Math.sin(a)],[.53,.018,.028],M.steel);roller.rotation.y=-a;
    }
    const t=.55,a=arc.start+arc.sweep*t,p=beltTravelPosition(DIRS[incoming[0]],dir,t);
    const tangent=a+Math.sign(arc.sweep)*Math.PI/2;
    arrow(g,p[0],p[1],tangent/(Math.PI/2),M.amber,.27);
  }else if(incoming.length===1){
    g.name='belt-straight';g.rotation.y=-dir*Math.PI/2;
    box(g,[0,.13,0],[1,.24,.7],M.dark);
    box(g,[0,.27,0],[1,.045,.55],M.rubber).name='belt-surface';
    for(const z of [-.35,.35])box(g,[0,.29,z],[1,.12,.05],M.steel).name='belt-rail';
    for(let x=-.35;x<.5;x+=.23)box(g,[x,.3,0],[.028,.018,.53],M.steel);
    arrow(g,0,0,0,M.amber,.33);
  }else{
    g.name='belt-junction';
    box(g,[0,.13,0],[.7,.24,.7],M.dark);
    box(g,[0,.27,0],[.7,.045,.7],M.rubber).name='belt-surface';
    for(const [side,[dx,dz]] of DIRS.entries()){
      const arm=new THREE.Group();arm.rotation.y=-side*Math.PI/2;g.add(arm);
      if(side===dir||incoming.includes(side)){
        box(arm,[.425,.13,0],[.15,.24,.7],M.dark);
        box(arm,[.425,.27,0],[.15,.045,.55],M.rubber).name='belt-surface';
        for(const z of [-.35,.35])box(arm,[.425,.29,z],[.15,.12,.05],M.steel).name='belt-rail';
      }else box(g,[dx*.35,.29,dz*.35],[dx?.05:.7,.12,dz?.05:.7],M.steel).name='belt-rail';
    }
    arrow(g,DIRS[dir][0]*.14,DIRS[dir][1]*.14,dir,M.amber,.33);
  }
  return g;
}

export function createView(canvas){
  const renderer=new THREE.WebGLRenderer({canvas,antialias:true,powerPreference:'high-performance'});
  renderer.setPixelRatio(Math.min(devicePixelRatio,1.5));renderer.shadowMap.enabled=true;renderer.shadowMap.type=THREE.PCFShadowMap;
  renderer.toneMapping=THREE.ACESFilmicToneMapping;renderer.toneMappingExposure=.9;
  const scene=new THREE.Scene();scene.background=new THREE.Color('#344643');scene.fog=new THREE.Fog('#344643',45,85);
  const camera=new THREE.OrthographicCamera(-20,20,12,-12,.1,120),target=new THREE.Vector3(0,.25,.3);
  const cameraState={yaw:25*Math.PI/180,zoom:1};
  const env=new RoomEnvironment(),pmrem=new THREE.PMREMGenerator(renderer),environment=pmrem.fromScene(env,.03);
  scene.environment=environment.texture;scene.environmentIntensity=.4;env.dispose();pmrem.dispose();
  scene.add(new THREE.HemisphereLight('#d7ebef','#536052',.85));
  const sun=new THREE.DirectionalLight('#fff0ce',2.4);sun.position.set(-9,16,9);sun.castShadow=true;
  sun.shadow.mapSize.set(2048,2048);Object.assign(sun.shadow.camera,{left:-18,right:18,top:18,bottom:-18,near:1,far:50});
  sun.shadow.bias=-.00015;sun.shadow.normalBias=.035;sun.shadow.camera.updateProjectionMatrix();scene.add(sun);
  const yard=createYard();
  // Decorative infrastructure stays at the back, outside the playable grid.
  for(const x of [-9,-3,3,9]){
    box(yard,[x,1.17,-7.5],[.17,2.34,.17],M.dark);box(yard,[x,.07,-7.5],[.55,.14,.5],M.steel);
    const flange=cylinder(yard,[x,2.42,-7.5],.25,.16,M.amber);flange.rotation.z=Math.PI/2;
  }
  const glass=new THREE.MeshPhysicalMaterial({color:'#b7ece8',metalness:.12,roughness:.12,transparent:true,opacity:.23,side:THREE.DoubleSide,depthWrite:false,clearcoat:1});
  const pipe=rod(yard,[-9,2.42,-7.5],[9,2.42,-7.5],.21,glass,24);pipe.castShadow=false;
  for(let i=0;i<12;i++){
    const x=ORE.x+.22+(i%4)*.49,z=ORE.z+.23+Math.floor(i/4)*.65;
    const c=mesh(yard,new THREE.ConeGeometry(.18,.38+(i%3)*.12,5),crystalMaterial,[x,.22,z]);c.rotation.z=(i%3-1)*.18;
  }
  scene.add(batchStatic(yard));
  const engineer=createEngineer(scene),entities=new Map(),grid=new THREE.Group(),guides=new THREE.Group();scene.add(grid,guides);
  const gridMat=new THREE.LineBasicMaterial({color:'#c0cbb6',transparent:true,opacity:.26});
  const lines=[];for(let x=AREA.minX;x<=AREA.maxX;x++)lines.push(x,.04,AREA.minZ,x,.04,AREA.maxZ);
  for(let z=AREA.minZ;z<=AREA.maxZ;z++)lines.push(AREA.minX,.04,z,AREA.maxX,.04,z);
  grid.add(new THREE.LineSegments(new THREE.BufferGeometry().setAttribute('position',new THREE.Float32BufferAttribute(lines,3)),gridMat));
  const guideMat=material('#c4c69a',0,.8);guideMat.transparent=true;guideMat.opacity=.45;
  for(const [type,p] of Object.entries(REFERENCE)){const def=CATALOG[type];footprint(guides,p.x,p.z,def.w,def.d,guideMat);}
  const validMat=material('#73d0b3',0,.7),invalidMat=material('#dc8065',0,.7),selectMat=material('#edc576',.1,.65);
  for(const m of [validMat,invalidMat]){m.transparent=true;m.opacity=.65;}
  let ghost=new THREE.Group(),selection=new THREE.Group(),lastRevision=-1,ghostKey='',selectionKey='';scene.add(ghost,selection);
  const ray=new THREE.Raycaster(),plane=new THREE.Plane(new THREE.Vector3(0,1,0),0);
  function resize(){const r=canvas.getBoundingClientRect();renderer.setSize(r.width,r.height,false);syncCamera();}
  function syncCamera(){
    const r=canvas.getBoundingClientRect(),aspect=r.width/r.height,pitch=50*Math.PI/180,h=Math.max(21,31/aspect)/cameraState.zoom;
    Object.assign(camera,{left:-h*aspect/2,right:h*aspect/2,top:h/2,bottom:-h/2});
    camera.position.set(Math.sin(cameraState.yaw)*Math.cos(pitch)*40,Math.sin(pitch)*40,Math.cos(cameraState.yaw)*Math.cos(pitch)*40).add(target);
    camera.lookAt(target);camera.updateProjectionMatrix();camera.updateMatrixWorld();
  }
  new ResizeObserver(resize).observe(canvas);resize();
  function ground(clientX,clientY){
    const r=canvas.getBoundingClientRect();ray.setFromCamera(new THREE.Vector2((clientX-r.left)/r.width*2-1,-(clientY-r.top)/r.height*2+1),camera);
    return ray.ray.intersectPlane(plane,new THREE.Vector3());
  }
  function project(x,y,z){const v=new THREE.Vector3(x,y,z).project(camera),r=canvas.getBoundingClientRect();return {x:(v.x+1)*r.width/2,y:(1-v.y)*r.height/2,visible:v.z>-1&&v.z<1};}
  function build(e,inputs=[]){
    const def=CATALOG[e.type],g=new THREE.Group();g.position.set(e.x+def.w/2,0,e.z+def.d/2);scene.add(g);
    let model;
    if(e.type==='collector'){model=compressor(g,0,0,e.id);model.scale.set(.58,.85,.68);}
    if(e.type==='reactor'){model=reactor(g,0,0,e.id);model.scale.set(.94,1,.94);}
    if(e.type==='storage'){model=storage(g,0,0,e.id);model.scale.set(.79,.85,.79);}
    let cargo,lamp,bar;
    if(e.type==='belt'){
      g.add(createBeltGeometry(e.dir,inputs));
      cargo=mesh(g,new THREE.OctahedronGeometry(.19),crystalMaterial,[0,.53,0]);cargo.castShadow=true;
    }else{
      for(const role of ['input','output']){
        const p=port(e,role);if(!p)continue;
        const localX=p.x+.5-g.position.x,localZ=p.z+.5-g.position.z;
        const socket=new THREE.Group();socket.position.set(localX+p.dx*.5,0,localZ);g.add(socket);
        const accent=role==='input'?M.cyan:M.amber;
        // A raised frame sits on the true boundary; its short apron reaches the belt.
        box(socket,[p.dx*.08,.18,0],[.66,.24,.82],M.dark);
        for(const z of [-.38,.38])box(socket,[0,.52,z],[.22,.62,.1],accent);
        box(socket,[0,.85,0],[.22,.1,.86],accent);
        box(socket,[-p.dx*.14,.52,0],[.08,.48,.66],M.rubber);
        const mark=arrow(socket,p.dx*.27,0,0,M.light,.48);mark.position.y=.36;
        // Keep the frame cap plain; the apron carries the single flow arrow.
        box(socket,[0,.92,0],[.5,.07,.78],M.dark);
      }
      const lampMat=new THREE.MeshStandardMaterial({color:STATUS.waiting,emissive:STATUS.waiting,emissiveIntensity:.5});
      lamp=mesh(g,new THREE.SphereGeometry(.105,12,8),lampMat,[-def.w/2+.22,e.type==='reactor'?3.4:2.1,def.d/2-.2]);
      box(g,[0,.035,def.d/2+.15],[def.w*.8,.04,.12],M.dark);
      bar=box(g,[0,.064,def.d/2+.15],[def.w*.8,.025,.12],M.cyan);
    }
    return {g,cargo,lamp,bar};
  }
  function rebuild(s){
    for(const [id,v] of entities)if(!s.entities.some(e=>e.id===id)){dispose(v.g);v.lamp?.material.dispose();entities.delete(id);}
    // Neighbour edits also change an existing belt's entry shape.
    for(const e of s.entities){
      const inputs=e.type==='belt'?beltInputs(s,e):[],shapeKey=`${e.dir}/${inputs.join(',')}`;
      let v=entities.get(e.id);
      if(v&&v.shapeKey!==shapeKey){dispose(v.g);v.lamp?.material.dispose();entities.delete(e.id);v=null;}
      if(!v){v=build(e,inputs);v.shapeKey=shapeKey;entities.set(e.id,v);}
    }
    lastRevision=s.revision;
  }
  function draw(s,a,ui){
    if(lastRevision!==s.revision)rebuild(s);
    engineer.update(a);grid.visible=ui.build;guides.visible=ui.build&&ui.guides;
    const validCell=ui.cell&&[ui.cell.x,ui.cell.z].every(Number.isInteger),valid=ui.tool&&validCell&&placement(s,ui.tool,ui.cell.x,ui.cell.z,a).ok;
    const nextGhost=`${ui.tool}/${ui.cell?.x}/${ui.cell?.z}/${ui.dir}/${valid}/${JSON.stringify(ui.stroke)}`;
    if(nextGhost!==ghostKey){dispose(ghost);ghost=new THREE.Group();scene.add(ghost);ghostKey=nextGhost;
    if(ui.stroke){
      const directions=beltPathDirections(ui.stroke,ui.dir);
      for(const [i,c] of ui.stroke.entries()){
        footprint(ghost,c.x,c.z,1,1,validMat,.08);
        arrow(ghost,c.x+.5,c.z+.5,directions[i],validMat,.6);
      }
    }else if(ui.tool&&validCell){const {x,z}=ui.cell,d=CATALOG[ui.tool];
      footprint(ghost,x,z,d.w,d.d,valid?validMat:invalidMat,.07);
      const top=box(ghost,[x+d.w/2,.07,z+d.d/2],[d.w,.035,d.d],valid?validMat:invalidMat);top.castShadow=false;
      if(ui.tool==='belt')arrow(ghost,x+.5,z+.5,ui.dir,valid?validMat:invalidMat,.6);
    }}
    const nextSelection=`${ui.selected}/${s.revision}`;
    if(nextSelection!==selectionKey){dispose(selection);selection=new THREE.Group();scene.add(selection);selectionKey=nextSelection;
      const chosen=s.entities.find(e=>e.id===ui.selected);if(chosen){const d=CATALOG[chosen.type];footprint(selection,chosen.x,chosen.z,d.w,d.d,selectMat,.07);}}
    for(const e of s.entities){const v=entities.get(e.id),def=CATALOG[e.type],f=feedback(s,e);
      if(v.lamp){v.lamp.material.color.set(STATUS[f.kind]);v.lamp.material.emissive.set(STATUS[f.kind]);v.lamp.scale.setScalar(f.kind==='running'?1+Math.sin(s.time*5)*.12:1);}
      if(v.bar){const progress=e.type==='reactor'?(e.processing?e.progress/10:e.output?1:0):e.type==='collector'?e.buffer/50:(e.crystal+e.catalyst)/200;
        v.bar.scale.x=Math.max(.001,progress);v.bar.position.x=-(1-progress)*def.w*.4;}
      if(v.cargo){v.cargo.visible=!!e.cargo;if(e.cargo){v.cargo.material=e.cargo==='crystal'?crystalMaterial:catalystMaterial;
        const [x,z]=beltTravelPosition(e.entry,e.dir,e.progress);
        v.cargo.position.set(x,.53,z);v.cargo.rotation.y=s.time*.4;v.cargo.scale.setScalar(e.cargo==='catalyst'?.9:1);}}

    }
    renderer.render(scene,camera);
  }
  function hit(clientX,clientY){
    const r=canvas.getBoundingClientRect();ray.setFromCamera(new THREE.Vector2((clientX-r.left)/r.width*2-1,-(clientY-r.top)/r.height*2+1),camera);
    const hits=ray.intersectObjects([...entities.values()].map(v=>v.g),true);
    for(const hit of hits)for(const [id,v] of entities){let n=hit.object;while(n){if(n===v.g)return id;n=n.parent;}}
    return null;
  }
  return {draw,ground,project,hit,cameraState,syncCamera};
}
