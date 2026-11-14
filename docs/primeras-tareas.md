# Primeras tareas por funcionalidad

Propuesta para dos desarrolladores que trabajan en todo el stack. Los nombres A y B indican reparto sugerido; pueden intercambiarlo. Cada tarea debe terminar con su propia validación y PR revisado por la otra persona.

| Orden | Rama sugerida | Responsable / revisión | Resultado y dependencias |
| --- | --- | --- | --- |
| 0 | `chore/base-proyecto` | A / B | Estructura, herramientas reproducibles, entorno de ejemplo, documentación y pruebas iniciales. Configurar el remoto y la revisión de `main`. |
| 1A | `feat/vitrina-conectada` | A / B | Conectar las vistas Flutter a categorías, tiendas y productos de la API; búsqueda sin tildes, categorías primera/segunda, paginación y estados de carga/error/vacío. Depende de 0 y del contrato de las respuestas públicas. |
| 1B | `feat/acceso-utb` | B / A | Correo institucional y subdominios, código OTP, límites, sesión y completar perfil; pantallas Flutter y endpoints Laravel probados. Depende de 0 y de un servicio de correo de pruebas. Puede avanzar junto a 1A. |
| 2A | `feat/crear-editar-tienda` | A / B | Datos de vendedor, tienda en dos pasos, logo, portada restringida por plan y enlace público. Depende de acceso y tablas de categorías/puntos. |
| 2B | `feat/productos-tienda` | B / A | Publicar y editar productos, fotos y disponibilidad; permisos de propietario y borrado suave. Depende de la creación de tienda; puede usar fixtures acordados mientras se revisa 2A. |
| 3A | `feat/pedido-whatsapp` | A / B | Carrito de una sola tienda, cantidades, entrega y pago, total calculado en servidor, pedido guardado antes de WhatsApp; errores si un producto se agota. Depende de acceso, tienda y productos. |
| 3B | `feat/gestion-pedidos` | B / A | Historial de comprador/vendedor, cancelar o entregar solo pendientes, vencimiento automático y visualización en Filament. Depende del modelo de pedidos acordado con 3A. |
| 4A | `feat/reportes-moderacion` | A / B | Reporte con límite de 24 h, detalle obligatorio para Otro, revisión en Filament y baja con motivo. Depende de acceso y tienda. |
| 4B | `feat/premium-comprobantes` | B / A | Precio configurable, comprobante privado, solicitud única pendiente, aprobación/rechazo y vencimiento; portada e insignia sin prioridad en resultados. Depende de tienda, acceso y almacenamiento privado. |
| 5 | `feat/privacidad-piloto` | A+B / revisión cruzada | Política, borrado de cuenta, pruebas Android/web y despliegue para piloto. Depende de todos los flujos que manejen datos personales. |

Los recorridos locales de demostración permiten revisar la interfaz mientras se desarrollan las tareas conectadas. No sustituyen su lógica de servidor ni sus pruebas de permisos, datos y concurrencia.

## Antes de tomar cada tarea

1. Identificar las historias y pantallas del PRD que cubre.
2. Acordar entradas/salidas, estados y dependencias con la otra persona.
3. Avisar si hace falta cambiar el contrato, mostrando campo o respuesta, ejemplo antes/después e impacto en ambos lados.
4. Preparar datos ficticios reproducibles y pruebas de los casos relevantes.
5. Abrir el PR con instrucciones que la otra persona pueda seguir sin ayuda.

Las tareas que dependan de una misma migración deben acordar quién la crea. No se editan migraciones ya aplicadas por otra persona; se añade una nueva cuando corresponda.
