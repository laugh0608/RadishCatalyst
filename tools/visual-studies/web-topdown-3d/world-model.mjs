export const MACHINES = Object.freeze([
  { type: 'reactor', x: -7, z: -4, radius: 1.55 },
  { type: 'reactor', x: 0, z: -4, radius: 1.55 },
  { type: 'reactor', x: 7, z: -4, radius: 1.55 },
  { type: 'compressor', x: -7, z: 3, radius: 1.65 },
  { type: 'compressor', x: 0, z: 3, radius: 1.65 },
  { type: 'storage', x: 7, z: 2.5, radius: 1.3 },
  { type: 'storage', x: 7, z: 6, radius: 1.3 },
]);
export const SUPPORTS = Object.freeze([[-4,-1.2], [3.5,-1.2], [9.5,-1.2], [9.5,4.5]]);
export const SPOTS = Object.freeze({ entry: { x: -2.8, z: 6.5 }, reactorBack: { x: 0, z: -6.2 },
  reactorFront: { x: 0, z: -1.9 }, pipe: { x: -.8, z: -1.2 }, aisle: { x: -3.6, z: 1 } });
export const PLAYER = Object.freeze({ radius: .29, height: 1.65, speed: 3.3 });
export function newState() { return { ...SPOTS.entry, angle: 0, walk: 0, moving: false, target: null }; }
export function blocked(x,z) {
  if (Math.abs(x)>11.4 || Math.abs(z)>8.3) return true;
  if (MACHINES.some(m=>{
    const [w,d]=m.type==='reactor'?[3,2.9]:m.type==='compressor'?[3.2,2.65]:[2.4,2.4];
    return Math.hypot(Math.max(Math.abs(x-m.x)-w/2,0),Math.max(Math.abs(z-m.z)-d/2,0))<PLAYER.radius;
  })) return true;
  // Low utility pipes and their terminal elbows are below head clearance.
  if(Math.abs(z+7.2)<.12+PLAYER.radius&&Math.abs(x)<10.12+PLAYER.radius)return true;
  for(const sx of [-7,0])if(Math.abs(x-sx-2)<.12+PLAYER.radius&&z>1.3-PLAYER.radius&&z<3+PLAYER.radius)return true;
  return SUPPORTS.some(([sx,sz])=>[-.55,.55].some(offset=>Math.hypot(x-sx,z-sz-offset)<.15+PLAYER.radius));
}
export function move(state, dx, dz, dt) {
  if (![dx,dz,dt].every(Number.isFinite)||dt<0) throw new TypeError('Invalid movement');
  const length=Math.hypot(dx,dz); state.moving=false;
  if (!length) return;
  const distance=PLAYER.speed*Math.min(dt,.06), steps=Math.max(1,Math.ceil(distance/.06));
  for(let i=0;i<steps;i++) {
    const x=state.x+dx/length*distance/steps, z=state.z+dz/length*distance/steps;
    if (!blocked(x,state.z)) {state.x=x; state.moving=true;}
    if (!blocked(state.x,z)) {state.z=z; state.moving=true;}
  }
  if(state.moving) { state.angle=Math.atan2(dx,dz); state.walk+=distance; }
}
export function tick(state,keys,dt,yaw) {
  const right=Number(keys.has('d')||keys.has('ArrowRight'))-Number(keys.has('a')||keys.has('ArrowLeft'));
  const forward=Number(keys.has('w')||keys.has('ArrowUp'))-Number(keys.has('s')||keys.has('ArrowDown'));
  let dx=right*Math.cos(yaw)-forward*Math.sin(yaw), dz=-right*Math.sin(yaw)-forward*Math.cos(yaw);
  if(right||forward) state.target=null;
  else if(state.target) {
    dx=state.target.x-state.x; dz=state.target.z-state.z;
    if(Math.hypot(dx,dz)<Math.max(.05,PLAYER.speed*dt)) { state.target=null; state.moving=false; return; }
  }
  move(state,dx,dz,dt);
  if(state.target&&!state.moving) state.target=null;
}
