# Premium

## Recorrido local

1. Entra a la app como vendedor y abre **Mi tienda → Premium**. Con los datos ficticios locales, carga una imagen de prueba, un número nuevo y un monto de 3,00. Usa estos datos solo para simular la solicitud.
2. En otro perfil del navegador, entra a Filament y abre **Solicitudes Premium**. Revisa la foto y el número antes de **Aprobar**. Para **Rechazar**, escribe el motivo que verá el vendedor.
3. Vuelve a **Premium** y pulsa **Actualizar**. Al salir a **Mi tienda**, puedes elegir **Cambiar portada**. En otro perfil, verifica la insignia **Sacó 10** y la portada desde la tienda pública. Premium conserva el orden de la Vitrina.

Para habilitar cobros, la fila 1 de `configuraciones` necesita el precio, una cuenta de la plataforma, un periodo académico vigente y el plazo de conservación. Si falta una configuración vigente, la app muestra el estado del plan y deja el formulario de pago desactivado. La aprobación toma el fin del periodo configurado para ese momento.

PostgreSQL calcula la vigencia del plan según la fecha de Ecuador continental. Al vencer, la portada sale de la vista pública y queda guardada. El programador ejecuta `php artisan premium:limpiar-comprobantes` a diario. El plazo se cuenta desde la revisión y la limpieza conserva el registro del número y monto.

## Contrato

- `GET /api/v1/premium` devuelve `plan`, `premium_hasta`, `pago` y `ultima_solicitud`. `pago` es nulo cuando el cobro no está habilitado.
- `POST /api/v1/premium/solicitudes` recibe `numero_comprobante`, `monto` e `imagen` multipart (JPG, PNG o WebP, hasta 2 MB) y devuelve la solicitud pendiente en `data`. Una segunda solicitud pendiente devuelve 409.
- `GET /api/v1/premium/solicitudes/{id}/foto` devuelve `imagen` en Base64 solo al titular de la tienda. Filament consulta la imagen mediante su propia sesión. El contenido se entrega con `Cache-Control: private, no-store`.
- `POST /api/v1/mi-tienda/portada` recibe `imagen` de la tienda Premium y devuelve `portada_url`. Sirve `/storage/tiendas/` mediante Laravel para verificar la vigencia antes de entregar una portada.
