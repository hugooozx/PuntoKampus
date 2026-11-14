# Alcance del tramo 1

Versión 1, 12 de noviembre de 2026. Fecha límite: semana 9 del periodo, primera entrega de Emprendimiento *(fecha exacta por confirmar con el calendario académico)*.

## Para qué es este tramo

Que vendedores y compradores reales de la UTB puedan usar PuntoKampus en la prueba piloto. Un vendedor crea su tienda, un comprador le pide algo y el pedido queda registrado. También tiene que poder medirse si alguien paga el Premium con dinero real.

## Entra

1. Registro y entrada con correo institucional y código de 6 dígitos.
2. Tienda del vendedor: crear y editar.
3. Productos con fotos, precio y "disponible" o "agotado".
4. Vitrina por categorías, con búsqueda.
5. Enlace público de cada tienda.
6. Pedido de una sola tienda: se guarda en la base de datos y luego se abre WhatsApp con el mensaje armado.
7. Lista de pedidos del vendedor (marcar entregado o cancelado) y del comprador (ver estado, cancelar). Paso automático a "Vencido" 24 horas después de la hora de entrega.
8. Botón "reportar tienda".
9. Solicitud de Premium con foto y número del comprobante. Beneficios: insignia, portada propia y pedidos sin límite.
10. Panel del administrador: tiendas, bajas con motivo, reportes, solicitudes Premium, usuarios, pedidos, categorías y puntos de entrega.
11. Política de privacidad aceptada al registrarse y visible en la app. Opción de borrar la cuenta.

## No entra

Confirmación de entrega con QR o código, estrellas, tarjeta QR imprimible, métricas y Excel, existencias exactas, destacados, publicidad, notificaciones y publicación en Google Play. Todo eso es del tramo 2.

Si aparece una idea nueva durante el tramo 1, se anota para el tramo 2. No se agrega sin la aprobación del dueño del producto.

## Quién hace qué

| Parte | Responsable |
|---|---|
| Servidor Laravel, base de datos PostgreSQL y panel Filament | Quien programa el servidor |
| App Flutter (Android y versión web) | Quien programa la app |
| Aprobar los documentos, revisar cada viernes y atender los reportes | Dueño del producto |

## Terminado significa

- Cada función de la lista "Entra" pasa su prueba de `02-historias-tramo-1.md`, en un celular Android y en el navegador de un celular.
- La plataforma está en un servidor en internet y se abre con un enlace. No vale que funcione solo en la computadora de quien programa.
- La app de Android se puede instalar en los celulares del piloto (instalación directa, sin esperar a Google Play).
- El correo con el código llega a correos institucionales reales.
- Alguien que no es del equipo crea una tienda y hace un pedido sin ayuda.

## Calendario del tramo

| Semana | Meta del viernes |
|---|---|
| 3 (16 al 20 nov) | Documentos de requisitos aprobados. Servidor y proyecto de Flutter creados |
| 4 | Registro y entrada con el código funcionando de punta a punta |
| 5 | Tienda, productos y vitrina |
| 6 | Pedido guardado más WhatsApp, y lista de pedidos |
| 7 | Reportes, Premium, panel del administrador y privacidad. Prueba con personas de fuera del equipo |
| 8 | Prueba piloto con al menos 10 clientes reales |
| 9 | Primera entrega |

El detalle de cada ciclo va en `06-plan-de-trabajo.md`.

## Riesgos

| Riesgo | Qué se hace |
|---|---|
| Aprender Flutter y Laravel a tiempo | Cada uno empieza por la parte que ya conoce; la IA ayuda en la otra |
| El correo con el código cae en spam o no llega | Se prueba en la semana 4 con correos UTB reales |
| La versión web de Flutter tarda en abrir con datos móviles | Se mide en la semana 4. Si tarda demasiado, se decide qué hacer antes de seguir |
| Las semanas 8 y 9 caen en vacaciones | Confirmar el calendario académico. Si hay vacaciones, el piloto se adelanta a la semana 7 |
