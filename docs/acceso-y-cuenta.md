# Acceso institucional y cuenta

La portada web está en `/`. **Explorar la Vitrina** abre `/vitrina` sin sesión. **Quiero vender** usa el mismo acceso con correo UTB y código que el comprador. Después del alta con nombres y consentimiento, lleva a `/mi-tienda`, donde aparece la tienda existente o la opción **Crear mi tienda**. **Administración** abre el panel de Filament con su propia sesión y permiso. En Cuenta puedes editar los nombres, controlar la visibilidad de WhatsApp, consultar privacidad y solicitar el borrado.

## Probar en esta computadora

1. Abre `Abrir PuntoKampus.cmd` y entra en `http://127.0.0.1:8766`. Si ya tienes abierta la Vitrina, recarga con Ctrl + F5.
2. Pide el código con un correo ficticio, por ejemplo `prueba@fafi.utb.edu.ec`. Con la configuración local `MAIL_MAILER=log`, el correo de prueba queda en `api/storage/logs/laravel.log`. Busca la entrada más reciente para ese correo y copia sus seis dígitos. No uses datos personales en el modo de registro.
3. Escribe o pega los seis dígitos en el campo de código. Si es tu primera entrada, completa los nombres y acepta la política de privacidad para habilitar **Continuar**. En Cuenta prueba guardar otro nombre y recargar la página para comprobar la sesión.
4. Usa **Cerrar sesión** desde Cuenta o el menú de perfil de escritorio. Revoca la sesión, vacía el carrito y vuelve a la portada web. Para eliminar el perfil de prueba, vuelve a entrar, abre «Borrar mi cuenta» y solicita un código de confirmación. El límite de 60 segundos es por correo y abarca ambos tipos de código.
5. También puedes abrir directamente `http://127.0.0.1:8766/privacidad` y `http://127.0.0.1:8766/borrar-cuenta`. La segunda ruta permite borrar mediante correo y código incluso con una cuenta desactivada.

El iniciador aplica las migraciones, incluida la tabla técnica `borrados_archivos`. Para desarrollo sin periodo académico configurado las sesiones vencen en siete días. Con un periodo activo vencen al terminar su último día en Ecuador continental. Los tiempos persistidos se guardan en UTC.

## Contrato entre Flutter y Laravel

Se mantienen las siete rutas y los campos de acceso y cuenta en el PRD. Las respuestas de `GET /yo` y `PUT /yo` contienen `id`, `correo`, `nombres`, `acepto_privacidad_en`, `mostrar_whatsapp` y `tienda`. `mostrar_whatsapp` es nulo si falta el perfil de vendedor y `tienda` es nulo si la cuenta aún no tiene tienda. El sello de consentimiento permite retomar un registro incompleto aunque `es_nuevo` sea falso. La creación y edición de los datos académicos del vendedor se integrarán con el flujo de tiendas.

El servidor autentica el encabezado Bearer con un middleware que lee `sesiones_acceso` en PostgreSQL y verifica el hash SHA-256. El cliente mantiene la cabecera del PRD. Para futuras rutas con sesión, el middleware exige perfil completo por defecto. Las rutas `/yo` y el cierre de sesión permiten terminar el alta o eliminar una cuenta incompleta.

| Ruta agregada (prefijo `/api/v1`) | Solicitud | Respuesta y uso |
| --- | --- | --- |
| `GET /privacidad` | Sin sesión | `responsable`, `contacto` y `actualizada_en` (`AAAA-MM-DD` o nulo). Laravel lee la fecha de `PK_PRIVACIDAD_ACTUALIZADA_EN`. Flutter muestra la fecha cuando está disponible. Las versiones anteriores del cliente pueden ignorarla. |
| `POST /cuentas/codigo-borrado` | `correo` | 204. Código exclusivo de borrado para el formulario web público. |
| `DELETE /cuentas` | `correo`, `codigo` | 204. Confirma el borrado desde el formulario sin sesión. |

El correo del código tiene versiones HTML y de texto sin recursos externos. Se usa para el acceso, Filament y la confirmación de borrado. Los códigos vencen en diez minutos y se almacenan como hashes. Se bloquea el quinto intento errado, hay un máximo de cinco envíos por hora y la API usa `Retry-After` en el límite de envíos. El borrado retira la cuenta, revoca las sesiones, cancela pedidos pendientes afectados y conserva los pedidos de la contraparte sin la relación a la cuenta o tienda borrada y sin notas libres. Los comprobantes aprobados conservan número y monto para evitar reutilización. Se retiran las fotos de los discos administrados. Los futuros servicios de subida deberán registrar URLs bajo `/storage/` en disco público y rutas relativas de comprobantes en disco privado. Activa el programador de Laravel para reintentar fallos de almacenamiento mediante `cuentas:limpiar-archivos`.

## Antes del piloto

- Configurar un remitente SMTP autorizado en el `.env` del servidor y comprobar entrega y spam con correos UTB reales. El modo de registro de correo es local.
- Configurar el periodo académico activo, el responsable y el correo de privacidad (`PK_RESPONSABLE_DATOS`, `PK_CORREO_PRIVACIDAD`). El texto local es un borrador basado en el PRD y queda sujeto a la revisión del equipo.
- Servir la web y la API mediante HTTPS. El servidor web debe devolver `index.html` al abrir directamente `/vitrina`, `/mi-tienda`, `/cuenta`, `/t/{slug}`, `/privacidad` o `/borrar-cuenta`. El navegador local usa almacenamiento cifrado de la sesión mediante WebCrypto y Android usa su almacenamiento seguro.
