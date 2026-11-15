# Reportes y moderación

## Prueba local

1. En la [Vitrina local](http://127.0.0.1:8766/), abre una tienda ajena y pulsa **Reportar**. Entra con correo UTB si hace falta. Selecciona un motivo y, si eliges **Otro**, escribe qué ocurrió.
2. Abre el [panel de moderación local](http://127.0.0.1:8000/admin). Solicita un código con una cuenta habilitada para administración. Con `MAIL_MAILER=log`, el código local aparece en `api/storage/logs/laravel.log` junto al asunto **Tu código para el panel de PuntoKampus**.
3. En **Reportes**, abre **Ver detalle**. Elige **Cerrar sin acción** y escribe una nota interna, o **Dar de baja la tienda** y escribe el motivo que verá el vendedor. La tienda dada de baja desaparece del catálogo. Sus pedidos pendientes quedan cancelados por el sistema y dejan de reservar unidades.
4. En **Tiendas**, verifica el motivo y prueba **Reactivar**. La tienda vuelve al catálogo y los pedidos cancelados conservan su estado. Para una baja ajena a un reporte, usa **Dar de baja** desde esta misma sección.

## Instalación y acceso

- En `api/`, ejecuta `composer install` y `php artisan migrate`. Composer publica los recursos de Filament. Puedes republicarlos con `php artisan filament:assets`.
- Para habilitar a un administrador, el operador de la base valida primero la identidad y activa `es_admin` en su usuario institucional existente. El panel comprueba que el usuario conserva el rol y su cuenta sigue activa. El código propio del panel vence a los diez minutos y la sesión del panel se gestiona aparte de la app.
- La ventana de 24 horas para repetir un reporte se cuenta desde el último envío para la misma tienda. Las 24 horas de revisión del PRD son un plazo para el equipo.

## API

`POST /api/v1/tiendas/{id}/reportes` usa la sesión institucional con perfil completo. Recibe `motivo` y `detalle`. El detalle admite 300 caracteres y es obligatorio para `otro`. Responde 201 con `{"estado":"nuevo"}`. Si la misma cuenta ya reportó esa tienda en las últimas 24 horas devuelve 429 con `Retry-After`. Las acciones administrativas se ejecutan desde Filament.
