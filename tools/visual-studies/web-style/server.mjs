import http from 'node:http';
import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(here, '../../..');
const routes = new Map();
for (const name of ['index.html', 'style.css', 'app.mjs', 'renderer.mjs', 'scene-model.mjs']) routes.set(`/${name}`, path.join(here, name));
routes.set('/', path.join(here, 'index.html'));
for (const name of ['industrial', 'character', 'ground']) routes.set(`/assets/${name}.png`, path.join(here, `assets/${name}.png`));
for (const name of ['machine', 'pipe', 'support', 'machine_shadow', 'pipe_shadow', 'support_shadow']) {
  routes.set(`/pixel/${name}.png`, path.join(repo, `client/assets/sprites/visual_studies/industrial_volume_v1/${name}.png`));
}
routes.set('/pixel/actor.png', path.join(repo, 'client/assets/sprites/demo_presentation_rebuild/player_engineer.png'));
routes.set('/pixel/floor.png', path.join(repo, 'client/assets/tiles/demo_presentation_rebuild/metal_platform_floor.png'));
const mime = { '.html': 'text/html; charset=utf-8', '.css': 'text/css; charset=utf-8', '.mjs': 'text/javascript; charset=utf-8', '.png': 'image/png' };

export function createServer() {
  return http.createServer(async (req, res) => {
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('Cache-Control', 'no-store');
    res.setHeader('Content-Security-Policy', "default-src 'self'; img-src 'self' data:; script-src 'self'; style-src 'self'; connect-src 'self'; frame-ancestors 'none'; base-uri 'none'");
    if (!['GET', 'HEAD'].includes(req.method)) { res.writeHead(405, { Allow: 'GET, HEAD' }); res.end('Method not allowed'); return; }
    let pathname;
    try { pathname = new URL(req.url, 'http://127.0.0.1').pathname; }
    catch { res.writeHead(400); res.end('Bad request'); return; }
    const file = routes.get(pathname);
    if (!file) { res.writeHead(404); res.end('Not found'); return; }
    try {
      const body = await readFile(file);
      res.writeHead(200, { 'Content-Type': mime[path.extname(file)], 'Content-Length': body.length });
      res.end(req.method === 'HEAD' ? undefined : body);
    } catch (error) {
      console.error(`Cannot serve ${pathname}: ${error.code}`);
      res.writeHead(error.code === 'ENOENT' ? 404 : 500); res.end('Local asset unavailable');
    }
  });
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const port = Number(process.env.WEB_STYLE_PORT || 4317);
  if (!Number.isInteger(port) || port < 1024 || port > 65535) throw new Error('WEB_STYLE_PORT must be 1024–65535');
  const server = createServer();
  server.on('error', error => { console.error(error.message); process.exitCode = 1; });
  server.listen(port, '127.0.0.1', () => console.log(`Local: http://127.0.0.1:${port}/`));
}
