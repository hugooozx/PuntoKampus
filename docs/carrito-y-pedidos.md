# Carrito y pedidos

En esta computadora, ejecuta `Abrir PuntoKampus.cmd` y abre `http://127.0.0.1:8766/`. Si ya la tienes abierta, recarga con Ctrl+F5. El carrito conserva los productos mientras navegas y durante el inicio de sesión. Cada carrito corresponde a una sola tienda.

1. En **Productos**, abre un producto disponible, elige la cantidad y pulsa **Agregar al carrito**. En el carrito puedes cambiar la cantidad o quitar productos.
2. Pulsa **Continuar**. Entra con una cuenta UTB distinta de la del vendedor y completa el perfil si corresponde. En el entorno local el código queda en el log de Laravel según la [guía de acceso](acceso-y-cuenta.md).
3. Selecciona el punto de entrega, el día, la hora y la forma de pago. La nota es opcional. Pulsa **Enviar pedido**.
4. Anota el código que aparece en **Tu pedido quedó registrado**. Puedes pulsar **Abrir WhatsApp** si el navegador bloqueó la apertura automática. Recarga la app y abre **Mis pedidos** para comprobar que el pedido quedó guardado.

Las cantidades van de 1 a 20 por producto. La entrega se puede programar desde 30 minutos hasta 7 días después del envío y usa la hora de Ecuador continental. La nota admite 200 caracteres. La interfaz de **Mi tienda** admite hasta 10 dígitos en el WhatsApp nacional y valida el prefijo `09`. Laravel normaliza los formatos ecuatorianos admitidos a un número internacional.

## Contrato de la API

- `POST /api/v1/pedidos` conserva los campos del PRD y devuelve `pedido` y `whatsapp_url`. Envía los identificadores y las cantidades como enteros JSON. `hora_entrega` incluye un desplazamiento horario ISO 8601 en la solicitud. La respuesta devuelve la hora en UTC. Laravel comprueba la tienda, los productos, el punto activo y el plazo, copia nombres y precios y guarda el pedido pendiente antes de responder.
- Flutter envía el encabezado opcional `Idempotency-Key` con 32 dígitos hexadecimales en minúscula. Una repetición con los mismos datos devuelve el pedido original. Si se reutiliza la clave con otros datos, la API devuelve 409. Aplica `php artisan migrate` para agregar las columnas del envío.
- `GET /api/v1/pedidos` devuelve pedidos de la cuenta compradora de 20 en 20, con `estado` opcional. El botón de confirmación abre el historial del comprador. La cancelación, los pedidos recibidos por el vendedor y el vencimiento automático se completarán en otra tarea.
