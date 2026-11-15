# Acceso institucional y cuenta

La portada web está en `/`. **Explorar la Vitrina** abre `/vitrina` sin sesión. Compradores y vendedores pueden **Iniciar sesión** con su correo UTB y contraseña o **Crear cuenta** con un código de verificación. **Quiero vender** lleva a `/mi-tienda` después del acceso y de completar los nombres y el consentimiento cuando falten. **Administración** abre el panel de Filament con su propia sesión y permiso. En Cuenta puedes editar los nombres, controlar la visibilidad de WhatsApp, consultar privacidad y solicitar el borrado.

## Probar en esta computadora

1. Abre `Abrir PuntoKampus.cmd` y entra en `http://127.0.0.1:8766`. Si ya tienes abierta la Vitrina, recarga con Ctrl + F5.
2. Abre **Crear cuenta** y pide el código con un correo ficticio disponible. Con `MAIL_MAILER=log`, busca en `api/storage/logs/laravel.log` la entrada más reciente para ese correo y copia sus seis dígitos.
3. Escribe o pega el código y establece una contraseña de PuntoKampus de 12 a 128 caracteres. Si falta tu perfil, completa los nombres y el consentimiento. Las cuentas anteriores de solo código pueden usar **Crear cuenta** con el mismo correo para establecer la contraseña una vez y conservar el perfil.
4. Usa **Cerrar sesión** desde Cuenta o el menú de perfil de escritorio. Luego elige **Iniciar sesión** y usa el correo y la contraseña. Para eliminar la cuenta se conserva la confirmación independiente por código.
5. También puedes abrir directamente `http://127.0.0.1:8766/privacidad` y `http://127.0.0.1:8766/borrar-cuenta`. La segunda ruta permite borrar mediante correo y código incluso con una cuenta desactivada.

El iniciador aplica las migraciones, incluida la que agrega `usuarios.contrasena_hash`. Para desarrollo sin periodo académico configurado las sesiones vencen en siete días. Con un periodo activo vencen al terminar su último día en Ecuador continental. El siguiente inicio de sesión usa contraseña, incluso al cambiar de periodo. Los tiempos persistidos se guardan en UTC.

## Contrato entre Flutter y Laravel

La decisión posterior del equipo reemplaza el ingreso habitual por código descrito en el PRD. Las respuestas de `GET /yo` y `PUT /yo` contienen `id`, `correo`, `nombres`, `acepto_privacidad_en`, `mostrar_whatsapp` y `tienda`. El hash Argon2id queda en PostgreSQL y nunca se incluye en las respuestas. `mostrar_whatsapp` es nulo si falta el perfil de vendedor y `tienda` es nulo si la cuenta aún no tiene tienda.

| Ruta | Cambio |
| --- | --- |
| `POST /api/v1/auth/entrar` | Nueva. Recibe `correo`, `contrasena` y `dispositivo`. Responde con `token`, `usuario` y `es_nuevo: false`. |
| `POST /api/v1/auth/codigo` | Solicita verificación para cuentas nuevas o anteriores sin contraseña. Responde 204 también si la cuenta ya tiene contraseña o está desactivada. |
| `POST /api/v1/auth/verificar` | Recibe además `contrasena` y `contrasena_confirmation` para completar el registro o configurar la clave inicial. Conserva la estructura de respuesta. |

Aplicar la migración antes de actualizar Laravel y desplegar Flutter con la API actualizada. Las sesiones anteriores continúan hasta su vencimiento o cierre. La versión anterior de Flutter requiere actualizarse para completar este nuevo registro.

El servidor autentica el encabezado Bearer con un middleware que lee `sesiones_acceso` en PostgreSQL y verifica el hash SHA-256. El cliente mantiene la cabecera del PRD. Para futuras rutas con sesión, el middleware exige perfil completo por defecto. Las rutas `/yo` y el cierre de sesión permiten terminar el alta o eliminar una cuenta incompleta.

| Ruta agregada (prefijo `/api/v1`) | Solicitud | Respuesta y uso |
| --- | --- | --- |
| `GET /privacidad` | Sin sesión | `responsable`, `contacto` y `actualizada_en` (`AAAA-MM-DD` o nulo). Laravel lee la fecha de `PK_PRIVACIDAD_ACTUALIZADA_EN`. Flutter muestra la fecha cuando está disponible. Las versiones anteriores del cliente pueden ignorarla. |
| `POST /cuentas/codigo-borrado` | `correo` | 204. Código exclusivo de borrado para el formulario web público. |
| `DELETE /cuentas` | `correo`, `codigo` | 204. Confirma el borrado desde el formulario sin sesión. |

El correo del código tiene versiones HTML y de texto sin recursos externos. Se usa para verificar el registro, entrar a Filament y confirmar el borrado. Los códigos vencen en diez minutos y se almacenan como hashes. Se bloquea el quinto intento errado, hay un máximo de cinco envíos por hora y la API usa `Retry-After` en el límite de envíos. El borrado retira la cuenta, revoca las sesiones, cancela pedidos pendientes afectados y conserva los pedidos de la contraparte sin la relación a la cuenta o tienda borrada y sin notas libres. Los comprobantes aprobados conservan número y monto para evitar reutilización. Se retiran las fotos de los discos administrados. Los futuros servicios de subida deberán registrar URLs bajo `/storage/` en disco público y rutas relativas de comprobantes en disco privado. Activa el programador de Laravel para reintentar fallos de almacenamiento mediante `cuentas:limpiar-archivos`.

## Antes del piloto

- Configurar un remitente SMTP autorizado en el `.env` del servidor y comprobar entrega y spam con correos UTB reales. El modo de registro de correo es local.
- Configurar el periodo académico activo, el responsable y el correo de privacidad (`PK_RESPONSABLE_DATOS`, `PK_CORREO_PRIVACIDAD`). El texto local es un borrador basado en el PRD y queda sujeto a la revisión del equipo.
- Servir la web y la API mediante HTTPS. El servidor web debe devolver `index.html` al abrir directamente `/vitrina`, `/mi-tienda`, `/cuenta`, `/t/{slug}`, `/privacidad` o `/borrar-cuenta`. El navegador local usa almacenamiento cifrado de la sesión mediante WebCrypto y Android usa su almacenamiento seguro.
