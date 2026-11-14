# Datos, reglas y API del tramo 1

Versión 1, 12 de noviembre de 2026. Este documento es el acuerdo entre quien programa el servidor y quien programa la app. Si uno necesita cambiar algo de aquí, lo avisa al otro y al dueño del producto antes de hacerlo.

Los nombres de tablas, campos y rutas van en español y sin tildes, tal como están escritos aquí.

## 1. Tablas

### usuarios

| Campo | Tipo | Regla |
|---|---|---|
| id | bigint | Clave |
| correo | texto, único | Termina en `utb.edu.ec` o en un subdominio (`fafi.utb.edu.ec`). Se guarda en minúsculas |
| nombres | texto | Obligatorio |
| codigo_estudiante | texto | Solo vendedores |
| facultad, carrera | texto | Solo vendedores |
| semestre | entero 1 a 10 | Solo vendedores |
| whatsapp | texto | Solo vendedores. Se guarda en formato internacional: `09XXXXXXXX` se convierte en `5939XXXXXXXX` |
| mostrar_whatsapp | booleano | Falso por defecto. Si es verdadero, el número aparece en la tienda pública |
| es_admin | booleano | Falso por defecto. Solo se cambia desde la base de datos o el panel |
| acepto_privacidad_en | fecha y hora | Obligatorio para usar la plataforma |
| estado | `activa` o `desactivada` | |
| creado_en, actualizado_en | fecha y hora | |

El comprador solo necesita correo y nombres. Los demás datos se piden cuando la persona crea una tienda. Se pide lo mínimo, como manda la ley de datos (ver `05`).

### codigos_acceso

| Campo | Tipo | Regla |
|---|---|---|
| id | bigint | |
| correo | texto | |
| codigo_hash | texto | Nunca se guarda el código en claro |
| expira_en | fecha y hora | 10 minutos después de enviarlo |
| intentos | entero | Máximo 5. Al quinto fallo el código deja de servir |
| usado_en | fecha y hora | Un código se usa una sola vez |

### tiendas

| Campo | Tipo | Regla |
|---|---|---|
| id | bigint | |
| usuario_id | bigint, único | Una tienda por cuenta |
| nombre | texto, 3 a 40 caracteres | |
| slug | texto, único | Sale del nombre (`dulces-de-ana`). Forma el enlace público |
| descripcion | texto, hasta 300 caracteres | |
| logo_url | texto | Opcional |
| portada_url | texto | Solo Premium |
| categoria_1_id | bigint | Obligatoria |
| categoria_2_id | bigint | Opcional, distinta de la primera |
| horario | texto, hasta 100 caracteres | Libre en el tramo 1, por ejemplo "Lunes a viernes, 8:00 a 14:00" |
| punto_entrega_id | bigint | Punto de entrega habitual |
| plan | `gratis` o `premium` | `gratis` por defecto |
| premium_hasta | fecha | Fin del periodo académico pagado |
| estado | `activa` o `dada_de_baja` | `activa` al crearse |
| motivo_baja | texto | Obligatorio si está dada de baja |
| dada_de_baja_en | fecha y hora | |

### categorias y puntos_entrega

Las dos tablas tienen `id`, `nombre`, `activa` y `orden`. `puntos_entrega` agrega `descripcion` (por ejemplo, "Junto a la puerta principal"). Se manejan desde el panel.

Lista inicial de categorías *(propuesta, se cambia desde el panel)*: Comida, Postres y dulces, Bebidas, Ropa y accesorios, Tecnología, Útiles y papelería, Servicios, Otros.

Puntos de entrega iniciales: la biblioteca y la entrada de cada facultad. La lista definitiva sale de la encuesta.

### productos y producto_fotos

| Campo | Tipo | Regla |
|---|---|---|
| id | bigint | |
| tienda_id | bigint | |
| nombre | texto, 3 a 60 caracteres | |
| descripcion | texto, hasta 300 caracteres | Opcional |
| precio | numérico (8,2) | Mayor que 0 y hasta 500 |
| disponible | booleano | Verdadero por defecto |
| eliminado_en | fecha y hora | Borrado suave: el producto desaparece, pero los pedidos viejos lo siguen mostrando |

`producto_fotos`: `id`, `producto_id`, `url`, `orden`. Hasta 3 fotos por producto. El servidor guarda cada foto con un máximo de 1080 px por lado.

### pedidos y pedido_items

| Campo | Tipo | Regla |
|---|---|---|
| id | bigint | |
| codigo | texto, único | Corto y legible: `PK-000123` |
| comprador_id | bigint | |
| tienda_id | bigint | |
| punto_entrega_id | bigint | |
| hora_entrega | fecha y hora | Desde 30 minutos después de hacer el pedido hasta 7 días después |
| forma_pago | `efectivo`, `transferencia` o `deuna` | |
| nota | texto, hasta 200 caracteres | Opcional |
| total | numérico (8,2) | Lo calcula el servidor, nunca la app |
| estado | `pendiente`, `entregado`, `cancelado` o `vencido` | |
| cancelado_por | `comprador`, `vendedor` o `sistema` | |
| estado_cambiado_en | fecha y hora | |

`pedido_items`: `id`, `pedido_id`, `producto_id`, `nombre_producto`, `precio_unitario`, `cantidad` (1 a 20) y `subtotal`. El nombre y el precio se **copian** al momento del pedido, para que el historial no cambie si después el vendedor cambia el precio.

### reportes

| Campo | Tipo | Regla |
|---|---|---|
| id | bigint | |
| tienda_id | bigint | |
| reportado_por | bigint | Usuario que reporta |
| motivo | `prohibido`, `no_entrego`, `informacion_falsa`, `trato_inadecuado` u `otro` | |
| detalle | texto, hasta 300 caracteres | Obligatorio si el motivo es `otro` |
| estado | `nuevo`, `sin_accion` o `tienda_dada_de_baja` | |
| revisado_por, revisado_en, nota_admin | | Se llenan al revisarlo |

### solicitudes_premium

| Campo | Tipo | Regla |
|---|---|---|
| id | bigint | |
| tienda_id | bigint | |
| numero_comprobante | texto | Obligatorio |
| monto | numérico (8,2) | El que declara el vendedor |
| foto_comprobante | texto | Ruta privada: no se puede abrir con un enlace público |
| estado | `pendiente`, `aprobada` o `rechazada` | |
| motivo_rechazo | texto | Obligatorio si se rechaza |
| revisado_por, revisado_en | | |
| foto_borrada_en | fecha y hora | Cuándo se borró la imagen (ver `05`) |

### configuracion

Una sola fila que se edita desde el panel: precio del Premium, datos de la cuenta donde se paga (banco, tipo de cuenta, número, titular, usuario de Deuna), fecha de fin del periodo académico, días que se guarda la foto del comprobante y `limite_pedidos_gratis` (vacío = sin límite; **vacío en el tramo 1**).

## 2. Reglas del negocio

### Acceso

1. Solo se aceptan correos de `utb.edu.ec` y sus subdominios. Cualquier otro correo recibe un error y no se envía nada.
2. Para pedir un código nuevo hay que esperar 60 segundos. Máximo 5 códigos por correo cada hora.
3. Si el correo no tiene cuenta, al verificar el código se crea. La persona completa sus nombres y acepta la política de privacidad antes de seguir.
4. La sesión dura hasta que la persona sale o hasta el fin del periodo académico. Al empezar el periodo nuevo vuelve a entrar con un código, y así se comprueba que su correo institucional sigue existiendo.
5. Una cuenta `desactivada` no puede entrar.

### Tiendas

6. Al crear la tienda se piden los datos de vendedor (código de estudiante, facultad, carrera, semestre y WhatsApp) si la cuenta no los tiene.
7. La tienda se publica apenas se crea. No hay aprobación previa.
8. Una tienda `dada_de_baja` no aparece en la vitrina ni en la búsqueda. Su enlace público muestra "Esta tienda no está disponible". Sus pedidos pendientes pasan a `cancelado`, con `cancelado_por = sistema`. El vendedor ve el motivo al entrar.
9. Solo el administrador da de baja y reactiva.
10. La portada solo se puede subir si la tienda es Premium. Si el Premium vence, la portada deja de mostrarse, pero no se borra.

### Pedidos

11. Un pedido es de una sola tienda. Todos sus productos tienen que ser de esa tienda y estar disponibles.
12. Nadie puede pedirle a su propia tienda.
13. No se puede pedir a una tienda dada de baja.
14. El servidor calcula el total con los precios del momento. Si un producto ya no está disponible, rechaza el pedido y dice cuál es.
15. El pedido se guarda con estado `pendiente` **antes** de abrir WhatsApp. El servidor devuelve el enlace de WhatsApp ya armado.
16. El comprador puede cancelar solo si el pedido sigue `pendiente`.
17. El vendedor puede marcar `entregado` o `cancelado` solo si el pedido sigue `pendiente`.
18. A las 24 horas de la `hora_entrega`, si sigue `pendiente`, pasa a `vencido` (tarea automática cada hora).
19. `limite_pedidos_gratis` está vacío en el tramo 1. Si el dueño del producto lo activa más adelante, antes se define qué pasa al llegar al límite.

### Mensaje de WhatsApp

El servidor lo arma así (con los datos reales):

```
Hola, soy Ana Pérez. Te hice un pedido por PuntoKampus (PK-000123):
- 2 x Empanada de queso: $3.00
- 1 x Jugo de naranja: $1.00
Total: $4.00
Entrega: Biblioteca, jueves 19/11 a las 10:30
Pago: Transferencia
Nota: sin cebolla, por favor
```

Enlace: `https://wa.me/5939XXXXXXXX?text=<mensaje codificado para URL>`.

### Reportes

20. Una persona puede reportar la misma tienda una vez cada 24 horas.
21. No se puede reportar la tienda propia.
22. El dueño del producto revisa cada reporte en 24 horas. Si da de baja la tienda, el reporte queda en `tienda_dada_de_baja`. Si no, queda en `sin_accion`, con una nota.

### Premium

23. Una tienda tiene como máximo una solicitud `pendiente` a la vez.
24. El número de comprobante no puede repetirse en otra solicitud aprobada. Así nadie usa dos veces el mismo pago.
25. Al aprobar, la tienda pasa a `premium` y `premium_hasta` toma la fecha de fin del periodo de la configuración.
26. Al rechazar, el motivo es obligatorio y el vendedor lo ve.
27. Cuando `premium_hasta` pasa, la tienda vuelve a `gratis` (tarea automática diaria).
28. La foto del comprobante solo la ven los administradores, y se borra según el plazo de `05`.

### Borrar la cuenta

29. Se puede borrar desde la app (Cuenta → Borrar mi cuenta, con un código de confirmación) y desde la página web `/borrar-cuenta`.
30. Al borrar: se eliminan los datos personales, la tienda, los productos, las fotos y los comprobantes. En los pedidos que la persona tuvo con otros, su nombre se reemplaza por "Usuario eliminado", para que la otra parte conserve su historial.
31. Se hace al momento. La ley da 15 días como máximo.

## 3. Quién puede hacer qué

| Acción | Visitante | Comprador | Vendedor | Admin |
|---|---|---|---|---|
| Ver vitrina, tiendas y productos | Sí | Sí | Sí | Sí |
| Hacer un pedido | No | Sí | Sí (a otras tiendas) | Sí |
| Reportar una tienda | No | Sí | Sí (a otras tiendas) | No aplica |
| Crear y editar su tienda y productos | No | Puede crear una | Sí | No |
| Ver y cambiar los pedidos de su tienda | No | No | Sí | Solo ver |
| Pedir Premium | No | No | Sí | No |
| Dar de baja y reactivar tiendas | No | No | No | Sí |
| Revisar reportes y solicitudes Premium | No | No | No | Sí |
| Ver comprobantes | No | No | Solo los suyos, antes de que se borren | Sí |

"Comprador" es cualquier persona que entró con su correo. "Vendedor" es quien además tiene tienda. El administrador usa el panel de Filament, no la app.

## 4. API

Todas las rutas empiezan con `/api/v1`. Responden en JSON. Las que tienen 🔒 necesitan el token de sesión en la cabecera `Authorization: Bearer <token>` (Laravel Sanctum).

Los errores usan el formato normal de Laravel, con los textos en español:

```json
{ "message": "Revisa los datos del pedido.", "errors": { "items.0.producto_id": ["Este producto ya no está disponible."] } }
```

| Código | Cuándo |
|---|---|
| 401 | Falta el token o venció |
| 403 | La persona no tiene permiso (por ejemplo, subir portada sin Premium) |
| 404 | No existe, o la tienda está dada de baja |
| 422 | Datos que no cumplen las reglas |
| 429 | Demasiados intentos (códigos, reportes) |

### Acceso y cuenta

| Método y ruta | Envía | Responde |
|---|---|---|
| `POST /auth/codigo` | `correo` | 204. Envía el código por correo |
| `POST /auth/verificar` | `correo`, `codigo`, `dispositivo` | `token`, `usuario`, `es_nuevo` |
| `POST /auth/salir` 🔒 | | 204 |
| `GET /yo` 🔒 | | Datos de la cuenta y, si tiene, resumen de su tienda |
| `PUT /yo` 🔒 | `nombres`, `acepto_privacidad` (obligatorio la primera vez), datos de vendedor, `mostrar_whatsapp` | Cuenta actualizada |
| `POST /yo/codigo-borrado` 🔒 | | 204. Envía un código para confirmar el borrado |
| `DELETE /yo` 🔒 | `codigo` | 204. Borra la cuenta (reglas 29 a 31) |

### Vitrina (sin sesión)

| Método y ruta | Envía | Responde |
|---|---|---|
| `GET /categorias` | | Lista de categorías activas |
| `GET /puntos-entrega` | | Lista de puntos activos |
| `GET /tiendas` | `categoria`, `buscar`, `pagina` | Tiendas activas, 20 por página |
| `GET /tiendas/{slug}` | | Tienda con sus productos no eliminados |
| `GET /productos` | `categoria`, `buscar`, `pagina` | Productos de tiendas activas, 20 por página |

La búsqueda revisa el nombre de la tienda, el nombre del producto y su descripción, sin distinguir mayúsculas ni tildes.

### Mi tienda 🔒

| Método y ruta | Envía | Responde |
|---|---|---|
| `POST /mi-tienda` | Datos de la tienda (y de vendedor si faltan) | Tienda creada |
| `GET /mi-tienda` | | Tienda, plan, estado y motivo de baja si lo hay |
| `PUT /mi-tienda` | Datos editables | Tienda actualizada |
| `POST /mi-tienda/logo` | Imagen | `logo_url` |
| `POST /mi-tienda/portada` | Imagen | `portada_url`. 403 si no es Premium |
| `GET /mi-tienda/productos` | | Productos de la tienda |
| `POST /mi-tienda/productos` | `nombre`, `descripcion`, `precio`, `disponible` | Producto creado |
| `PUT /mi-tienda/productos/{id}` | Campos a cambiar | Producto actualizado |
| `DELETE /mi-tienda/productos/{id}` | | 204 (borrado suave) |
| `POST /mi-tienda/productos/{id}/fotos` | Imagen | Foto agregada. 422 si ya tiene 3 |
| `DELETE /mi-tienda/productos/{id}/fotos/{foto}` | | 204 |
| `GET /mi-tienda/pedidos` | `estado` | Pedidos recibidos, los más nuevos primero |
| `POST /mi-tienda/pedidos/{id}/entregado` | | Pedido actualizado |
| `POST /mi-tienda/pedidos/{id}/cancelar` | | Pedido actualizado |

### Pedidos del comprador 🔒

| Método y ruta | Envía | Responde |
|---|---|---|
| `POST /pedidos` | `tienda_id`, `items` (`producto_id`, `cantidad`), `punto_entrega_id`, `hora_entrega`, `forma_pago`, `nota` | `pedido` y `whatsapp_url` |
| `GET /pedidos` | `estado` | Mis pedidos, los más nuevos primero |
| `POST /pedidos/{id}/cancelar` | | Pedido actualizado |

### Reportes y Premium 🔒

| Método y ruta | Envía | Responde |
|---|---|---|
| `POST /tiendas/{id}/reportes` | `motivo`, `detalle` | 201 |
| `GET /premium` | | Precio, datos de la cuenta para pagar, estado del plan y de la última solicitud |
| `POST /premium/solicitudes` | `numero_comprobante`, `monto`, foto | Solicitud `pendiente` |

### Páginas web del servidor (fuera de la API)

| Ruta | Para qué |
|---|---|
| `/privacidad` | Política de privacidad. Su enlace va en la ficha de Google Play |
| `/borrar-cuenta` | Borrado de cuenta desde la web, con correo y código. Lo exige Google Play |
| `/admin` | Panel del administrador (Filament). Solo cuentas con `es_admin` |

El enlace público de una tienda (`/t/{slug}`) lo maneja la versión web de Flutter.

## 5. Panel del administrador (Filament)

| Sección | Qué permite |
|---|---|
| Tiendas | Lista con filtros (estado, plan, categoría). Botones "Dar de baja" (pide motivo) y "Reactivar" |
| Reportes | Lista de reportes `nuevo` primero, con la tienda y el motivo. Botones "Dar de baja la tienda" y "Cerrar sin acción" (pide nota) |
| Solicitudes Premium | Lista de `pendiente` primero, con la foto del comprobante, el número y el monto. Botones "Aprobar" y "Rechazar" (pide motivo) |
| Usuarios | Lista y búsqueda por correo. Botón "Desactivar" |
| Pedidos | Solo lectura, con filtros por estado, tienda y fecha |
| Categorías y puntos de entrega | Crear, editar, ordenar, activar y desactivar |
| Configuración | La fila de `configuracion` |
| Resumen del piloto | Los números de la sección 9 de `00-PRD-general.md`, por semana |
