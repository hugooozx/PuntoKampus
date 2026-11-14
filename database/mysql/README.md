# Base de datos de PuntoKampus

Diseño del tramo 1, 14 de noviembre de 2026. El destino elegido para esta entrega es **MySQL 8.4 LTS**, conforme a la preferencia posterior del usuario. Sustituye PostgreSQL como objetivo del diseño; la integración de Laravel con esta nueva estructura se hará en una tarea posterior.

El entregable es [puntokampus.sql](puntokampus.sql): **19 tablas, 3 vistas y cero registros iniciales**. No incluye tiendas ficticias, usuarios, cuentas bancarias, categorías ni una configuración precargada. Tampoco crea usuarios del servidor MySQL ni incluye contraseñas.

## Ejecutarlo completo

1. Conectarse a un servidor **MySQL 8.4** desde MySQL Workbench u otro cliente que permita ejecutar scripts completos.
2. Abrir `puntokampus.sql` como archivo SQL con codificación UTF-8.
3. Seleccionar **todo el contenido** y ejecutar la selección completa. No hace falta crear ni seleccionar antes la base: el archivo contiene `CREATE DATABASE` y `USE`.
4. Actualizar el listado de esquemas. Aparecerá `puntokampus` con las tablas vacías y las vistas.

La conexión necesita los permisos de creación de base/tablas, `REFERENCES`, `CREATE VIEW`, `DROP` para reemplazar las vistas y `SELECT` sobre `puntokampus`. No se necesita permiso para crear procedimientos, disparadores, eventos ni usuarios. El script usa sentencias separadas por `;`, sin `DELIMITER` ni instrucciones específicas de un cliente.

**Reejecución:** `CREATE DATABASE IF NOT EXISTS` y `CREATE TABLE IF NOT EXISTS` evitan errores por objetos ya creados. Las vistas se redefinen con `CREATE OR REPLACE`. No se borran ni se insertan registros. MySQL puede mostrar avisos de que las tablas ya existen: son esperados.

La garantía comprobada es ejecutar y repetir **este mismo esquema en MySQL 8.4 con esos permisos**. No es un actualizador de esquemas ajenos o antiguos: `IF NOT EXISTS` no compara ni corrige las columnas de tablas existentes. Tampoco se promete compatibilidad con MySQL 5.7 o MariaDB. El DDL de MySQL confirma las sentencias individualmente; ejecutar el bloque completo no equivale a una transacción que revierta todo si se interrumpe. [Documentación oficial de CREATE TABLE](https://dev.mysql.com/doc/refman/8.4/en/create-table.html), [confirmaciones implícitas](https://dev.mysql.com/doc/refman/8.4/en/implicit-commit.html).

## Entidades

| Tablas | Responsabilidad |
| --- | --- |
| `facultades`, `carreras` | Estructura académica. La facultad se obtiene a través de la carrera. |
| `periodos_academicos` | Fechas de los periodos que delimitan Premium y el acceso institucional. |
| `usuarios` | Correo institucional, nombres, aceptación de privacidad, estado y permiso administrativo. |
| `perfiles_vendedores` | Datos adicionales necesarios para vender. Una fila por usuario vendedor. |
| `codigos_acceso` | Códigos temporales de acceso o eliminación, guardados como hash. |
| `sesiones_acceso` | Tokens de sesión guardados como hash, dispositivo y vencimiento. |
| `categorias`, `puntos_entrega` | Catálogos administrables y desactivables. |
| `tiendas`, `tiendas_categorias` | Una tienda por vendedor y una o dos categorías ordenadas. |
| `productos`, `fotos_productos` | Catálogo, disponibilidad, borrado suave y hasta tres fotos. |
| `pedidos`, `detalles_pedidos` | Cabecera y líneas del pedido con nombre y precio históricos. |
| `reportes` | Motivo, detalle y resolución administrativa. |
| `cuentas_bancarias`, `configuraciones` | Cuenta de cobro **de PuntoKampus**, precio Premium, periodo actual y retención de comprobantes. No son datos bancarios de los estudiantes. |
| `solicitudes_premium` | Solicitud, comprobante privado, revisión y periodo concedido. |

Las tres vistas no almacenan registros:

- `vistas_detalles_pedidos`: añade `subtotal = precio_unitario × cantidad`.
- `vistas_totales_pedidos`: calcula el `total` de cada pedido a partir de sus líneas.
- `vistas_planes_tiendas`: devuelve `plan` y `premium_hasta` a partir de las solicitudes aprobadas y sus periodos vigentes. No altera el orden de la vitrina.

El [diagrama de relaciones](modelo.md) muestra las claves y cardinalidades. Todos los nombres de tablas están en español, en plural y sin tildes. `hash`, `slug`, `url` y `premium` se conservan como términos técnicos del contrato original.

## Tercera forma normal

El modelo lógico de las tablas se diseñó en **3FN**:

1. **Valores atómicos y sin listas de relaciones en una columna.** Cada foto, categoría asociada y detalle del pedido ocupa su propia fila. No se guardan listas de IDs ni documentos JSON de entidades relacionadas.
2. **Dependencia de la clave completa.** Cada tabla tiene clave primaria. En `tiendas_categorias`, `orden` depende de la asociación tienda–categoría; las claves alternativas `(tienda_id, orden)` y `(tienda_id, categoria_id)` evitan posiciones y categorías repetidas.
3. **Sin dependencias transitivas entre atributos no clave.** No se repiten facultad y carrera en el usuario: `usuario → perfil → carrera → facultad`. Las fechas de un periodo viven en `periodos_academicos`, no en todas sus solicitudes ni en la configuración. Los datos de la cuenta receptora viven en `cuentas_bancarias`.
4. **Importes derivados fuera de las tablas.** No se persisten `subtotal` ni `total`. Tampoco se duplica el estado Premium en `tiendas`: se obtiene de las aprobaciones y la fecha vigente.

El nombre y precio en `detalles_pedidos` son el **nombre acordado y precio acordado en esa venta**. No dependen funcionalmente del precio o nombre actuales del catálogo: un mismo producto puede tener distintos precios históricos en distintos pedidos. Conservar estos hechos permite el historial exigido por el PRD sin introducir esa dependencia transitiva.

Los índices funcionales que garantizan la unicidad condicional de Premium son estructuras de acceso del motor; no agregan atributos editables o copias de datos de negocio al modelo. Se utilizan `ENUM` para dominios pequeños y cerrados del PRD —por ejemplo estados y formas de pago—, y tablas para los catálogos que el administrador sí puede editar. Un dominio enumerado no incumple la 3FN. [Índices funcionales de MySQL](https://dev.mysql.com/doc/refman/8.4/en/create-index.html).

## Reglas garantizadas por la base

- Claves foráneas, claves primarias y unicidad de correos, enlaces de tienda y códigos de pedido.
- Correo institucional en minúsculas, dominio UTB o subdominio válido; la validación completa del correo también se realiza en Laravel.
- Perfil de vendedor con carrera existente, semestre de 1 a 10 y WhatsApp con dígitos internacionales sin `+`. La conversión de `09…` a `5939…` la realiza el servidor.
- Una tienda por cuenta y existencia previa del perfil de vendedor.
- Como máximo dos categorías distintas por tienda y tres fotos por producto, mediante posiciones limitadas y únicas.
- Precio de producto e histórico mayor que cero y hasta USD 500; cantidad de 1 a 20.
- Hora de entrega entre 30 minutos y siete días respecto de `creado_en`.
- Motivo y fecha de baja; actor de cancelación; detalle obligatorio del reporte «otro»; nota al cerrar sin acción; motivo de rechazo de Premium.
- Una solicitud Premium pendiente por tienda y un número de comprobante único entre las aprobadas, incluso ante operaciones concurrentes. Los números se comparan sin distinguir mayúsculas y se rechazan espacios exteriores.
- Solicitud aprobada asociada a un periodo existente.
- Una única fila posible de configuración, con ID 1. `limite_pedidos_gratis` solo admite `NULL` en este tramo. Activarlo en otro tramo requerirá una migración, además de definir su comportamiento.
- Códigos con vigencia de diez minutos y como máximo cinco intentos. El campo de hash no admite un código de seis caracteres en claro; **Laravel debe generar y verificar el hash criptográfico**, no basta la validación de longitud.

Las restricciones `CHECK` no consultan otras tablas ni ejecutan tareas periódicas. Su alcance es la fila evaluada. [Restricciones CHECK de MySQL](https://dev.mysql.com/doc/refman/8.4/en/create-table-check-constraints.html).

## Reglas que Laravel debe implementar al integrar

Este archivo define la estructura; **no sustituye los servicios de negocio**. Se requieren transacciones y validaciones en el servidor para:

| Operación | Regla y estrategia |
| --- | --- |
| Alta y acceso | Permitir temporalmente ambos campos `nombres` y `acepto_privacidad_en` en `NULL` después de verificar el correo; exigirlos antes de usar funciones autenticadas. Validar cuenta activa. No permitir que el usuario cambie `es_admin`. |
| Códigos | Espera de 60 segundos, máximo cinco envíos por hora, consumo de un solo uso, invalidación de códigos anteriores, rechazo del quinto fallo y vencimiento. Serializar por correo para evitar carreras. Separar propósito de acceso y borrado. |
| Sesiones | Guardar SHA-256 del token, validar vencimiento y estado del usuario, revocar al salir o desactivar. No permitir sesiones más allá del fin del periodo. Los permisos se resuelven con políticas del servidor. |
| Publicar tienda | Crear el perfil, la tienda y su categoría de orden 1 en una transacción; comprobar catálogos activos. La FK no puede exigir que un padre tenga al menos un hijo. |
| Catálogo | Límites de imagen, rutas públicas de fotos, portada solo para Premium y ocultación de WhatsApp según consentimiento. Al expirar Premium se oculta la portada, sin borrar el archivo. |
| Pedido | Exigir comprador y tienda no nulos al crear; no comprar a la tienda propia; tienda activa; al menos una línea; productos activos, disponibles y de esa misma tienda. Bloquear tienda y productos durante la transacción; copiar nombre y precio del servidor; ignorar importes del cliente. |
| Código del pedido | Asignar un código único con formato `PK-000123`, sin `MAX(id)+1` inseguro. Puede generarse usando una estrategia transaccional o un identificador aleatorio numérico con reintento ante colisión. No se calcula a partir del ID en este diseño. |
| Totales e historial | Serializar importes como texto decimal. Validar el máximo `999999.99` del contrato original antes de confirmar. No modificar las líneas después de crear el pedido. Registrar antes de devolver el enlace de WhatsApp. |
| Estados | Solo pasar de pendiente a entregado, cancelado o vencido; comprobar actor autorizado con una actualización condicional `WHERE estado = 'pendiente'`. Vencer pendientes 24 horas después de la entrega mediante la tarea horaria. |
| Baja | Solo administrador; guardar motivo y cancelar los pedidos pendientes con `cancelado_por = sistema` en la misma transacción. |
| Reportes | Prohibir reportar tienda propia y exigir autor al crear. Un reporte por tienda en una ventana móvil de 24 horas, bloqueando el usuario durante la comprobación y escritura. No equivale a «uno por día calendario». |
| Revisión | Solo administradores. Asignar `revisado_por` y `revisado_en` y realizar la operación asociada al reporte. Las FK permiten anonimizar posteriormente al revisor. |
| Premium | Solo dueño de tienda activa; validar comprobante, monto y ruta privada; no exponer la foto por URL pública. Aprobar o rechazar solo pendientes. Al aprobar, asignar el periodo actual de configuración; exigir que todavía no haya terminado. |
| Periodos | Una vez usados para aprobaciones, no cambiar sus fechas sin una operación explícita de negocio. Crear nuevas filas para nuevos periodos. La vista calcula el vencimiento a partir de esas fechas. |
| Retención | El plazo se configura explícitamente: no se asumió que la propuesta de 30 días ya estuviera aprobada. Borrar el archivo según plazo desde revisión, poner la ruta en `NULL` y registrar `foto_borrada_en`. |

**Fechas:** todos los `DATETIME` se guardan en UTC. Configurar la conexión de Laravel con zona `+00:00` y modo estricto. Convertir a `America/Guayaquil` al mostrar y recibir fechas. El final del periodo Premium es inclusivo según la fecha local de Ecuador continental; la vista utiliza UTC−05:00 y no depende de cargar tablas de zonas horarias. Las fechas de creación las asigna el servidor, nunca la app.

**Búsqueda:** las columnas de nombres y descripciones usan `utf8mb4_0900_ai_ci`, que permite comparar sin distinguir mayúsculas ni acentos. Usar consultas parametrizadas y escapar comodines si se busca literalmente. Una búsqueda `LIKE '%texto%'` no se acelera por un índice B-tree normal; para el piloto se prioriza la semántica del PRD. No se añadió `FULLTEXT` porque cambia el tratamiento de términos cortos y coincidencias parciales.

## Eliminación de cuentas e historial

La eliminación de `usuarios` elimina por cascada perfil, tienda, asociaciones, productos, fotos de catálogo y sesiones. Los pedidos y detalles de la otra parte se conservan: las FK del comprador, tienda o producto pasan a `NULL`, sin copiar datos personales en el historial. La API muestra **«Usuario eliminado»** o **«Tienda eliminada»** según corresponda. La eliminación normal de un producto sigue siendo suave con `eliminado_en`.

La operación completa de eliminación también debe:

1. Recopilar las rutas de archivos antes de eliminar filas y revocar sesiones/códigos del correo, incluidos los códigos que no tienen FK.
2. Cancelar pendientes afectados como sistema, depurar datos personales de notas/detalles libres y eliminar solicitudes Premium no aprobadas de la tienda.
3. Conservar número y monto de solicitudes aprobadas, quitar las fotos y registrar su eliminación; la referencia a la tienda pasa a `NULL`. Así el mismo comprobante aprobado no vuelve a ser válido por haber borrado la cuenta, conforme al registro de pagos de `05-privacidad-y-google-play.md`.
4. Ejecutar el borrado de filas en una transacción, y eliminar los archivos del almacenamiento con reintentos si falla alguna operación de disco. Una FK no elimina archivos físicos.
5. Eliminar pedidos cuando ya no exista ninguna de las dos partes (`comprador_id IS NULL AND tienda_id IS NULL`), para no conservar un historial sin destinatarios.

Los revisores y reportantes eliminados quedan como referencia nula. Los reportes desaparecen al eliminar la tienda. Los catálogos usados por un registro se desactivan; sus FK impiden borrarlos mientras exista una referencia.

## Cambios respecto del contrato y del código existente

El PRD original se conserva como referencia histórica. El cambio de motor y la normalización se documentan aquí para que ambos desarrolladores conozcan su impacto; **la API actual no quedó migrada por crear este SQL**.

| Contrato original | Diseño MySQL | Impacto de integración |
| --- | --- | --- |
| PostgreSQL | MySQL 8.4, InnoDB y `utf8mb4` | Laravel: `pdo_mysql`, conexión `mysql`, consultas y pruebas sobre MySQL. Flutter no cambia de motor ni conecta directamente a la base. |
| Datos de vendedor dentro de `usuarios` | `perfiles_vendedores` y catálogos académicos | Laravel compone el recurso de usuario con las relaciones. Puede seguir devolviendo `facultad`, `carrera`, `semestre`, `whatsapp`, etc. |
| `categoria_1_id`, `categoria_2_id` en `tiendas` | Filas en `tiendas_categorias`, posiciones 1 y 2 | Laravel transforma los dos campos de entrada/salida; Flutter puede conservar esos campos. |
| `producto_fotos` | `fotos_productos` | Cambia la tabla del modelo Eloquent; las respuestas públicas mantienen fotos y su orden. |
| `pedido_items` | `detalles_pedidos` | Cambia la tabla del modelo; la API mantiene la lista `items`. |
| `subtotal` y `total` almacenados | Vistas/calculados en consultas | Laravel devuelve los mismos campos y formatos. Flutter sigue mostrando el resultado calculado por el servidor. |
| `tiendas.plan`, `premium_hasta` | `vistas_planes_tiendas` | Laravel conserva esos campos de respuesta. Vencimiento calculado al consultar: evita un plan desactualizado si falla la tarea diaria. Para plan gratis, la vista devuelve `premium_hasta = NULL`. |
| `configuracion` y fecha de fin repetida | `configuraciones`, `cuentas_bancarias`, `periodos_academicos` | Filament edita las relaciones. `/premium` mantiene precio y datos de pago mediante un recurso de respuesta. |
| Nombres y privacidad siempre obligatorios en tabla | Ambos nulos solo durante alta | Resuelve el paso «cuenta creada → completar perfil» de R3. El middleware debe exigir perfil completo antes de operar. |
| Tokens Sanctum por defecto | `sesiones_acceso` en español y con FK concreta | Es necesario adaptar el modelo de token y sus métodos/relación a Sanctum; no basta cambiar solo el nombre de tabla. Las cabeceras Bearer no cambian en Flutter. |

**Extensión propuesta para los formularios académicos**, a implementar y reflejar en la siguiente versión del contrato antes de conectar esas pantallas:

- `GET /api/v1/facultades`: `data: [{id, nombre}]`, solo activas.
- `GET /api/v1/carreras?facultad_id=…`: `data: [{id, facultad_id, nombre}]`, solo activas de esa facultad.
- `PUT /yo` y `POST /mi-tienda`: enviar `carrera_id` en los datos de vendedor en lugar de textos libres `facultad` y `carrera`.
- Respuesta de usuario: conservar `facultad` y `carrera` como nombres para mostrar, y agregar `facultad_id` y `carrera_id` para los selectores.
- Flutter: selector de facultad y selector dependiente de carrera. Laravel: validar que ambos catálogos estén activos y derivar la facultad desde la carrera; no guardar una facultad contradictoria enviada por la app.

Las migraciones existentes de `api/` todavía crean el esquema anterior. **No ejecutar `php artisan migrate` sobre una base creada con este archivo hasta adaptar y conciliar las migraciones.** Para un proyecto vacío, las futuras migraciones deben reproducir este diseño; para una base con datos, se necesita una migración incremental revisada. Nunca borrar una base existente para resolver esa diferencia.

Este modelo incluye las tablas del dominio y los tokens de acceso. Las tablas técnicas de Laravel para migraciones, colas o caché se definirán al integrar sus controladores, también con nombres en español si se almacenan en MySQL; no se mezclan aquí con el modelo de negocio. No hay tablas de destacados pagados, estrellas, existencias exactas ni otras funciones del tramo 2.

## Verificación realizada

Se ejecutó con **MySQL Community Server 8.4.13** en una instancia aislada, sin usar una base del usuario. Resultado: **51 comprobaciones aprobadas**.

- Ejecución completa sobre una base nueva y segunda ejecución íntegra.
- Comprobación exacta de cero filas en las 19 tablas del entregable.
- Reejecución sobre una base de prueba poblada, conservando registros y valores.
- Rechazo de correos inválidos, relaciones huérfanas, duplicados, precios/cantidades fuera de rango y exceso de fotos/categorías.
- Restricciones de estados, entrega, códigos, configuración y solicitudes Premium.
- Cálculo del plan vigente y del total histórico, incluso tras cambiar o eliminar productos.
- Conservación del historial al eliminar comprador/vendedor y prevención de reutilización de comprobantes aprobados de tiendas eliminadas.

El verificador usa otra base para los datos ficticios. Esos datos **no forman parte de `puntokampus.sql`**. Para repetirlo con Python y los binarios oficiales de MySQL 8.4:

```powershell
python database/mysql/pruebas/verificar_esquema.py --bin .tools/mysql-pruebas/mysql-8.4.13-winx64/bin --trabajo .tools/mysql-pruebas
```

El script crea su propia carpeta, puerto local y contraseña aleatoria; no se conecta a un servidor existente y apaga su instancia al terminar. El resultado detallado se guarda en `.tools/mysql-pruebas/resultado.json`. La carpeta `.tools/` está excluida de Git. Estas pruebas validan el esquema; **no equivalen a tener implementadas las rutas de Laravel ni todas las reglas de autorización**.
