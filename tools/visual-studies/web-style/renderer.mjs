import { WORLD, OBSTACLES, CONTACT, drawOrder } from './scene-model.mjs';

const loadImage = src => new Promise((resolve, reject) => {
  const img = new Image(); img.onload = () => resolve(img);
  img.onerror = () => reject(new Error(`无法读取素材：${src}`)); img.src = src;
});

// Sprite source rectangles are measured from alpha; originals remain unchanged.
function sprite(image, cell = [0, 0, image.width, image.height]) {
  const [sx, sy, w, h] = cell.map(Math.round);
  const canvas = document.createElement('canvas'); canvas.width = w; canvas.height = h;
  const ctx = canvas.getContext('2d', { willReadFrequently: true });
  ctx.drawImage(image, sx, sy, w, h, 0, 0, w, h);
  const pixels = ctx.getImageData(0, 0, w, h).data;
  let left = w, top = h, right = 0, bottom = 0;
  for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
    if (pixels[(y * w + x) * 4 + 3] > 20) {
      left = Math.min(left, x); top = Math.min(top, y); right = Math.max(right, x + 1); bottom = Math.max(bottom, y + 1);
    }
  }
  if (right <= left || bottom <= top) throw new Error('素材单元格为空');
  return { image, x: sx + left, y: sy + top, w: right - left, h: bottom - top };
}

export async function loadAssets() {
  const names = ['machine', 'pipe', 'support', 'actor', 'floor'];
  const pixelImages = await Promise.all(names.map(n => loadImage(`/pixel/${n}.png`)));
  const [atlas, actor, floor] = await Promise.all(['industrial', 'character', 'ground'].map(n => loadImage(`/assets/${n}.png`)));
  const cw = atlas.width / 3, ch = atlas.height / 2;
  const pixel = Object.fromEntries(names.map((name, i) => [name, name === 'floor' ? pixelImages[i] : sprite(pixelImages[i])]));
  const paint = { machine: sprite(atlas, [0, 0, cw, ch]), pipe: sprite(atlas, [cw, 0, cw, ch]),
    support: sprite(atlas, [cw * 2, 0, cw, ch]), actor: sprite(actor), floor };
  return { pixel, paint };
}

function drawSprite(ctx, s, x, bottom, width, height, pixel = false) {
  const ratio = Math.min(width / s.w, height / s.h);
  const w = Math.round(s.w * ratio), h = Math.round(s.h * ratio);
  ctx.imageSmoothingEnabled = !pixel;
  ctx.drawImage(s.image, s.x, s.y, s.w, s.h, Math.round(x - w / 2), Math.round(bottom - h), w, h);
}

function projectedShadow(s) {
  const c = document.createElement('canvas'); c.width = s.w; c.height = s.h;
  const ctx = c.getContext('2d');
  ctx.drawImage(s.image, s.x, s.y, s.w, s.h, 0, 0, s.w, s.h);
  ctx.globalCompositeOperation = 'source-in'; ctx.fillStyle = '#1e332e'; ctx.fillRect(0, 0, s.w, s.h);
  return c;
}

export class Renderer {
  constructor(canvas, assets, kind) {
    this.canvas = canvas; this.ctx = canvas.getContext('2d'); this.assets = assets; this.kind = kind;
    this.pixel = kind === 'pixel'; this.shadows = Object.fromEntries(['machine', 'pipe', 'support', 'actor'].map(n => [n, projectedShadow(assets[n])]));
  }

  draw(state) {
    const ctx = this.ctx, scale = this.canvas.width / WORLD.width;
    ctx.setTransform(scale, 0, 0, scale, 0, 0);
    ctx.clearRect(0, 0, WORLD.width, WORLD.height);
    ctx.save(); ctx.translate(WORLD.width / 2, WORLD.height / 2); ctx.scale(state.zoom, state.zoom); ctx.translate(-WORLD.width / 2, -WORLD.height / 2);
    ctx.imageSmoothingEnabled = !this.pixel;
    const floor = this.assets.floor;
    // The floor is supplied raster artwork, drawn as a common continuous plane.
    ctx.drawImage(floor, 0, 0, floor.width, floor.height, 0, 0, WORLD.width, WORLD.height);
    if (state.grid) this.grid(ctx);
    if (state.shadow) {
      this.shadow('machine', 80, 188, 135, 31, .23);
      this.shadow('pipe', 189, 177, 166, 14, .16);
      this.shadow('support', 205, 177, 20, 9, .22); this.shadow('support', 308, 177, 20, 9, .22);
      this.shadow('actor', Math.round(state.x - 8), Math.round(state.y - 2), 23, 8, .28);
    }
    if (state.target) {
      ctx.strokeStyle = '#f2dd9f'; ctx.lineWidth = 1;
      ctx.beginPath(); ctx.arc(state.target.x, state.target.y, 4, 0, Math.PI * 2); ctx.stroke();
    }
    for (const id of drawOrder(state.y)) {
      if (id === 'machine') drawSprite(ctx, this.assets.machine, 134, CONTACT.machine, 128, 128, this.pixel);
      if (id === 'pipe') this.pipe(state);
      if (id === 'actor') drawSprite(ctx, this.assets.actor, Math.round(state.x), Math.round(state.y), 28, 42, this.pixel);
    }
    ctx.restore();
  }

  shadow(name, x, y, w, h, alpha) {
    const ctx = this.ctx; ctx.save(); ctx.globalAlpha = alpha;
    if (!this.pixel) ctx.filter = 'blur(1.4px)';
    ctx.drawImage(this.shadows[name], x, y, w, h); ctx.restore();
  }

  pipe(state) {
    const ctx = this.ctx, a = this.assets;
    for (const x of [211, 314]) drawSprite(ctx, a.support, x, 178, this.pixel ? 23 : 38, 48, this.pixel);
    // Only the glazing changes opacity. Metal collars keep their authored opacity.
    // This finite straight specimen uses a central rectangular material region;
    // it is not a general pipe mesh, refraction model, or production asset mask.
    const x = 183, y = 128, w = 164, h = 38;
    const s = a.pipe;
    const collar = .15;
    ctx.imageSmoothingEnabled = !this.pixel;
    const segments = [[0, collar, 1], [collar, 1 - collar * 2, state.glass ? .32 : 1], [1 - collar, collar, 1]];
    for (const [start, size, alpha] of segments) {
      ctx.save(); ctx.globalAlpha = alpha;
      ctx.drawImage(s.image, s.x + s.w * start, s.y, s.w * size, s.h, Math.round(x + w * start), y, Math.ceil(w * size), h);
      ctx.restore();
    }
    if (!state.glass) {
      // Source-atop over a dedicated raster layer fills source transparency only,
      // keeping the same pipe silhouette for the opaque comparison.
      if (!this.opaquePipe) {
        const c = document.createElement('canvas'); c.width = s.w; c.height = s.h;
        const cctx = c.getContext('2d');
        cctx.drawImage(s.image, s.x, s.y, s.w, s.h, 0, 0, s.w, s.h);
        const data = cctx.getImageData(0, 0, c.width, c.height);
        for (let i = 0; i < data.data.length; i += 4) {
          if (data.data[i + 3] > 5) data.data[i + 3] = 255;
        }
        cctx.putImageData(data, 0, 0); this.opaquePipe = c;
      }
      ctx.drawImage(this.opaquePipe, x, y, w, h);
    }
  }

  grid(ctx) {
    ctx.save(); ctx.strokeStyle = '#d7e5c65c'; ctx.lineWidth = .5;
    ctx.beginPath();
    for (let x = 0; x <= WORLD.width; x += 32) { ctx.moveTo(x, 0); ctx.lineTo(x, WORLD.height); }
    for (let y = 0; y <= WORLD.height; y += 32) { ctx.moveTo(0, y); ctx.lineTo(WORLD.width, y); }
    ctx.stroke(); ctx.strokeStyle = '#e9bd70';
    for (const o of OBSTACLES) ctx.strokeRect(o.x, o.y, o.w, o.h);
    ctx.restore();
  }
}
