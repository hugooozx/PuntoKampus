
import { spawn } from 'node:child_process';
import { writeFile, mkdir } from 'node:fs/promises';
import { resolve } from 'node:path';
const delay = ms => new Promise(resolve => setTimeout(resolve, ms));
async function fetchWait(url) {
  for (let i = 0; i < 60; i++) {
    try { const r = await fetch(url, {signal: AbortSignal.timeout(700)}); if (r.ok) return r; } catch {}
    await delay(350);
  }
  throw new Error(`Unavailable: ${url}`);
}
await mkdir('.local/verificaciones', {recursive:true});
await fetchWait('http://127.0.0.1:8000/api/v1/categorias');
const apiResponses=[];
const port = 8767;
const server = spawn('python', ['scripts/abrir_demo.py','--sin-navegador','--puerto',String(port)], {windowsHide:true, stdio:'ignore'});
let browser;
try {
  const url = `http://127.0.0.1:${port}/`;
  await fetchWait(url);
  const profile = resolve('.local/verificaciones/perfil');
  browser = spawn('C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe', [
    '--headless=new','--no-first-run','--enable-unsafe-swiftshader','--remote-debugging-address=127.0.0.1',
    '--remote-debugging-port=9228',`--user-data-dir=${profile}`,'about:blank'
  ], {windowsHide:true, stdio:'ignore'});
  const r = await fetchWait('http://127.0.0.1:9228/json/list');
  const target = (await r.json()).find(x => x.type==='page');
  const ws = new WebSocket(target.webSocketDebuggerUrl);
  await new Promise((yes,no) => {ws.onopen=yes;ws.onerror=no;});
  let id = 0;
  const pending = new Map(), exceptions=[];
  ws.onmessage = e => {
    const item = JSON.parse(e.data);
    if (item.id) pending.get(item.id)?.(item);
    if(item.method==='Network.responseReceived' && item.params.response.url.includes(':8000/api/v1/')) apiResponses.push({url:item.params.response.url,status:item.params.response.status});
    if (item.method==='Runtime.exceptionThrown') exceptions.push(item.params.exceptionDetails);
  };
  const send = (method,params={}) => new Promise((yes,no) => {
    const n=++id;
    pending.set(n,msg=>{pending.delete(n);if(msg.error)no(new Error(JSON.stringify(msg.error)));else yes(msg.result);});
    ws.send(JSON.stringify({id:n,method,params}));
  });
  await send('Runtime.enable');
  await send('Network.enable');
  await send('Network.setCacheDisabled',{cacheDisabled:true});
  await send('Page.enable');
  for (const [name,width,height] of [['mobile',390,844],['desktop',1440,900]]) {
    await send('Emulation.setDeviceMetricsOverride',{width,height,deviceScaleFactor:1,mobile:false});
    const responseStart=apiResponses.length;
    await send('Page.navigate',{url});
    let loaded=false;
    for(let i=0;i<45;i++) {
      const check = await send('Runtime.evaluate',{expression:"Boolean(document.querySelector('flutter-view flt-glass-pane, flutter-view flt-scene-host, flutter-view canvas, flt-semantics-placeholder'))",returnByValue:true});
      if(check.result.value){loaded=true;break;}
      await delay(350);
    }
    if(!loaded) throw new Error('No Flutter view: '+JSON.stringify(exceptions));
    let ready=false;
    for(let retry=0;retry<80;retry++) {
      ready=['categorias','puntos-entrega','tiendas'].every(endpoint=>apiResponses.slice(responseStart).some(r=>r.url.includes('/'+endpoint)&&r.status===200));
      if(ready) break;
      await delay(250);
    }
    if(!ready) throw new Error('La API no completo la carga de '+name+': '+JSON.stringify(apiResponses.slice(responseStart)));
    await delay(1200);
    const shot=await send('Page.captureScreenshot',{format:'png'});
    await writeFile(resolve('.local/verificaciones',name+'.png'),Buffer.from(shot.data,'base64'));
    console.log(name+' rendered');
  }
  for(const endpoint of ['categorias','puntos-entrega','tiendas']) { if(!apiResponses.some(r=>r.url.includes('/'+endpoint) && r.status===200)) throw new Error('No se verifico la API: '+endpoint); }
  await writeFile(resolve('.local/verificaciones/api.json'),JSON.stringify(apiResponses,null,2));
  console.log('Respuestas API reales: '+apiResponses.length);
  ws.close();
  if(exceptions.length) throw new Error(JSON.stringify(exceptions));
} finally { browser?.kill(); server.kill(); }
