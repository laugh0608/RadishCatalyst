import {createState,CATALOG,DIRS,REFERENCE,place,salvage,deposit,rotate,advance,entityAt,feedback,placement,moveActor,extendBeltPath,placeBeltPath} from './model.mjs';
import {createView} from './scene.mjs';

const $=id=>document.getElementById(id),canvas=$('world');
let state=createState(),actor={x:-3.5,z:5.7,angle:0,walk:0,moving:false,target:null};
const ui={build:true,tool:null,cell:null,dir:0,selected:null,guides:true,paused:false,stroke:null},keys=new Set();
let view,ready=false,lastUI=0,lastLesson='',pointer=null;
const names=['东 →','南 ↓','西 ←','北 ↑'];
function notice(message,error=false){$('notice').textContent=message;$('notice').dataset.error=String(error);}
function choose(type){
  stopPointer();
  ui.build=true;ui.tool=type;ui.selected=null;
  const p=REFERENCE[type]||{x:-6,z:0};ui.cell={...p};
  actor.target=null;notice(type==='belt'?'箭头沿物料前进方向。单击放一格，按住拖动连续铺带，松开确认；R 转向。':'移动鼠标选择落位，点击放置；也可用下方 X / Z 精确调整。');syncUI();
}
function commit(){
  if(!ui.tool||!ui.cell)return;
  const result=place(state,ui.tool,ui.cell.x,ui.cell.z,ui.dir,actor);
  if(!result.ok){notice(result.reason,true);syncUI();return;}
  const e=result.entity;notice(`${CATALOG[e.type].name}已放置。${e.type==='belt'?'可继续铺设，Esc 结束。':'点击设备可以查看库存与运行状态。'}`);
  if(e.type==='belt'){const [dx,dz]=DIRS[ui.dir];ui.cell={x:e.x+dx,z:e.z+dz};}
  else{ui.tool=null;ui.selected=e.id;}
  syncUI();
}
function select(id){ui.tool=null;ui.selected=id;actor.target=null;syncUI();}
function cancel(){
  if(pointer){stopPointer();notice('已取消本次拖动铺带。');syncUI();return;}
  if(ui.tool){ui.tool=null;notice('已取消放置。');}
  else if(ui.selected!==null){ui.selected=null;}
  else if(ui.build){ui.build=false;notice('观察模式：点击地面移动，点击设备查看。');}
  syncUI();
}
function setBuild(){stopPointer();ui.build=!ui.build;ui.tool=null;notice(ui.build?'选择一个构件开始建造。':'观察模式：点击地面移动，点击设备查看。');syncUI();}
function turn(){if(ui.tool==='belt'){ui.dir=(ui.dir+1)%4;syncUI();}else if(ui.selected){const r=rotate(state,ui.selected);notice(r.ok?'传送带已转向。':r.reason,!r.ok);syncUI();}}
function syncUI(){
  $('build').textContent=ui.build?'建造中 B':'进入建造 B';$('build').setAttribute('aria-pressed',String(ui.build));$('build-tools').hidden=!ui.build;
  for(const b of document.querySelectorAll('[data-tool]')){b.classList.toggle('active',ui.tool===b.dataset.tool);b.setAttribute('aria-pressed',String(ui.tool===b.dataset.tool));}
  for(const b of document.querySelectorAll('[data-kit]'))b.textContent=state.kits[b.dataset.kit];
  $('placement').hidden=!ui.tool;
  if(ui.tool&&ui.cell){
    $('placement-name').textContent=CATALOG[ui.tool].name;
    if(document.activeElement!==$('cell-x'))$('cell-x').value=ui.cell.x;
    if(document.activeElement!==$('cell-z'))$('cell-z').value=ui.cell.z;
    $('rotate').hidden=ui.tool!=='belt';$('rotate').textContent=`方向：${names[ui.dir]}`;
    const valid=placement(state,ui.tool,ui.cell.x,ui.cell.z,actor);$('placement-reason').textContent=valid.ok?'可放置 · 点击场地或按 Enter':valid.reason;
    $('place').disabled=!valid.ok;
  }
  $('bag').textContent=`回收箱：晶体 ${state.bag.crystal} / 催化剂 ${state.bag.catalyst}`;
  $('delivered').textContent=state.delivered;
  $('clock').textContent=`${Math.floor(state.time/60).toString().padStart(2,'0')}:${Math.floor(state.time%60).toString().padStart(2,'0')}`;
  $('actor-position').value=`X ${actor.x.toFixed(1)} / Z ${actor.z.toFixed(1)}`;
  const e=state.entities.find(e=>e.id===ui.selected);$('inspector').hidden=!e;
  if(e){
    $('selected-name').textContent=CATALOG[e.type].name;$('selected-status').textContent=feedback(state,e).label;
    let text=e.type==='collector'?`晶体缓冲 ${e.buffer} / 50\n采集速度 1 个 / 秒\n金色出口位于右侧`:e.type==='reactor'?`晶体输入 ${e.input} / 2\n催化剂输出 ${e.output} / 1\n${e.processing?`加工 ${e.progress.toFixed(1)} / 10 秒`:'每批 2 晶体 → 1 催化剂'}\n左进右出，接口在靠前一排`:e.type==='storage'?`晶体 ${e.crystal} · 催化剂 ${e.catalyst}\n容量 ${e.crystal+e.catalyst} / 200\n青色入口位于左侧`:`方向 ${names[e.dir]}\n带上物品：${e.cargo==='crystal'?'晶体':e.cargo==='catalyst'?'催化剂':'空'}\n速度 1 格 / 秒`;
    $('selected-details').textContent=text;$('rotate-selected').hidden=e.type!=='belt';$('deposit').hidden=e.type==='belt';
    $('deposit').disabled=state.bag.crystal+state.bag.catalyst===0;
  }
  updateMission();
  // Fit the actual world between the header and control dock, including narrow screens.
  const dock=$('game').getBoundingClientRect().bottom-document.querySelector('.dock').getBoundingClientRect().top;
  $('viewport').style.bottom=`${dock+4}px`;document.querySelector('.camera-tools').style.bottom=`${dock+16}px`;
}
function updateMission(){
  const l=state.lesson,built=['collector','reactor','storage'].every(t=>state.entities.some(e=>e.type===t));
  const done={build:built,delivery:l.firstDelivery,starved:l.starved,recovered:l.recovered};
  for(const el of document.querySelectorAll('[data-milestone]'))el.classList.toggle('done',done[el.dataset.milestone]);
  let step,title,text;
  if(l.recovered){step='04 / 已恢复';title='你的产线重新运转了';text='新产物已经入仓。可以继续改布局，再判断是否想把这座工厂扩建下去。';}
  else if(l.starved){step='04 / 修复';title='补回输入缺口';text='重新铺带，把采集器接回反应器。等待新的催化剂进入终端仓。';}
  else if(l.cut){step='03 / 等待耗尽';title='线路已断开';text='已有存料会继续加工。观察反应器消耗完晶体，真实进入缺料状态。';}
  else if(l.firstDelivery){step='03 / 断路';title='试着拆开输入线路';text='点击采集器与反应器之间的一段带，选择“拆回构件和货物”，观察后续变化。';}
  else if(!state.entities.some(e=>e.type==='collector')){step='01 / 搭建';title='从青色矿点开始';text='选择采集器，覆盖青色矿点。浅色框是可关闭的参考落位。';}
  else if(!built){step='01 / 搭建';title='放下反应器和终端仓';text='预留带的空间。反应器左进右出，终端仓从左侧接收。';}
  else{step='02 / 接通';title='把三台设备连起来';text='金色出口 → 传送带 → 青色入口。晶体加工 10 秒，产出催化剂后送入终端仓。';}
  $('mission-step').textContent=step;$('mission-title').textContent=title;$('mission-text').textContent=text;
  if(lastLesson!==step&&l.firstDelivery)notice(title);lastLesson=step;
}
for(const b of document.querySelectorAll('[data-tool]'))b.addEventListener('click',()=>choose(b.dataset.tool));
$('build').addEventListener('click',setBuild);$('place').addEventListener('click',commit);$('cancel').addEventListener('click',cancel);$('rotate').addEventListener('click',turn);$('rotate-selected').addEventListener('click',turn);
for(const id of ['cell-x','cell-z'])$(id).addEventListener('input',()=>{if(!ui.cell)return;ui.cell[id==='cell-x'?'x':'z']=$(id).valueAsNumber;syncUI();});
$('guides').addEventListener('change',e=>{ui.guides=e.target.checked;});
$('close-inspector').addEventListener('click',()=>{ui.selected=null;syncUI();});
$('salvage').addEventListener('click',()=>{
  const r=salvage(state,ui.selected);if(r.ok){ui.selected=null;notice(`已回收${CATALOG[r.type].name}、${r.items.crystal} 晶体、${r.items.catalyst} 催化剂。`);}else notice(r.reason,true);syncUI();
});
$('deposit').addEventListener('click',()=>{const r=deposit(state,ui.selected);notice(r.ok?`已投入 ${r.amount} 件回收物品。`:r.reason,!r.ok);syncUI();});
$('pause').addEventListener('click',()=>{ui.paused=!ui.paused;$('pause').textContent=ui.paused?'继续':'暂停';$('pause').setAttribute('aria-pressed',String(ui.paused));notice(ui.paused?'生产已暂停，可以查看或调整布局。':'生产继续。');});
$('help').addEventListener('click',()=>{$('help-panel').hidden=!$('help-panel').hidden;$('help').setAttribute('aria-expanded',String(!$('help-panel').hidden));syncUI();});
$('restart').addEventListener('click',()=>$('restart-dialog').showModal());$('keep-playing').addEventListener('click',()=>$('restart-dialog').close());
$('confirm-restart').addEventListener('click',()=>{stopPointer();state=createState();actor={x:-3.5,z:5.7,angle:0,walk:0,moving:false,target:null};Object.assign(ui,{build:true,tool:null,cell:null,dir:0,selected:null,paused:false});keys.clear();$('pause').textContent='暂停';$('pause').setAttribute('aria-pressed','false');$('restart-dialog').close();$('help-panel').hidden=true;$('help').setAttribute('aria-expanded','false');notice('新厂坪已准备好。');syncUI();});
function rotateCamera(amount){if(!view)return;view.cameraState.yaw+=amount*Math.PI/180;view.syncCamera();}
function zoom(amount){if(!view)return;view.cameraState.zoom=Math.max(.8,Math.min(1.5,view.cameraState.zoom+amount));view.syncCamera();}
$('left').addEventListener('click',()=>rotateCamera(-15));$('right').addEventListener('click',()=>rotateCamera(15));$('zoom-out').addEventListener('click',()=>zoom(-.1));$('zoom-in').addEventListener('click',()=>zoom(.1));
function stopPointer(){
  const id=pointer?.id;pointer=null;ui.stroke=null;
  if(id!==undefined&&canvas.hasPointerCapture(id))canvas.releasePointerCapture(id);
}
function canvasPoint(e){
  const bounds=canvas.getBoundingClientRect();
  if(e.clientX<bounds.left||e.clientX>=bounds.right||e.clientY<bounds.top||e.clientY>=bounds.bottom)return null;
  // Pointer capture must not turn an overlaid panel into buildable ground.
  if(document.elementFromPoint(e.clientX,e.clientY)!==canvas)return null;
  return view.ground(e.clientX,e.clientY);
}
function previewStroke(cell){
  const result=extendBeltPath(state,ui.stroke,cell);ui.stroke=result.path||ui.stroke;
  notice(result.ok?`预览 ${ui.stroke.length} 段 · 松开铺设，回拖缩短，Esc 取消`:result.reason,!result.ok);
}
canvas.addEventListener('pointermove',e=>{
  if(!ready||!ui.tool)return;
  if(pointer&&pointer.id!==e.pointerId)return;
  const p=canvasPoint(e);
  if(!p){if(pointer){stopPointer();notice('已离开场地，本次铺带预览已取消。');syncUI();}return;}
  ui.cell={x:Math.floor(p.x),z:Math.floor(p.z)};
  if(pointer?.belt){if(!(e.buttons&1)){stopPointer();return;}previewStroke(ui.cell);}
  syncUI();
});
canvas.addEventListener('pointerdown',e=>{
  if(!ready||e.button!==0||pointer)return;
  const p=canvasPoint(e);if(!p)return;
  canvas.focus();actor.target=null;
  pointer={id:e.pointerId,x:e.clientX,y:e.clientY,belt:ui.tool==='belt'};
  canvas.setPointerCapture(e.pointerId);
  if(pointer.belt){ui.cell={x:Math.floor(p.x),z:Math.floor(p.z)};ui.stroke=[];previewStroke(ui.cell);syncUI();}
});
canvas.addEventListener('pointerup',e=>{
  if(!ready||!pointer||pointer.id!==e.pointerId||e.button!==0)return;
  const gesture=pointer,p=canvasPoint(e);
  if(gesture.belt){
    const path=ui.stroke;stopPointer();
    if(!p){notice('已离开场地，本次铺带预览已取消。');syncUI();return;}
    const result=placeBeltPath(state,path,ui.dir);
    notice(result.ok?`已铺设 ${result.entities.length} 段传送带。可继续拖动铺设，Esc 结束。`:result.reason,!result.ok);
    syncUI();return;
  }
  stopPointer();
  if(!p||Math.hypot(e.clientX-gesture.x,e.clientY-gesture.y)>8)return;
  if(ui.tool){ui.cell={x:Math.floor(p.x),z:Math.floor(p.z)};commit();return;}
  const id=view.hit(e.clientX,e.clientY),e2=entityAt(state,Math.floor(p.x),Math.floor(p.z));
  if(id||e2)select(id||e2.id);else{ui.selected=null;actor.target={x:p.x,z:p.z};syncUI();}
});
for(const name of ['pointercancel','lostpointercapture'])canvas.addEventListener(name,()=>stopPointer());
canvas.addEventListener('wheel',e=>{e.preventDefault();zoom(-e.deltaY*.001);},{passive:false});
const moveKeys=new Set(['w','a','s','d','ArrowUp','ArrowDown','ArrowLeft','ArrowRight']);
function movement(dt){
  const yaw=view.cameraState.yaw,right=Number(keys.has('d')||keys.has('ArrowRight'))-Number(keys.has('a')||keys.has('ArrowLeft')),forward=Number(keys.has('w')||keys.has('ArrowUp'))-Number(keys.has('s')||keys.has('ArrowDown'));
  let dx=right*Math.cos(yaw)-forward*Math.sin(yaw),dz=-right*Math.sin(yaw)-forward*Math.cos(yaw);
  if(right||forward)actor.target=null;
  else if(actor.target){dx=actor.target.x-actor.x;dz=actor.target.z-actor.z;if(Math.hypot(dx,dz)<.07){actor.target=null;dx=dz=0;}}
  moveActor(state,actor,dx,dz,dt);if(actor.target&&!actor.moving)actor.target=null;
}
window.addEventListener('keydown',e=>{
  if(!ready||$('restart-dialog').open)return;
  const k=e.key.length===1?e.key.toLowerCase():e.key;
  if(k==='Escape'){e.preventDefault();cancel();return;}
  if(pointer)return;
  if(e.target.matches('input'))return;
  if(k==='Enter'&&ui.tool){e.preventDefault();commit();return;}
  if(k.startsWith('Arrow')&&ui.tool){e.preventDefault();const delta={ArrowLeft:[-1,0],ArrowRight:[1,0],ArrowUp:[0,-1],ArrowDown:[0,1]}[k];ui.cell.x+=delta[0];ui.cell.z+=delta[1];syncUI();return;}
  if(moveKeys.has(k)){e.preventDefault();keys.add(k);if(!e.repeat)movement(1/60);return;}
  if(e.repeat)return;
  if('1234'.includes(k)&&k.length===1)choose(['collector','reactor','storage','belt'][Number(k)-1]);
  if(k==='b')setBuild();if(k==='r')turn();if(k==='q')rotateCamera(-15);if(k==='e')rotateCamera(15);
});
window.addEventListener('keyup',e=>keys.delete(e.key.length===1?e.key.toLowerCase():e.key));
window.addEventListener('blur',()=>{stopPointer();keys.clear();actor.target=null;});
document.addEventListener('visibilitychange',()=>{stopPointer();keys.clear();actor.target=null;});
for(const b of document.querySelectorAll('[data-key]')){b.addEventListener('pointerdown',e=>{if(!ready)return;e.preventDefault();b.setPointerCapture(e.pointerId);keys.add(b.dataset.key);movement(1/60);});for(const name of ['pointerup','pointercancel','lostpointercapture'])b.addEventListener(name,()=>keys.delete(b.dataset.key));}
function fail(error){ready=false;$('load-status').hidden=false;$('load-status').setAttribute('role','alert');$('load-status').textContent=`场景无法继续：${error.message}`;console.error(error);}
canvas.addEventListener('webglcontextlost',e=>{e.preventDefault();fail(new Error('图形上下文丢失，请刷新页面重新开始'));});
try{
  view=createView(canvas);ready=true;$('load-status').hidden=true;syncUI();let previous;
  function frame(now){if(!ready)return;try{
    const dt=previous===undefined?0:Math.min((now-previous)/1000,.1);previous=now;
    if(!document.hidden){if(!ui.paused&&!$('restart-dialog').open)advance(state,dt);movement(Math.min(dt,.06));}
    if(now-lastUI>120){syncUI();lastUI=now;}view.draw(state,actor,ui);requestAnimationFrame(frame);
  }catch(error){fail(error);}}
  requestAnimationFrame(frame);
}catch(error){fail(error);}
