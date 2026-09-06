import http from 'node:http';
import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { createHash } from 'node:crypto';
const here=path.dirname(fileURLToPath(import.meta.url));
const routes=new Map();
for(const f of ['index.html','style.css','app.mjs','factory.mjs','parts.mjs','world-model.mjs'])routes.set('/'+f,path.join(here,f));
routes.set('/',path.join(here,'index.html'));
for(const f of ['three.module.js','three.core.js'])routes.set('/vendor/'+f,path.join(here,'node_modules/three/build',f));
for(const f of ['environments/RoomEnvironment.js','utils/BufferGeometryUtils.js'])routes.set('/addons/'+f,path.join(here,'node_modules/three/examples/jsm',f));
const map='{"imports":{"three":"/vendor/three.module.js","three/addons/":"/addons/"}}';
const hash=createHash('sha256').update(map).digest('base64');
export function createServer(){return http.createServer(async(req,res)=>{
  res.setHeader('Cache-Control','no-store');res.setHeader('X-Content-Type-Options','nosniff');
  res.setHeader('Content-Security-Policy',`default-src 'self'; script-src 'self' 'sha256-${hash}'; style-src 'self'; img-src 'self' data:; connect-src 'self'; frame-ancestors 'none'; base-uri 'none'`);
  if(!['GET','HEAD'].includes(req.method)){res.writeHead(405,{Allow:'GET, HEAD'});res.end('Method not allowed');return;}
  let url;try{url=new URL(req.url,'http://127.0.0.1');}catch{res.writeHead(400);res.end('Bad request');return;}
  const file=routes.get(url.pathname);if(!file){res.writeHead(404);res.end('Not found');return;}
  try{const data=await readFile(file);res.writeHead(200,{'Content-Type':file.endsWith('.html')?'text/html; charset=utf-8':file.endsWith('.css')?'text/css; charset=utf-8':'text/javascript; charset=utf-8','Content-Length':data.length});res.end(req.method==='HEAD'?undefined:data);}
  catch(error){console.error(`${url.pathname}: ${error.code}`);res.writeHead(error.code==='ENOENT'?404:500);res.end('Required local file unavailable');}
});}
if(process.argv[1]&&path.resolve(process.argv[1])===fileURLToPath(import.meta.url)){
  const port=Number(process.env.WEB_3D_PORT||4318);if(!Number.isInteger(port)||port<1024||port>65535)throw new Error('WEB_3D_PORT must be 1024–65535');
  const server=createServer();server.on('error',e=>{console.error(e.message);process.exitCode=1;});server.listen(port,'127.0.0.1',()=>console.log(`Local: http://127.0.0.1:${port}/`));
}
