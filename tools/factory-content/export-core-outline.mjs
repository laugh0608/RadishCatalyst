// R1-B editable, repository-authored silhouette. No textures or gameplay data.
import fs from 'node:fs/promises';
import crypto from 'node:crypto';
import * as THREE from '../visual-studies/web-topdown-3d/node_modules/three/build/three.module.js';
import { GLTFExporter } from '../visual-studies/web-topdown-3d/node_modules/three/examples/jsm/exporters/GLTFExporter.js';
import { RoundedBoxGeometry } from '../visual-studies/web-topdown-3d/node_modules/three/examples/jsm/geometries/RoundedBoxGeometry.js';
import { batchStatic } from '../visual-studies/web-topdown-3d/factory.mjs';

const args = process.argv.slice(2);
const batch = args[0];
if (!batch || !/^[a-z0-9][a-z0-9-]*$/.test(batch) || args.slice(1).some(a => a !== '--publish-prototype')) {
  throw Error('Usage: node tools/factory-content/export-core-outline.mjs <new-batch> [--publish-prototype]');
}
const rootUrl = new URL('../../', import.meta.url);
const out = new URL(`assets/art-intake/2026-11-01-core-outline/${batch}/`, rootUrl);
await fs.mkdir(out, { recursive: true });
try { await fs.access(new URL('source-manifest.json', out)); throw Error('Use a new batch; existing evidence must not be overwritten'); }
catch (e) { if (e.code !== 'ENOENT') throw e; }
globalThis.FileReader = class {
  readAsArrayBuffer(blob) { blob.arrayBuffer().then(result => { this.result = result; this.onloadend?.(); }); }
};
const material = (name, color) => new THREE.MeshStandardMaterial({ name, color, metalness: 0, roughness: .78 });
const mats = { shell: material('Outline_Shell', '#c9cbbb'), frame: material('Outline_Frame', '#293f43'),
  module: material('Outline_Module', '#497e79'), mark: material('Outline_Output', '#d1aa62') };
const structure = new THREE.Group(), logistics = new THREE.Group(), marks = new THREE.Group();
const tierI = new THREE.Group(), tierII = new THREE.Group();
function mesh(parent, geometry, mat, at) {
  const part = new THREE.Mesh(geometry, mat); part.position.set(...at); parent.add(part); return part;
}
function box(parent, at, size, mat, radius = .045) {
  return mesh(parent, new RoundedBoxGeometry(...size, 1, radius), mat, at);
}
function plain(parent, at, size, mat) { return mesh(parent, new THREE.BoxGeometry(...size), mat, at); }
function arrow(parent, point, direction, mat, scale = 1) {
  const shape = new THREE.Shape();
  shape.moveTo(-.16, .02); shape.lineTo(-.065, .02); shape.lineTo(-.065, .22);
  shape.lineTo(.065, .22); shape.lineTo(.065, .02); shape.lineTo(.16, .02); shape.lineTo(0, -.2); shape.closePath();
  const part = mesh(parent, new THREE.ShapeGeometry(shape), mat, point);
  part.rotation.set(-Math.PI / 2, 0, 0); part.rotateOnWorldAxis(new THREE.Vector3(0, 1, 0), Math.atan2(direction[0], direction[1]));
  part.scale.setScalar(scale);
}

// A full low foundation reads as one six-cell core; the roof rises toward +Z.
box(logistics, [0, .09, 0], [6, .18, 6], mats.frame, .035);
box(structure, [0, .825, .35], [3.2, 1.25, 2.5], mats.shell, .13);
box(logistics, [0, .3, .15], [3.4, .2, 3.1], mats.frame, .06);
for (const x of [-2.4, 2.4]) {
  box(structure, [x, .4, -2.35], [.85, .44, .9], mats.shell, .08);
  plain(logistics, [x, .635, -2.35], [.5, .025, .5], mats.frame);
  // Mirror the corner outline, with the south caps below the tray sightline samples.
  box(structure, [x, .25, 2.35], [.85, .14, .9], mats.shell, .045);
  plain(logistics, [x, .329, 2.35], [.5, .018, .5], mats.frame);
}
for (const x of [-1.05, 1.05]) {
  box(structure, [x, .57, -1.25], [.62, .64, .6], mats.shell, .06);
  plain(logistics, [x, .9, -1.25], [.4, .025, .34], mats.frame);
}
// Narrow maintenance spine is common to both tiers and fixes their envelope.
box(structure, [0, 1.675, 1.17], [.62, 2.09, .58], mats.shell, .065);
box(logistics, [0, 2.69, 1.17], [.73, .16, .69], mats.frame, .04);
plain(marks, [0, 2.785, 1.17], [.45, .03, .4], mats.mark);
box(logistics, [0, .93, 1.64], [1.6, .64, .16], mats.frame, .06);
plain(marks, [0, 1.03, 1.73], [.66, .1, .025], mats.mark);
for (const x of [-1.12, 1.12]) plain(logistics, [x, .9, 1.613], [.18, .72, .035], mats.frame);
function module(parent, tier) {
  box(parent, [0, 1.76, .67], [2.75, .57, 1.64], mats.module, .11);
  for (const x of [-.8, 0, .8]) box(parent, [x, 2.095, .45], [.5, .13, .86], mats.module, .03);
  if (tier === 2) {
    for (const x of [-1.28, 1.28]) box(parent, [x, 1.55, 0], [.5, .58, .68], mats.module, .065);
    box(parent, [0, 2.29, .93], [1.9, .35, .5], mats.module, .065);
  }
}
module(tierI, 1); module(tierII, 2);

const ports = [];
for (const [side, nx, nz] of [['N', 0, -1], ['E', 1, 0], ['S', 0, 1], ['W', -1, 0]]) {
  for (const [index, offset] of [-1.5, -.5, .5, 1.5].entries()) {
    const output = index === 3;
    ports.push({ id: output ? `OUT_${side}0` : `IN_${side}${index}`,
      role: output ? 'output' : 'input', point: [3 * nx - nz * offset, .31, 3 * nz + nx * offset], normal: [nx, nz] });
  }
}
for (const port of ports) {
  const [nx, nz] = port.normal, [x, , z] = port.point;
  const center = [x - nx * .43, .245, z - nz * .43];
  const group = new THREE.Group(); group.position.set(...center); group.rotation.y = Math.atan2(nx, nz); logistics.add(group);
  box(group, [0, 0, 0], [.76, .13, .86], mats.frame, .025); // top = .31, ends at the footprint edge
  for (const side of [-1, 1]) plain(group, [side * .36, .13, 0], [.045, .13, .8], mats.frame);
  if (port.role === 'input') {
    arrow(structure, [center[0], .325, center[2]], [-nx, -nz], mats.shell);
  } else {
    for (const offset of [-.16, .16]) arrow(marks,
      [center[0] + nx * offset, .325, center[2] + nz * offset], [nx, nz], mats.mark, .65);
  }
  port.probe = [center[0], .34, center[2]];
  port.probe_samples = [[0, 0], [nx * .18, nz * .18], [-nx * .18, -nz * .18], [nz * .18, -nx * .18], [-nz * .18, nx * .18]]
    .map(([dx, dz]) => [center[0] + dx, .34, center[2] + dz]);
}

function batchGroup(source, name) {
  const group = batchStatic(source); group.name = name;
  group.children.forEach((m, i) => { m.name = `${name}_Mesh${i}`; }); return group;
}
const core = new THREE.Group(); core.name = 'BaseCore';
core.add(batchGroup(structure, 'Structure'), batchGroup(logistics, 'LogisticsRing'));
const tiers = new THREE.Group(); tiers.name = 'TierModules';
tiers.add(batchGroup(tierI, 'I'), batchGroup(tierII, 'II')); core.add(tiers);
core.add(batchGroup(marks, 'StatusMounts'));
const anchors = new THREE.Group(); anchors.name = 'Ports'; core.add(anchors);
for (const port of ports) {
  const node = new THREE.Group(); node.name = `Port_${port.id}`; node.position.set(...port.point);
  node.userData = { role: port.role, normal: port.normal, review_only: true }; anchors.add(node);
}
const bounds = () => { core.updateMatrixWorld(true); const b = new THREE.Box3().setFromObject(core, true); return { min: b.min.toArray(), max: b.max.toArray() }; };
const fullBounds = bounds();
if (fullBounds.min[0] < -3.00001 || fullBounds.max[0] > 3.00001 || fullBounds.min[2] < -3.00001 || fullBounds.max[2] > 3.00001 || fullBounds.min[1] < -.00001 || fullBounds.max[1] > 3.6) throw Error('Core exceeds footprint / height contract');
const variants = {};
for (const tier of [1, 2]) {
  tiers.children[0].visible = tier === 1; tiers.children[1].visible = tier === 2;
  let surfaces = 0, triangles = 0;
  core.traverseVisible(obj => { if (obj.isMesh) { surfaces++; triangles += (obj.geometry.index?.count ?? obj.geometry.attributes.position.count) / 3; } });
  if (surfaces > 4 || triangles > 12000) throw Error(`Tier ${tier} exceeds silhouette budget`);
  variants[tier] = { surfaces, triangles };
}
tiers.children.forEach(c => { c.visible = true; });
const scene = new THREE.Scene(); scene.add(core);
const bytes = Buffer.from(await new GLTFExporter().parseAsync(scene, { binary: true, onlyVisible: false }));
const hash = data => crypto.createHash('sha256').update(data).digest('hex');
const sourcePaths = ['tools/factory-content/export-core-outline.mjs', 'tools/visual-studies/web-topdown-3d/factory.mjs',
  'tools/visual-studies/web-topdown-3d/parts.mjs', 'tools/visual-studies/web-topdown-3d/world-model.mjs',
  'tools/visual-studies/web-topdown-3d/node_modules/three/package.json'];
const sources = {};
for (const path of sourcePaths) sources[path] = hash(await fs.readFile(new URL(path, rootUrl)));
const manifest = { purpose: 'R1-B prototype silhouette only; no gameplay, fine materials or textures',
  source: 'Repository-authored editable geometry; no external asset pack', license: 'Project-authored; existing Three.js MIT dependency',
  command: `node tools/factory-content/export-core-outline.mjs ${args.join(' ')}`, three_version: THREE.REVISION,
  status: 'outline candidate; owner review pending', files: { 'core-outline.glb': { bytes: bytes.length, sha256: hash(bytes),
    root: 'BaseCore', footprint: [6, 6], bounds: fullBounds, materials: 4, textures: 0, variants } }, ports, sources,
  geometry_notes: 'Four visible material batches; I and II alternatives share a common root/ports/envelope. Flat rough opaque materials, no glow.' };
await fs.writeFile(new URL('core-outline.glb', out), bytes);
await fs.copyFile(new URL('tools/factory-content/export-core-outline.mjs', rootUrl), new URL('export-core-outline.mjs', out));
await fs.writeFile(new URL('source-manifest.json', out), JSON.stringify(manifest, null, 2) + '\n');
if (args.includes('--publish-prototype')) {
  const target = new URL('client/assets/prototypes/base_core_outline/', rootUrl); await fs.mkdir(target, { recursive: true });
  for (const file of ['core-outline.glb', 'source-manifest.json']) await fs.copyFile(new URL(file, out), new URL(file, target));
}
console.log(JSON.stringify({ batch, bytes: bytes.length, bounds: fullBounds, variants, ports: ports.length, published_prototype: args.includes('--publish-prototype') }));
