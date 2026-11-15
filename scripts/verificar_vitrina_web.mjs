
import { spawn } from 'node:child_process';
import { writeFile, mkdir, readFile } from 'node:fs/promises';
import { resolve } from 'node:path';
const delay = ms => new Promise(resolve => setTimeout(resolve, ms));
// Las respuestas de ejemplo solo se inyectan en este navegador de prueba.
// No son una entrada de la aplicación ni escriben registros en MySQL.
const withFixtures = process.argv.includes('--fixtures');
const fixture = withFixtures ? JSON.parse(await readFile('app/test/fixtures/vitrina.json', 'utf8')) : null;
const outputDir = withFixtures ? '.local/verificaciones/laminas' : '.local/verificaciones';
async function fetchWait(url) {
  for (let i = 0; i < 60; i++) {
    try { const r = await fetch(url, {signal: AbortSignal.timeout(700)}); if (r.ok) return r; } catch {}
    await delay(350);
  }
  throw new Error(`Unavailable: ${url}`);
}
await mkdir(outputDir, {recursive:true});
if (!withFixtures) await fetchWait('http://127.0.0.1:8000/api/v1/categorias');
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
    if (item.method==='Fetch.requestPaused') {
      const url = new URL(item.params.request.url);
      const path = url.pathname.split('/').filter(Boolean).slice(2);
      let data = [];
      let status = 200;
      if (path.length === 2 && path[0] === 'tiendas') {
        const shop = fixture.tiendas.find(s => s.slug === path[1]);
        data = shop ? {...shop, productos: fixture.productos.filter(p => p.tienda_id === shop.id)} : null;
        if (!shop) status = 404;
      } else {
        data = (fixture[path[0]] ?? []).map(v => path[0] === 'productos' ? {...v, tienda: fixture.tiendas.find(s => s.id === v.tienda_id)} : v);
        const fold = s => s.normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase();
        if (url.searchParams.has('buscar')) data = data.filter(v => fold(v.nombre).includes(fold(url.searchParams.get('buscar'))));
        if (url.searchParams.has('categoria')) data = data.filter(v => (v.tienda ?? v).categoria_1_id === Number(url.searchParams.get('categoria')));
      }
      send('Fetch.fulfillRequest', {requestId: item.params.requestId, responseCode: status,
        responseHeaders: [{name:'Content-Type',value:'application/json; charset=utf-8'},{name:'Access-Control-Allow-Origin',value:'*'}],
        body: Buffer.from(JSON.stringify({data, meta:{current_page:1,last_page:1,total:Array.isArray(data)?data.length:1}})).toString('base64')
      }).catch(error => exceptions.push(String(error)));
    }
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
  if (withFixtures) await send('Fetch.enable', {patterns:[{urlPattern:'http://127.0.0.1:8000/api/v1/*',requestStage:'Request'}]});
  await send('Emulation.setEmulatedMedia',{features:[{name:'prefers-reduced-motion',value:'reduce'}]});
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
    await writeFile(resolve(outputDir,name+'.png'),Buffer.from(shot.data,'base64'));
    console.log(name+' rendered');
    if (withFixtures && name === 'mobile') {
      await send('Runtime.evaluate', {expression:"document.querySelector('flt-semantics-placeholder')?.click()"});
      await delay(500);
      async function clickText(label, partial=false) {
        const result = await send('Runtime.evaluate',{expression:`(() => {
          const candidates = [...document.querySelectorAll('[role="button"]')];
          const el = candidates.find(el => {
            const text = (el.getAttribute('aria-label') || el.textContent).trim();
            return ${partial} ? text.includes(${JSON.stringify(label)}) : text === ${JSON.stringify(label)};
          });
          if (!el) return false;
          el.click(); return true;
        })()`,returnByValue:true});
        if(!result.result.value) throw new Error('Botón no encontrado: '+label);
        await delay(1200);
      }
      async function shot(name) {
        const result = await send('Page.captureScreenshot',{format:'png'});
        await writeFile(resolve(outputDir,name+'.png'),Buffer.from(result.data,'base64'));
      }
      await clickText('Productos');
      await shot('mobile-productos');
      const field = await send('Runtime.evaluate',{expression:`(() => {
        const input = document.querySelector('input'); if (!input) return false;
        const rect = input.getBoundingClientRect();
        return {x:rect.x+rect.width/2, y:rect.y+rect.height/2};
      })()`,returnByValue:true});
      if(!field.result.value) throw new Error('Buscador no encontrado');
      await send('Input.dispatchMouseEvent',{type:'mousePressed',...field.result.value,button:'left',clickCount:1});
      await send('Input.dispatchMouseEvent',{type:'mouseReleased',...field.result.value,button:'left',clickCount:1});
      await delay(400);
      await send('Input.insertText',{text:'sushi'});
      await delay(1200);
      if (!apiResponses.some(r => r.url.includes('buscar=sushi'))) throw new Error('La búsqueda no llegó al cliente HTTP');
      await shot('mobile-sin-resultados');
      await clickText('Limpiar búsqueda');
      await send('Page.navigate',{url:url+'t/dulces-de-ana'});
      await delay(1800);
      await shot('mobile-tienda');
      await send('Runtime.evaluate', {expression:"document.querySelector('flt-semantics-placeholder')?.click()"});
      await delay(300);
      await clickText('Brownie de chocolate',true);
      await shot('mobile-producto');
    }
  }
  for(const endpoint of ['categorias','puntos-entrega','tiendas']) { if(!apiResponses.some(r=>r.url.includes('/'+endpoint) && r.status===200)) throw new Error('No se verifico la API: '+endpoint); }
  await writeFile(resolve(outputDir,'api.json'),JSON.stringify(apiResponses,null,2));
  console.log((withFixtures ? 'Respuestas de prueba aisladas: ' : 'Respuestas API reales: ')+apiResponses.length);
  ws.close();
  if(exceptions.length) throw new Error(JSON.stringify(exceptions));
} finally { browser?.kill(); server.kill(); }
