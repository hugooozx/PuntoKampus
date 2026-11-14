# Plan de trabajo del tramo 1

Versión 1, 12 de noviembre de 2026. Semana 3 del periodo = 16 al 20 de noviembre. Las semanas 8 y 9 se confirman con el calendario académico.

## Cómo funciona cada semana

| Día | Qué pasa |
|---|---|
| Lunes | Cada uno sabe qué historias le tocan en la semana (tabla de abajo) |
| Miércoles | Mensaje corto al grupo: qué ya funciona, qué falta, en qué está trabado |
| Viernes | Demostración: se muestra lo hecho **en un celular Android y en el navegador de un celular**, con el servidor en internet. El dueño del producto pasa la lista de revisión |

Mensaje del miércoles (copiar y llenar):

```
Servidor / App (borrar uno)
Ya funciona: ...
Me falta: ...
Estoy trabado en: ... (o "nada")
```

Regla de oro: si algo está trabado más de un día, se avisa ese mismo día. No se espera al viernes.

## Qué se hace cada semana

| Semana | Servidor (Laravel, PostgreSQL, Filament) | App (Flutter) | Viernes se muestra |
|---|---|---|---|
| 3 | Proyecto Laravel creado y subido a un servidor en internet con HTTPS. Base de datos con las tablas de `04`. Envío de correos configurado | Proyecto Flutter creado, compilando para Android y web. Navegación con la barra inferior y pantallas vacías | Una página del servidor abierta desde el celular; la app instalada mostrando las 4 secciones |
| 4 | `/auth/codigo`, `/auth/verificar`, `/auth/salir`, `/yo`. Pruebas de las reglas R1 a R5 | P01 a P04 y P13 conectadas al servidor | H01, H02 y H03 de punta a punta. Prueba con 3 correos UTB reales. Medir cuánto tarda en abrir la versión web con datos móviles |
| 5 | Tiendas, productos y fotos (`/mi-tienda...`), vitrina y búsqueda (`/tiendas`, `/productos`). Panel: categorías y puntos de entrega | P05 a P08, P14 a P16 | H05 a H12 |
| 6 | `/pedidos`, pedidos del vendedor, mensaje de WhatsApp, tarea de vencidos | P09 a P12 y P17 | H13 a H18 |
| 7 | Reportes, Premium, borrado de cuenta, `/privacidad` y `/borrar-cuenta`. Panel: tiendas, reportes, solicitudes, usuarios, pedidos, configuración, resumen del piloto | P18 a P22 | H04, H19 a H27. **Prueba con 3 personas de fuera del equipo, sin ayuda** |
| 8 | Arreglos de lo que salió en la prueba | Arreglos | Prueba piloto con al menos 10 clientes reales |
| 9 | | | Primera entrega de Emprendimiento |

En la semana 3 el dueño del producto aprueba estos documentos, y el equipo define el logo y los colores (para aplicarlos en la semana 4).

## Lista de revisión del viernes

El dueño del producto la pasa con el celular en la mano. No hace falta leer código. Cada pregunta se responde **sí** o **no**; un "no" vuelve a la lista de la semana siguiente, antes que cualquier cosa nueva.

### Semana 3
- ¿Abro una página del servidor desde mi celular, con el candado de HTTPS?
- ¿La app se instala en un Android y abre?
- ¿La versión web abre en el navegador del celular?

### Semana 4
- ¿Me llega el código a mi correo UTB en menos de 2 minutos? ¿Llegó a la bandeja principal o a spam?
- ¿Con un correo de Gmail me sale el error y no me llega nada?
- ¿Al equivocarme 5 veces de código, me pide uno nuevo?
- ¿Al cerrar y abrir la app, sigo dentro?
- ¿Cuántos segundos tarda la versión web en abrir con datos móviles? (anotar el número)

### Semana 5
- ¿Creo una tienda y aparece de inmediato en la vitrina con "Matriculado"?
- ¿Subo una foto tomada con el celular y se ve bien?
- ¿Marco un producto "Agotado" y nadie lo puede agregar al carrito?
- ¿Busco "EMPANADA" y "empanada" y me sale lo mismo?
- ¿Abro el enlace de mi tienda desde un celular sin sesión y la veo?

### Semana 6
- ¿Hago un pedido y se abre WhatsApp con el mensaje completo y bien escrito?
- ¿El pedido aparece en "Mis pedidos" y en "Pedidos de mi tienda" del vendedor?
- ¿Si el vendedor agota un producto mientras pido, me avisa cuál?
- ¿Puedo pedirle a mi propia tienda? (debe ser **no**)
- ¿El vendedor marca "Entregado" y yo lo veo?

### Semana 7
- ¿Reporto una tienda y el reporte aparece en el panel?
- ¿Doy de baja una tienda desde el panel y desaparece de la vitrina? ¿El vendedor ve el motivo?
- ¿Mando un comprobante, lo apruebo en el panel y aparece "Sacó 10" y la portada?
- ¿Al intentar aprobar dos veces el mismo número de comprobante, el panel lo impide?
- ¿Borro una cuenta de prueba y desaparecen su tienda y sus productos?
- ¿Tres personas de fuera del equipo crearon una tienda o hicieron un pedido sin que nadie les explicara?

## Si no alcanza el tiempo

Se recorta en este orden, de lo primero que se deja para después a lo último:

1. Portada Premium (queda solo la insignia)
2. Resumen del piloto en el panel (los números se sacan con consultas directas a la base)
3. Búsqueda (queda solo la navegación por categorías)
4. Cancelar pedido desde el comprador

Nunca se recortan: entrar con correo UTB, tienda y productos, vitrina, pedido guardado con WhatsApp, Premium con comprobante (se necesita para medir la disposición a pagar), reportar, dar de baja y borrar la cuenta (lo exige Google Play).

## Terminado significa

Ver "Terminado significa" en `01-alcance-tramo-1.md`.
