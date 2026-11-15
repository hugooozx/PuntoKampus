# Mis productos

En la aplicación local, entra con tu cuenta UTB y abre **Mi tienda → Mis productos → Nuevo producto**. Escribe el nombre, el precio y una descripción opcional. Puedes seleccionar hasta tres fotos. Pulsa **Publicar producto** y comprueba la tarjeta en la Vitrina y en tu tienda pública.

Toca un producto de tu lista para editarlo. Al apagar **Disponible** y guardar, la tarjeta sigue visible con la etiqueta **Agotado**. **Borrar producto** pide confirmación, lo retira de las vistas públicas y conserva su referencia histórica en los pedidos.

Laravel guarda los datos en PostgreSQL y prepara las fotos en WebP, con un máximo de 1080 píxeles por lado. Los archivos quedan en `api/storage/app/public/productos/`. Al quitar una foto o retirar un producto, se programa la limpieza del archivo local. Para probar en esta computadora, abre `Abrir PuntoKampus.cmd` y navega a `http://127.0.0.1:8766/`. Si ya la tienes abierta, recarga con Ctrl+F5 después de compilar.

En esta instalación local queda el ejemplo **Brownie de prueba**, visible como **Agotado** en Productos y en `/t/dulces-de-prueba`. Para editarlo, entra como `productos.demo@utb.edu.ec` y toma el código más reciente para ese correo de `api/storage/logs/laravel.log`. La cuenta y el producto son datos ficticios para la prueba local.

## Contrato

Se implementan las seis rutas para productos y fotos de `/api/v1/mi-tienda/productos` descritas en el PRD. Los recursos públicos conservan su formato. Laravel devuelve `precio` como texto decimal, `disponible` como booleano y `fotos` en orden de presentación.

Para publicar o editar todo el formulario de P16 en una transacción, `POST` y `PUT` admiten además `fotos[]` como archivos, y `PUT` admite `fotos_eliminar[]` como IDs de fotos de ese mismo producto. Flutter envía la edición con archivos como multipart mediante `POST` con `_method=PUT`. Las solicitudes JSON existentes y los endpoints separados de fotos siguen disponibles.

Las pruebas de Laravel cubren propiedad, importes, publicación, agotado, borrado suave con historial, límite de fotos y reemplazo de una foto en el mismo guardado. Se ejecutan con `php artisan test --filter=MisProductosTest` sobre la base de pruebas PostgreSQL.
