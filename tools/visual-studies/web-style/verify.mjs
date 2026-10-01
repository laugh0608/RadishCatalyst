import test from 'node:test';
import assert from 'node:assert/strict';
import { newState, move, blocked, drawOrder, screenToWorld, SPOTS, tick } from './scene-model.mjs';
import { createServer } from './server.mjs';

test('movement normalizes diagonals and blocks the device footprint', () => {
  const a = newState(), b = newState();
  move(a, 1, 0, .1); move(b, 1, 1, .1);
  assert.ok(Math.abs(Math.hypot(b.x - SPOTS.start.x, b.y - SPOTS.start.y) - (a.x - SPOTS.start.x)) < 1e-8);
  const c = { ...newState(), ...SPOTS.machineFront };
  for (let i = 0; i < 100; i++) move(c, 0, -1, .1);
  assert.ok(c.y >= 199 && c.y < 211); assert.equal(blocked(c.x, c.y), false);
});
test('thin supports cannot be crossed by a long frame; all observation spots are free', () => {
  const s = { ...newState(), x: 190, y: 174 };
  for (let i = 0; i < 20; i++) move(s, 1, 0, 10);
  assert.ok(s.x <= 200); assert.equal(blocked(s.x, s.y), false);
  for (const p of Object.values(SPOTS)) assert.equal(blocked(p.x, p.y), false);
});
test('depth switches at contact and zoomed pointer mapping preserves world center', () => {
  assert.ok(drawOrder(SPOTS.machineBack.y).indexOf('actor') < drawOrder(SPOTS.machineBack.y).indexOf('machine'));
  assert.ok(drawOrder(SPOTS.machineFront.y).indexOf('actor') > drawOrder(SPOTS.machineFront.y).indexOf('machine'));
  assert.ok(drawOrder(SPOTS.pipeBack.y).indexOf('actor') < drawOrder(SPOTS.pipeBack.y).indexOf('pipe'));
  assert.deepEqual(screenToWorld(416, 288, 832, 576, 1.5), { x: 208, y: 144 });
});
test('pointer travel stops and manual keys take over', () => {
  const s = newState(); s.target = { x: s.x + 1, y: s.y };
  tick(s, new Set(), .05); assert.equal(s.target, null); assert.equal(s.x, SPOTS.start.x + 1);
  s.target = { x: 340, y: 260 }; tick(s, new Set(['a']), .05); assert.equal(s.target, null);
  assert.ok(s.x < SPOTS.start.x + 1);
});
test('local HTTP serves exact allowlist only and rejects writes', async t => {
  const server = createServer(); await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  t.after(() => new Promise(resolve => server.close(resolve)));
  const root = `http://127.0.0.1:${server.address().port}`;
  const home = await fetch(root); assert.equal(home.status, 200); assert.match(home.headers.get('content-type'), /text\/html/);
  for (const route of ['/../AGENTS.md', '/.git/config', '/assets/%2e%2e/server.mjs', '/pixel/manifest.json']) assert.equal((await fetch(root + route)).status, 404);
  assert.equal((await fetch(root, { method: 'POST' })).status, 405);
  assert.equal((await fetch(root + '/pixel/machine.png')).status, 200);
});
