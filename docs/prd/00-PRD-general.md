# PRD general de PuntoKampus

Versión 1.1, 12 de noviembre de 2026. Aprobado por el dueño del producto.

## 1. Qué es

PuntoKampus es una vitrina digital para los negocios de los estudiantes de la Universidad Técnica de Babahoyo (UTB). El estudiante que vende publica su tienda y sus productos. Cualquier persona de la comunidad universitaria la encuentra, hace un pedido y lo recibe en un punto del campus. El pago no pasa por la plataforma: va directo del comprador al vendedor, en efectivo, por transferencia o por Deuna.

## 2. El problema que resuelve

Hoy los estudiantes que venden comida, postres, ropa, accesorios o servicios se promocionan de boca en boca o con mensajes sueltos en grupos de WhatsApp, donde la publicación se pierde entre muchas otras. Varios recorren aulas y pasillos con la mercadería entre clases. Quien quiere comprar no sabe quién vende lo que busca dentro de la universidad, ni tiene cómo comprobar que el vendedor es un estudiante real.

PuntoKampus junta a todos esos vendedores en un solo lugar y deja entrar solo con correo institucional, así que cada tienda pertenece a un estudiante verificado.

## 3. Quién la usa

| Usuario | Quién es | Qué necesita |
|---|---|---|
| Comprador | Estudiante de la UTB con correo institucional | Encontrar rápido quién vende lo que busca, pedir sin escribir todo a mano y saber que el vendedor es real |
| Vendedor | Estudiante de la UTB con un negocio propio | Mostrar sus productos a toda la universidad, recibir pedidos ordenados y dejar de recorrer aulas |
| Administrador | El equipo de PuntoKampus | Vigilar las tiendas, atender reportes y activar los planes pagados |
| Visitante | Cualquier persona con el enlace o el QR de una tienda | Ver la tienda. No puede pedir |

Una misma cuenta puede comprar y, si crea una tienda, también vender. Cada cuenta tiene como máximo una tienda.

## 4. Cómo se accede

- Solo entran correos que terminan en `utb.edu.ec`, incluidos los subdominios como `fafi.utb.edu.ec`.
- Para registrarse y para entrar, la persona escribe su correo y recibe un **código de 6 dígitos**. No hay contraseñas. La sesión se mantiene abierta en el dispositivo hasta que la persona salga.
- Perfil del vendedor: nombres, código de estudiante, facultad, carrera, semestre y número de WhatsApp. No se pide cédula.
- Al iniciar cada periodo académico se vuelve a verificar el correo. Si ya no existe (graduado o retirado), la cuenta se desactiva.
- El WhatsApp del vendedor solo se muestra al público si él lo decide.
- Los negocios externos no venden. Pueden comprar un espacio publicitario (tramo 2).

## 5. Funciones por tramo

### Tramo 1: para la semana 9 (primera entrega de Emprendimiento)

| Función | Qué hace |
|---|---|
| Registro y entrada | Con correo institucional y código de 6 dígitos |
| Tienda | El vendedor crea y edita su tienda: nombre, logo, descripción, hasta 2 categorías, horario y punto de entrega |
| Productos | Nombre, fotos, precio, descripción y "disponible" o "agotado" |
| Vitrina | Lista de tiendas y productos por categoría, con búsqueda |
| Enlace público de la tienda | Cualquiera lo puede abrir y ver la tienda. Para pedir hay que entrar con correo UTB |
| Pedido | El comprador arma el carrito con productos de **una sola tienda**, elige punto, hora y forma de pago. El pedido **se guarda en la base de datos** con estado "Pendiente" y después se abre WhatsApp con el mensaje armado para el vendedor |
| Pedidos del vendedor | El vendedor ve sus pedidos y los marca como "Entregado" o "Cancelado". Si pasan 24 horas desde la hora de entrega y nadie hizo nada, el pedido pasa a "Vencido" |
| Mis pedidos (comprador) | El comprador ve sus pedidos y su estado, y puede cancelar uno pendiente |
| Reportar tienda | Botón en cada tienda. El comprador elige un motivo y puede escribir un detalle |
| Plan Premium | El vendedor paga por transferencia o Deuna, sube la foto del comprobante y escribe el número. El administrador lo revisa y activa o rechaza con un motivo |
| Insignias | Toda tienda del plan gratis muestra "Matriculado". La tienda Premium muestra "Sacó 10" |
| Beneficios Premium | Insignia "Sacó 10", portada propia de la tienda y pedidos registrados sin límite |
| Panel del administrador | Web, solo para el equipo: tiendas (dar de baja con motivo y reactivar), reportes, solicitudes Premium, usuarios, pedidos (solo lectura), categorías y puntos de entrega |
| Privacidad | Aceptación de la política de privacidad al registrarse, política visible dentro de la app y opción de borrar la cuenta |

### Tramo 2: antes de la feria (propuesta, puede cambiar según la prueba piloto)

| Función | Qué hace |
|---|---|
| Confirmación de entrega | El comprador escanea el QR del vendedor, o el vendedor escribe el código de 4 dígitos que ve el comprador. Se bloquea tras 5 intentos fallidos. Reemplaza al "Entregado" manual del tramo 1 |
| Estrellas | De 1 a 5, sin comentarios. Solo con un pedido entregado y una vez por pedido. La tienda muestra el promedio |
| Tarjeta QR imprimible | Logo, nombre, descripción corta, QR, punto de entrega y horario |
| Métricas del vendedor | Ventas por semana, ganancia y margen por producto, horas y puntos con más pedidos |
| Exportar a Excel | Solo Premium |
| Existencias exactas | La cantidad se descuenta sola al entregar. Solo Premium |
| Destacados | El vendedor paga para aparecer primero en su categoría, con la etiqueta "Destacado" |
| Espacio publicitario | Para negocios de fuera de la universidad, con la etiqueta "Publicidad" |
| Notificaciones | Aviso de pedido nuevo al vendedor y de cambio de estado al comprador |
| Google Play | Prueba cerrada de 14 días con al menos 12 personas y solicitud de publicación |

### Fuera de la versión 1.0

Pagos dentro de la app, reseñas escritas, app para iPhone en la App Store, otras universidades y cobro automático de los planes.

## 6. Arquitectura

```
 App Android (Flutter) ─┐
 Versión web (Flutter) ─┼──► Servidor Laravel (API) ──► PostgreSQL
 Panel admin (Filament) ┘          │
                                   ├──► Correo (envía el código de 6 dígitos)
                                   └──► Archivos (fotos y comprobantes)
 Pedido ──► se guarda primero ──► se abre WhatsApp con el mensaje armado
```

| Pieza | Decisión | Por qué |
|---|---|---|
| App y versión web | Flutter, un solo código | No se programa dos veces |
| Servidor | Laravel (PHP) con una API REST que responde en JSON | Trae resueltos el inicio de sesión, el envío de correos, la subida de archivos y la protección básica. Uno de los dos programadores ya lo usó |
| Inicio de sesión de la API | Laravel Sanctum (tokens) | Es el complemento de Laravel pensado para apps móviles |
| Base de datos | PostgreSQL | Elegida por el equipo. Los dos programadores la conocen |
| Panel del administrador | Filament, dentro del mismo Laravel | Arma tablas, filtros y botones de acción en días |
| WhatsApp | Enlace `https://wa.me/<número>?text=<mensaje>` | Funciona en Android y en el navegador, y no necesita ningún permiso de WhatsApp |
| Fotos | Se reducen de tamaño antes de subirlas | Celulares con poca memoria y datos móviles limitados |
| Servidor en internet | Un servidor pequeño con PHP y PostgreSQL | Debe entrar en los $15 al mes del presupuesto |

**Lo que se sacrifica con esta elección.** Laravel obliga a programar y mantener la API a mano. Una opción como Supabase daba eso hecho, pero el panel del administrador habría que construirlo desde cero, y nadie del equipo la ha usado. La versión web de Flutter tarda más en abrir la primera vez que una página web común, porque descarga la app completa. Con conexiones lentas puede notarse: hay que medirlo en la semana 4.

**Qué revisar si la plataforma crece.** Si llega a otras universidades o pasa de unos cientos de usuarios activos: guardar las fotos en un servicio de archivos externo, agregar una cola para los correos y separar el panel del administrador del servidor principal.

## 7. Requisitos generales

| Requisito | Cómo se cumple |
|---|---|
| Funciona en celulares Android de gama baja | Se prueba cada viernes en el celular Android más sencillo del equipo |
| La versión web funciona en el navegador del celular | Se prueba en Chrome de Android y en Safari de iPhone |
| Todo en español | Textos, mensajes de error y correos |
| Conexión segura | HTTPS en todo el servidor |
| Datos personales | Se cumple la Ley Orgánica de Protección de Datos Personales del Ecuador y la política de Datos del Usuario de Google Play. Detalle en `05-privacidad-y-google-play.md` |
| Comprobantes de pago | Solo los ve el administrador. La imagen se borra después de un plazo que se fija en el documento de privacidad |
| Copia de seguridad | Copia diaria de la base de datos |
| El correo con el código llega | Se prueba con correos institucionales reales desde la primera semana, incluida la carpeta de spam |

## 8. Reglas de publicación

Una tienda se publica apenas se crea. El equipo la vigila y la da de baja si vende algo de esta lista. El motivo de la baja es obligatorio y el vendedor lo ve.

No se puede vender:

- Alcohol, cigarrillos (también vapeadores) ni drogas
- Medicamentos
- Armas
- Productos falsificados o robados
- Contenido sexual
- Apuestas ni rifas
- Tareas, trabajos, exámenes o tesis hechos para que otra persona los entregue como propios

Sí se permiten los servicios que no reemplazan el trabajo del estudiante: tutorías, clases de refuerzo, impresiones, diseño y corrección de estilo.

Los reportes los revisa el dueño del producto, en un plazo de 24 horas.

## 9. Lo que la plataforma debe poder medir para la prueba piloto

La guía de Emprendimiento pide resultados con al menos 10 clientes reales: conversión, disposición a pagar y la decisión de seguir igual o cambiar. La base de datos tiene que permitir sacar, por semana:

| Dato | Para qué sirve |
|---|---|
| Tiendas creadas y productos publicados | Saber si los vendedores llegan a publicar |
| Pedidos registrados, entregados, cancelados y vencidos | Conversión: cuántos pedidos terminan en venta |
| Compradores distintos que hicieron al menos un pedido | Alcance real |
| Solicitudes Premium enviadas y aprobadas | Disposición a pagar con dinero real |
| Reportes recibidos | Si las reglas de publicación funcionan |

Estos datos se sacan con consultas desde el panel del administrador. No hace falta una pantalla de gráficos en el tramo 1.

## 10. Decisiones cerradas

| Fecha | Decisión |
|---|---|
| 5/11/2026 | La tarjeta del vendedor es solo con código QR (indicación del docente de Emprendimiento) |
| 12/11/2026 | App para Android en Google Play más versión web completa, hechas con Flutter |
| 12/11/2026 | Servidor en Laravel, base de datos PostgreSQL, panel del administrador con Filament |
| 12/11/2026 | Las tiendas se publican sin aprobación previa; se vigilan y se dan de baja con motivo |
| 12/11/2026 | Premium con comprobante en el tramo 1; incluye insignia, portada propia y pedidos sin límite |
| 12/11/2026 | Estrellas sin comentarios en el tramo 2 |
| 12/11/2026 | Los pedidos se guardan en la base de datos desde el tramo 1 (pedido del equipo) |
| 12/11/2026 | "Aparecer primero" en la categoría es solo para los destacados pagados |
| 12/11/2026 | Insignia del plan gratis: "Matriculado" (reemplaza a "Aprobado", porque las tiendas ya no se aprueban) |
| 12/11/2026 | Una cuenta compra y vende; entrada sin contraseña con código por correo; pedido de una sola tienda; en el tramo 1 el vendedor marca "Entregado" a mano |
| 12/11/2026 | Regla sobre trabajos académicos de la sección 8 |

## 11. Pendientes

| Tema | Qué falta | Quién lo decide |
|---|---|---|
| Límite de 15 pedidos al mes del plan gratis | Si se mantiene, cambia o se quita. Se resuelve al rehacer el modelo de negocio. Mientras tanto, el límite se programa como un valor configurable, desactivado | Dueño del producto |
| Precio del Premium | Se recalcula con el modelo de negocio | Dueño del producto y líder financiero |
| Lista inicial de categorías y puntos de entrega | Se cargan desde el panel. Los puntos preferidos saldrán de la encuesta | Dueño del producto |

## Fuentes

- Google. (s. f.-a). *Información sobre los requisitos de eliminación de cuentas de aplicaciones de Google Play*. Ayuda de Play Console. Recuperado el 12 de noviembre de 2026, de https://support.google.com/googleplay/android-developer/answer/13327111?hl=es
- Google. (s. f.-b). *Datos del usuario*. Ayuda de Play Console. Recuperado el 12 de noviembre de 2026, de https://support.google.com/googleplay/android-developer/answer/10144311?hl=es-419
- Google. (s. f.-c). *App testing requirements for new personal developer accounts*. Play Console Help. Recuperado el 10 de noviembre de 2026, de https://support.google.com/googleplay/android-developer/answer/14151465
