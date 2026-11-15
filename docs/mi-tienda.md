# Crear y editar una tienda

Con una sesión UTB y el perfil completo, abre **Mi tienda → Crear mi tienda**. El primer paso recoge código de estudiante, facultad, carrera, semestre y WhatsApp. El segundo recoge nombre, descripción, categorías, horario, punto de entrega y logo opcional. El número queda privado por defecto y su visibilidad se puede cambiar en Cuenta.

Al publicar, Laravel guarda el perfil de vendedor, la tienda y sus categorías en una transacción. La tienda se ve de inmediato en la Vitrina con plan gratis. **Editar tienda** conserva el enlace público aunque se cambie el nombre. **Cambiar logo** reemplaza la imagen por una nueva. Si una tienda está dada de baja, su dueño ve el motivo. Cambiar sus datos no vuelve a publicarla. La portada propia se habilitará cuando se implemente la gestión de Premium.

## Catálogos locales

Para crear una tienda deben existir una facultad y una carrera activas, una categoría activa y un punto de entrega activo. La base inicial sigue vacía. `php artisan db:seed --class=CatalogosInicialesSeeder` carga las categorías y los puntos iniciales propuestos en el PRD. Las facultades y carreras deben cargarse con los datos que confirme el equipo. La prueba automatizada crea catálogos ficticios exclusivamente en `puntokampus_pruebas`.

## Contrato

- Flutter consulta `GET /api/v1/facultades` y `GET /api/v1/carreras?facultad_id=…` con el formato `data` de los otros catálogos. Envía `carrera_id` al crear. Laravel deriva la facultad desde la carrera.
- `GET`, `POST` y `PUT /api/v1/mi-tienda` devuelven `tienda`, `ya_es_vendedor` y `mostrar_whatsapp`. `tienda` es nulo si aún no existe y usa los campos de la tienda pública más `motivo_baja`, exclusivo del dueño. Un `POST` exitoso devuelve 201. Para crear se envían los campos de tienda y, si faltan, `codigo_estudiante`, `carrera_id`, `semestre`, `whatsapp` y el booleano opcional `mostrar_whatsapp`. `PUT` recibe los datos editables de la tienda.
- `POST /api/v1/mi-tienda` acepta JSON o formulario multipart con `imagen`. `POST /api/v1/mi-tienda/logo` reemplaza la imagen mediante el mismo campo y responde `logo_url`. Laravel admite JPG, PNG y WebP hasta 2 MB. Las rutas públicas `/tiendas` conservan su formato.
- Las operaciones de escritura usan el usuario de la sesión institucional con perfil completo. Los IDs de dueño, plan y estado se resuelven en el servidor. El cambio a PostgreSQL mantiene este contrato.

Ejecuta `php artisan test --filter=MiTiendaTest` con la base de pruebas migrada. Cubre registro, publicación, edición, acceso de otra cuenta, categorías repetidas, WhatsApp privado, baja y reemplazo de logo. Para probar la interfaz local, abre «Mi tienda» con una cuenta de prueba y recorre ambos pasos con los catálogos cargados.
