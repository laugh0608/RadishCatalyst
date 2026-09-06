import * as THREE from 'three';
import { RoomEnvironment } from 'three/addons/environments/RoomEnvironment.js';
import { createFactory,createEngineer } from './factory.mjs';
import { newState,SPOTS,tick,blocked } from './world-model.mjs';

const canvas=document.querySelector('#world'),status=document.querySelector('#status');
const state=newState(),keys=new Set(),cameraState={elevation:55,yaw:25*Math.PI/180,zoom:1};
const movement=new Set(['w','a','s','d','ArrowUp','ArrowDown','ArrowLeft','ArrowRight']);
let renderer,camera,scene,factory,engineer,sun,ready=false;
const target=new THREE.Vector3(0,.2,0),raycaster=new THREE.Raycaster(),groundPlane=new THREE.Plane(new THREE.Vector3(0,1,0),0);
const marker=new THREE.Mesh(new THREE.RingGeometry(.18,.23,32),new THREE.MeshBasicMaterial({color:'#f3d18a',side:THREE.DoubleSide,depthWrite:false}));
marker.rotation.x=-Math.PI/2;marker.visible=false;
const timings=[];let frames=0,lastReport=0;

function syncCamera(){
  if(!camera)return;
  const rect=canvas.getBoundingClientRect(),aspect=rect.width/rect.height;
  const height=Math.max(23,34/aspect)/cameraState.zoom;
  camera.left=-height*aspect/2;camera.right=height*aspect/2;camera.top=height/2;camera.bottom=-height/2;
  const pitch=THREE.MathUtils.degToRad(cameraState.elevation),distance=40;
  camera.position.set(Math.sin(cameraState.yaw)*Math.cos(pitch)*distance,Math.sin(pitch)*distance,Math.cos(cameraState.yaw)*Math.cos(pitch)*distance).add(target);
  camera.lookAt(target);camera.updateProjectionMatrix();camera.updateMatrixWorld();
}
function resize(){if(!renderer)return;const r=canvas.getBoundingClientRect();renderer.setSize(r.width,r.height,false);syncCamera();}
function setShadows(enabled){
  if(!renderer)return;
  renderer.shadowMap.enabled=enabled;
  if(sun)sun.castShadow=enabled;
  scene.traverse(object=>{
    if(!object.isMesh)return;
    for(const material of (Array.isArray(object.material)?object.material:[object.material]))material.needsUpdate=true;
  });
}
function chooseSpot(name){Object.assign(state,SPOTS[name]);state.target=null;state.moving=false;keys.clear();}
function reset(){
  Object.assign(state,newState());Object.assign(cameraState,{elevation:55,yaw:25*Math.PI/180,zoom:1});keys.clear();
  document.querySelector('#zoom').value='1';
  for(const b of document.querySelectorAll('[data-angle]'))b.setAttribute('aria-pressed',String(b.dataset.angle==='55'));
  for(const id of ['glass','shadows'])document.getElementById(id).checked=true;
  document.querySelector('#contents').checked=false;
  if(factory){factory.setGlass(true);factory.contents.visible=false;}
  setShadows(true);
  if(sun){sun.position.set(-9,16,9);document.querySelector('#light').textContent='光向：左上';}
  syncCamera();
}
for(const button of document.querySelectorAll('[data-angle]'))button.addEventListener('click',()=>{
  cameraState.elevation=Number(button.dataset.angle);syncCamera();
  for(const b of document.querySelectorAll('[data-angle]'))b.setAttribute('aria-pressed',String(b===button));
});
for(const button of document.querySelectorAll('[data-spot]'))button.addEventListener('click',()=>chooseSpot(button.dataset.spot));
document.querySelector('#zoom').addEventListener('input',e=>{cameraState.zoom=Number(e.target.value);syncCamera();});
for(const [id,amount] of [['rotate-left',-15],['rotate-right',15]])document.getElementById(id).addEventListener('click',()=>{cameraState.yaw+=THREE.MathUtils.degToRad(amount);syncCamera();});
document.querySelector('#glass').addEventListener('change',e=>factory?.setGlass(e.target.checked));
document.querySelector('#contents').addEventListener('change',e=>{if(factory)factory.contents.visible=e.target.checked;});
document.querySelector('#shadows').addEventListener('change',e=>setShadows(e.target.checked));
document.querySelector('#light').addEventListener('click',()=>{
  if(!sun)return;const alternate=sun.position.x<0;sun.position.set(alternate?11:-9,16,alternate?-7:9);
  document.querySelector('#light').textContent=alternate?'光向：右后':'光向：左上';
});
document.querySelector('#reset').addEventListener('click',reset);
const normalize=key=>key.length===1?key.toLowerCase():key;
window.addEventListener('keydown',e=>{
  if(!ready||e.target.matches('input,select'))return;const key=normalize(e.key);
  if(movement.has(key)){e.preventDefault();keys.add(key);if(!e.repeat)tick(state,keys,1/60,cameraState.yaw);}
  else if((key==='q'||key==='e')&&!e.repeat){cameraState.yaw+=THREE.MathUtils.degToRad(key==='q'?-15:15);syncCamera();}
});
window.addEventListener('keyup',e=>keys.delete(normalize(e.key)));
window.addEventListener('blur',()=>{keys.clear();state.target=null;});
document.addEventListener('visibilitychange',()=>{if(document.hidden){keys.clear();state.target=null;}});
canvas.addEventListener('pointerdown',e=>{
  if(!ready)return;canvas.focus();const r=canvas.getBoundingClientRect();
  raycaster.setFromCamera(new THREE.Vector2((e.clientX-r.left)/r.width*2-1,-(e.clientY-r.top)/r.height*2+1),camera);
  const p=raycaster.ray.intersectPlane(groundPlane,new THREE.Vector3());
  if(p&&!blocked(p.x,p.z))state.target={x:p.x,z:p.z};
});
canvas.addEventListener('wheel',e=>{e.preventDefault();cameraState.zoom=THREE.MathUtils.clamp(cameraState.zoom-e.deltaY*.001,.8,1.6);document.querySelector('#zoom').value=String(cameraState.zoom);syncCamera();},{passive:false});
for(const button of document.querySelectorAll('[data-key]')) {
  button.addEventListener('pointerdown',e=>{if(!ready)return;e.preventDefault();button.setPointerCapture(e.pointerId);keys.add(button.dataset.key);tick(state,keys,1/60,cameraState.yaw);});
  for(const name of ['pointerup','pointercancel','lostpointercapture'])button.addEventListener(name,()=>keys.delete(button.dataset.key));
}

function fail(error){ready=false;status.hidden=false;status.setAttribute('role','alert');status.textContent=`三维场景无法继续：${error.message}`;console.error(error);}
canvas.addEventListener('webglcontextlost',e=>{e.preventDefault();fail(new Error('图形上下文丢失，请刷新页面重试'));});
try {
  renderer=new THREE.WebGLRenderer({canvas,antialias:true,alpha:false,powerPreference:'high-performance'});
  renderer.setPixelRatio(Math.min(window.devicePixelRatio,1.5));renderer.shadowMap.enabled=true;renderer.shadowMap.type=THREE.PCFShadowMap;
  renderer.toneMapping=THREE.ACESFilmicToneMapping;renderer.toneMappingExposure=.9;renderer.outputColorSpace=THREE.SRGBColorSpace;
  scene=new THREE.Scene();scene.background=new THREE.Color('#344643');scene.fog=new THREE.Fog('#344643',45,85);
  camera=new THREE.OrthographicCamera(-20,20,12,-12,.1,120);
  const env=new RoomEnvironment(),pmrem=new THREE.PMREMGenerator(renderer);
  const environment=pmrem.fromScene(env,.03);scene.environment=environment.texture;scene.environmentIntensity=.4;env.dispose();pmrem.dispose();
  scene.add(new THREE.HemisphereLight('#d7ebef','#536052',.85));
  sun=new THREE.DirectionalLight('#fff0ce',2.4);sun.position.set(-9,16,9);sun.castShadow=true;
  sun.shadow.mapSize.set(2048,2048);Object.assign(sun.shadow.camera,{left:-18,right:18,top:18,bottom:-18,near:1,far:50});
  sun.shadow.bias=-.00015;sun.shadow.normalBias=.035;sun.shadow.camera.updateProjectionMatrix();scene.add(sun);
  factory=createFactory(scene);engineer=createEngineer(scene);scene.add(marker);
  new ResizeObserver(resize).observe(canvas);resize();
  renderer.compile(scene,camera);renderer.render(scene,camera);ready=true;status.hidden=true;
  let previous;
  function frame(now){
    if(!ready)return;
    try{
      const dt=previous===undefined?0:Math.min((now-previous)/1000,.05);previous=now;
      tick(state,keys,dt,cameraState.yaw);engineer.update(state);
      marker.visible=!!state.target;if(state.target)marker.position.set(state.target.x,.018,state.target.z);
      const begin=performance.now();renderer.render(scene,camera);timings.push(performance.now()-begin);if(timings.length>180)timings.shift();frames++;
      if(now-lastReport>250){
        document.querySelector('#position').value=`X ${state.x.toFixed(1)} / Z ${state.z.toFixed(1)} · ${cameraState.elevation}°`;
        document.querySelector('#performance').value=`${(timings.reduce((a,b)=>a+b,0)/timings.length).toFixed(1)} ms 提交 / 帧`;
        canvas.dataset.frames=String(frames);canvas.dataset.drawCalls=String(renderer.info.render.calls);canvas.dataset.triangles=String(renderer.info.render.triangles);
        lastReport=now;
      }
      requestAnimationFrame(frame);
    }catch(error){fail(error);}
  }
  requestAnimationFrame(frame);
}catch(error){fail(error);}
