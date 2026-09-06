export const WORLD = Object.freeze({ width: 416, height: 288, speed: 86, radius: 6 });
export const SPOTS = Object.freeze({
  start: { x: 218, y: 226 }, machineBack: { x: 132, y: 148 },
  machineFront: { x: 132, y: 211 }, pipeBack: { x: 266, y: 161 },
  pipeFront: { x: 266, y: 193 },
});
export const CONTACT = Object.freeze({ machine: 192, pipe: 174 });
export const OBSTACLES = Object.freeze([
  { x: 89, y: 164, w: 83, h: 29 },
  { x: 206, y: 170, w: 10, h: 8 }, { x: 309, y: 170, w: 10, h: 8 },
]);

export function newState() {
  return { ...SPOTS.start, target: null, glass: true, shadow: true, grid: false, zoom: 1, moving: false };
}

export function blocked(x, y) {
  const r = WORLD.radius;
  return x < r || x > WORLD.width - r || y < 34 || y > WORLD.height - 12 ||
    OBSTACLES.some(o => x > o.x - r && x < o.x + o.w + r && y > o.y - r && y < o.y + o.h + r);
}

export function move(state, dx, dy, dt) {
  if (![dx, dy, dt].every(Number.isFinite) || dt < 0) throw new TypeError('Invalid motion input');
  const norm = Math.hypot(dx, dy);
  state.moving = false;
  if (!norm) return;
  // Bounded substeps prevent tunnelling through the small support feet.
  const distance = WORLD.speed * Math.min(dt, 0.1);
  const steps = Math.max(1, Math.ceil(distance / 2));
  const sx = dx / norm * distance / steps;
  const sy = dy / norm * distance / steps;
  for (let i = 0; i < steps; i++) {
    const beforeX = state.x, beforeY = state.y;
    if (!blocked(state.x + sx, state.y)) state.x += sx;
    if (!blocked(state.x, state.y + sy)) state.y += sy;
    state.moving ||= state.x !== beforeX || state.y !== beforeY;
  }
}

export function tick(state, keys, dt) {
  let dx = Number(keys.has('d') || keys.has('ArrowRight')) - Number(keys.has('a') || keys.has('ArrowLeft'));
  let dy = Number(keys.has('s') || keys.has('ArrowDown')) - Number(keys.has('w') || keys.has('ArrowUp'));
  if (dx || dy) state.target = null;
  else if (state.target) {
    dx = state.target.x - state.x; dy = state.target.y - state.y;
    const distance = Math.hypot(dx, dy);
    if (distance <= Math.max(1, WORLD.speed * dt)) {
      if (!blocked(state.target.x, state.target.y)) Object.assign(state, state.target);
      state.target = null; state.moving = false; return;
    }
  }
  move(state, dx, dy, dt);
  if (state.target && !state.moving) state.target = null;
}

export function screenToWorld(x, y, width, height, zoom) {
  return { x: (x / width * WORLD.width - WORLD.width / 2) / zoom + WORLD.width / 2,
    y: (y / height * WORLD.height - WORLD.height / 2) / zoom + WORLD.height / 2 };
}

export function drawOrder(y) {
  return [{ id: 'machine', y: CONTACT.machine }, { id: 'pipe', y: CONTACT.pipe }, { id: 'actor', y }]
    .sort((a, b) => a.y - b.y).map(item => item.id);
}
