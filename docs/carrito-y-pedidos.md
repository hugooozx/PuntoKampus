# Carrito y pedidos

En esta computadora, ejecuta `Abrir PuntoKampus.cmd` y abre `http://127.0.0.1:8766/vitrina`. Si ya la tienes abierta, recarga con Ctrl+F5. El carrito conserva los productos mientras navegas y durante el inicio de sesión. Cada carrito corresponde a una sola tienda.

1. En **Productos**, abre un producto disponible, elige la cantidad y pulsa **Agregar al carrito**. El carrito muestra la foto, el precio unitario y el importe de cada línea. Puedes cambiar la cantidad o quitar productos y ver el total actualizado.
2. Pulsa **Continuar**. Entra con una cuenta UTB distinta de la del vendedor y completa el perfil si corresponde. En el entorno local el código queda en el log de Laravel según la [guía de acceso](acceso-y-cuenta.md).
3. Selecciona el punto de entrega, el día, la hora y la forma de pago. La nota es opcional. Pulsa **Enviar pedido**.
4. Anota el código que aparece en **Tu pedido quedó registrado**. Puedes pulsar **Abrir WhatsApp** si el navegador bloqueó la apertura automática. Recarga la app y abre **Mis pedidos** para comprobar que el pedido quedó guardado.

Las cantidades van de 1 a 20 por producto. La entrega se puede programar desde 30 minutos hasta 7 días después del envío y usa la hora de Ecuador continental. La nota admite 200 caracteres. La interfaz de **Mi tienda** admite hasta 10 dígitos en el WhatsApp nacional y valida el prefijo `09`. Laravel normaliza los formatos ecuatorianos admitidos a un número internacional.

Cuando un producto tiene inventario, tanto su ficha como el carrito limitan la cantidad según las unidades consultadas al abrir el producto. Laravel vuelve a comprobar las existencias cuando recibe el pedido.

## Contrato de la API

- `POST /api/v1/pedidos` conserva los campos del PRD y devuelve `pedido` y `whatsapp_url`. Envía los identificadores y las cantidades como enteros JSON. `hora_entrega` incluye un desplazamiento horario ISO 8601 en la solicitud. La respuesta devuelve la hora en UTC. Laravel comprueba la tienda, los productos, el punto activo y el plazo, copia nombres y precios y guarda el pedido pendiente antes de responder.
- Flutter envía el encabezado opcional `Idempotency-Key` con 32 dígitos hexadecimales en minúscula. Una repetición con los mismos datos devuelve el pedido original. Si se reutiliza la clave con otros datos, la API devuelve 409. Aplica `php artisan migrate` para agregar las columnas del envío.
- `GET /api/v1/pedidos` y `GET /api/v1/mi-tienda/pedidos` devuelven 20 pedidos por página con `estado` opcional. Cada pedido incluye `items` y `cancelado_por`. La lista del vendedor incluye `comprador`. El comprador cancela con `POST /pedidos/{id}/cancelar`. El vendedor entrega o cancela con `POST /mi-tienda/pedidos/{id}/entregado` o `POST /mi-tienda/pedidos/{id}/cancelar`. Las acciones devuelven el pedido actualizado en `data`.

## Pedidos de mi tienda e inventario

1. En **Mi tienda → Mis productos → Ajustar inventario**, elige un producto y activa el control con 50 unidades. Registra una **Venta fuera de PuntoKampus** de 20 unidades.
2. Con otra cuenta, compra 5 unidades. En el inventario aparecerán 30 existencias físicas, 5 reservadas y 25 libres. Si ya había pedidos pendientes al activar el control, esas cantidades cuentan como reservas.
3. Con la cuenta vendedora, abre **Mi tienda → Pedidos de mi tienda**, filtra por **Pendientes** y marca el pedido como **Entregado**. El inventario queda con 25 existencias físicas y 25 libres. Prueba otro pedido con **Cancelar** o cancélalo desde el detalle en **Mis pedidos**. La cancelación y el vencimiento liberan las unidades reservadas.

La API añade `POST /api/v1/mi-tienda/productos/{id}/inventario`. Recibe `tipo` (`activacion`, `desactivacion`, `venta_externa`, `reposicion`, `correccion`), `existencias_esperadas` (el último conteo visto, o `null` si el control está apagado) y `cantidad` (entera, requerida salvo al desactivar). Un conteo que cambió devuelve 409. El catálogo añade `unidades_disponibles`, con `null` para productos sin control de inventario. Sigue usando `disponible` para habilitar la compra y considera agotado un producto con cero unidades libres. La API del vendedor también devuelve `existencias`, `reservadas` y `disponible_manual`. Aplica la migración con `php artisan migrate`.

Los pedidos vencen a las 24 horas de la entrega programada. Laravel revisa cada hora. **Abrir PuntoKampus.cmd** inicia el programador local. En otros entornos ejecuta el programador de Laravel con `php artisan schedule:run` cada minuto. Para verificar en local, ejecuta `php artisan pedidos:vencer` desde `api/`.
