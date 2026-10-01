import { newState, SPOTS, tick, screenToWorld, blocked } from './scene-model.mjs';
import { loadAssets, Renderer } from './renderer.mjs';

const state = newState(), keys = new Set();
const status = document.querySelector('#load-status');
const stages = document.querySelector('#stages');
const canvases = [...document.querySelectorAll('canvas')];
const movementKeys = new Set(['w', 'a', 's', 'd', 'ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight']);
const canonical = key => key.length === 1 ? key.toLowerCase() : key;
let renderers = [], ready = false;

function reset() {
  Object.assign(state, newState()); keys.clear();
  for (const name of ['glass', 'shadow', 'grid']) document.getElementById(name).checked = state[name];
  document.querySelector('#zoom').value = '1';
}

for (const button of document.querySelectorAll('button[data-view]')) {
  button.addEventListener('click', () => {
    stages.dataset.view = button.dataset.view;
    for (const peer of document.querySelectorAll('button[data-view]')) peer.setAttribute('aria-pressed', String(peer === button));
  });
}
for (const id of ['glass', 'shadow', 'grid']) document.getElementById(id).addEventListener('change', e => { state[id] = e.target.checked; });
document.querySelector('#zoom').addEventListener('change', e => { state.zoom = Number(e.target.value); });
for (const button of document.querySelectorAll('[data-spot]')) button.addEventListener('click', () => {
  Object.assign(state, SPOTS[button.dataset.spot]); state.target = null; keys.clear();
});
document.querySelector('#reset').addEventListener('click', reset);

window.addEventListener('keydown', event => {
  if (event.target.matches('input, select')) return;
  const key = canonical(event.key);
  if (movementKeys.has(key)) {
    event.preventDefault(); keys.add(key);
    // A tap shorter than one animation frame must still produce a small step.
    // Held keys continue through the frame loop, independently of OS repeat.
    if (!event.repeat) tick(state, keys, 1 / 60);
  }
});
window.addEventListener('keyup', event => { keys.delete(canonical(event.key)); });
window.addEventListener('blur', () => { keys.clear(); state.target = null; });
document.addEventListener('visibilitychange', () => { if (document.hidden) { keys.clear(); state.target = null; } });
for (const canvas of canvases) canvas.addEventListener('pointerdown', e => {
  if (!ready) return;
  canvas.focus();
  const r = canvas.getBoundingClientRect();
  const target = screenToWorld(e.clientX - r.left, e.clientY - r.top, r.width, r.height, state.zoom);
  if (!blocked(target.x, target.y)) state.target = target;
});
for (const button of document.querySelectorAll('[data-key]')) {
  button.addEventListener('pointerdown', e => {
    e.preventDefault(); button.setPointerCapture(e.pointerId); keys.add(button.dataset.key);
    tick(state, keys, 1 / 60);
  });
  for (const event of ['pointerup', 'pointercancel', 'lostpointercapture']) button.addEventListener(event, () => { keys.delete(button.dataset.key); });
}

try {
  const assets = await loadAssets();
  renderers = canvases.map(c => new Renderer(c, assets[c.id], c.id));
  ready = true; status.hidden = true;
  // Establish the time origin from the first animation callback: its timestamp
  // can predate performance.now() when registration happens within that frame.
  let previous, lastOutput = 0;
  const frame = now => {
    const dt = previous === undefined ? 0 : Math.min((now - previous) / 1000, .05); previous = now;
    tick(state, keys, dt);
    for (const renderer of renderers) renderer.draw(state);
    if (now - lastOutput > 100) {
      document.querySelector('#position').value = `X ${Math.round(state.x)} / Y ${Math.round(state.y)}`;
      lastOutput = now;
    }
    requestAnimationFrame(frame);
  };
  requestAnimationFrame(frame);
} catch (error) {
  status.textContent = error.message; status.setAttribute('role', 'alert');
  console.error(error);
}
