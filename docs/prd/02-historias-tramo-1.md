# Historias del tramo 1

Versión 1, 12 de noviembre de 2026. Cada historia dice quién quiere qué y para qué, y cómo se comprueba. Una historia está terminada cuando **todas** sus pruebas pasan en un celular Android y en el navegador de un celular, con el servidor en internet.

Las pruebas se leen así: **Dado** (la situación), **cuando** (lo que hace la persona), **entonces** (lo que tiene que pasar). Las reglas numeradas (R1, R2...) están en `04-datos-reglas-y-api.md`.

## Acceso

### H01. Registrarme con mi correo institucional
Como estudiante, quiero entrar con mi correo de la UTB para usar PuntoKampus sin crear una contraseña.

- Dado un correo `nombre@utb.edu.ec` sin cuenta, cuando lo escribo y pido el código, entonces me llega un correo con un código de 6 dígitos en menos de 2 minutos.
- Dado un correo `nombre@gmail.com`, cuando pido el código, entonces veo "Solo se puede entrar con un correo de la UTB" y no se envía nada.
- Dado un correo de subdominio (`nombre@fafi.utb.edu.ec`), cuando pido el código, entonces me llega igual.
- Dado el código correcto, cuando lo escribo, entonces me pide mis nombres y aceptar la política de privacidad, y después entro a la vitrina.
- Dado que no acepto la política, cuando intento seguir, entonces no puedo avanzar.

### H02. Entrar otra vez
Como estudiante con cuenta, quiero entrar con un código para no recordar contraseñas.

- Dado que escribo un código equivocado 5 veces, entonces ese código deja de servir y tengo que pedir otro.
- Dado un código de hace más de 10 minutos, cuando lo escribo, entonces veo "Este código ya venció. Pide uno nuevo".
- Dado que acabo de pedir un código, cuando pido otro antes de 60 segundos, entonces el botón muestra cuántos segundos faltan.
- Dado que entré y cierro la app, cuando la abro al día siguiente, entonces sigo dentro.

### H03. Salir
- Dado que estoy dentro, cuando toco "Salir", entonces vuelvo a la pantalla de bienvenida y el token deja de servir en el servidor.

### H04. Borrar mi cuenta
Como usuario, quiero borrar mi cuenta y mis datos cuando yo decida.

- Dado que estoy en Cuenta, cuando toco "Borrar mi cuenta", entonces veo qué se va a borrar y me llega un código para confirmar.
- Dado el código correcto, cuando confirmo, entonces mi cuenta, mi tienda, mis productos y mis fotos desaparecen, y salgo de la app.
- Dado que borré mi cuenta, cuando el vendedor revisa un pedido que le hice, entonces ve "Usuario eliminado" en lugar de mi nombre.
- Dado que no tengo la app, cuando entro a la página `/borrar-cuenta` con mi correo y un código, entonces puedo borrar la cuenta igual.

## Tienda y productos

### H05. Crear mi tienda
Como estudiante que vende, quiero crear mi tienda para que toda la universidad vea lo que ofrezco.

- Dado que no tengo tienda, cuando toco "Crear mi tienda", entonces me pide mis datos de vendedor (si faltan) y los de la tienda.
- Dado que escribo un WhatsApp como `0991234567`, cuando guardo, entonces se guarda como `593991234567`.
- Dado que lleno todo bien, cuando guardo, entonces la tienda aparece de inmediato en la vitrina, con la insignia "Matriculado".
- Dado que elijo dos veces la misma categoría, cuando guardo, entonces veo un error.
- Dado que ya tengo tienda, entonces no aparece la opción de crear otra.

### H06. Editar mi tienda
- Dado que cambio el nombre, el horario o el logo, cuando guardo, entonces los cambios se ven en la vitrina.
- Dado que mi tienda es del plan gratis, cuando busco dónde subir una portada, entonces veo que es un beneficio Premium y cómo obtenerlo.
- Dado que decido mostrar mi WhatsApp, cuando lo activo, entonces el número aparece en mi tienda pública. Si no lo activo, no aparece en ningún lado de la tienda.

### H07. Publicar y editar productos
- Dado mi tienda, cuando agrego un producto con nombre, precio y una foto, entonces aparece en mi tienda y en la vitrina.
- Dado un producto con 3 fotos, cuando intento subir otra, entonces veo "Cada producto puede tener hasta 3 fotos".
- Dado un precio de 0 o mayor que 500, cuando guardo, entonces veo un error.
- Dado que subo una foto tomada con el celular, entonces se sube aunque pese varios MB, porque se reduce antes de enviarla.
- Dado que borro un producto, entonces desaparece de mi tienda, pero sigue en los pedidos viejos que lo incluían.

### H08. Marcar un producto como agotado
- Dado un producto disponible, cuando lo marco "Agotado", entonces sigue visible en mi tienda con la etiqueta "Agotado" y nadie lo puede agregar al carrito.

## Vitrina

### H09. Ver la vitrina por categoría
Como comprador, quiero ver los negocios por categoría para encontrar rápido lo que busco.

- Dado que abro la vitrina, entonces veo las categorías y las tiendas activas.
- Dado que elijo "Postres y dulces", entonces solo veo tiendas que tienen esa categoría como primera o segunda.
- Dado que una tienda fue dada de baja, entonces no aparece.
- Dado que hay más de 20 tiendas, cuando llego al final de la lista, entonces se cargan más.

### H10. Buscar
- Dado que escribo "empanada", entonces veo los productos y tiendas que la mencionan en el nombre o la descripción.
- Dado que escribo "EMPANADA" o "empanadá", entonces el resultado es el mismo.
- Dado que no hay resultados, entonces veo "No encontramos nada con «empanada». Prueba con otra palabra o revisa las categorías".

### H11. Ver una tienda
- Dado que abro una tienda, entonces veo su nombre, logo, insignia, descripción, horario, punto de entrega y productos, y su portada si es Premium.

### H12. Abrir el enlace público de una tienda
Como vendedor, quiero compartir el enlace de mi tienda en mis grupos para que me encuentren.

- Dado el enlace `/t/dulces-de-ana`, cuando lo abre alguien sin sesión, entonces ve la tienda completa.
- Dado que esa persona toca "Pedir", entonces le pide entrar con su correo de la UTB y después vuelve a la misma tienda.
- Dado el enlace de una tienda dada de baja, entonces se ve "Esta tienda no está disponible".

## Pedidos

### H13. Armar el carrito
- Dado productos de una tienda en mi carrito, cuando agrego uno de otra tienda, entonces veo "Tu carrito tiene productos de otra tienda. ¿Quieres vaciarlo y empezar uno nuevo?".
- Dado un producto en el carrito, cuando cambio la cantidad a 21, entonces no me deja pasar de 20.
- Dado que estoy en mi propia tienda, entonces no veo el botón para agregar al carrito.

### H14. Enviar el pedido
Como comprador, quiero mandar mi pedido sin escribirlo a mano y que quede registrado.

- Dado mi carrito, cuando elijo punto, hora y forma de pago y toco "Enviar pedido", entonces el pedido se guarda como "Pendiente" y se abre WhatsApp con el mensaje armado para el vendedor.
- Dado que el vendedor marcó un producto como agotado mientras yo elegía, cuando envío, entonces veo cuál producto ya no está disponible y el pedido no se crea.
- Dado una hora de entrega dentro de los próximos 30 minutos, entonces no me deja elegirla.
- Dado que el total en mi pantalla no coincide con el del servidor, entonces manda el del servidor.
- Dado que no tengo WhatsApp instalado, cuando envío, entonces el pedido igual queda guardado y se abre WhatsApp Web.

### H15. Ver y cancelar mis pedidos
- Dado que hice pedidos, entonces los veo en "Mis pedidos" con su código, tienda, total y estado.
- Dado un pedido "Pendiente", cuando lo cancelo, entonces pasa a "Cancelado".
- Dado un pedido "Entregado", entonces no aparece la opción de cancelar.

### H16. Ver los pedidos de mi tienda
- Dado que me hicieron un pedido, entonces lo veo en "Pedidos de mi tienda" con el nombre del comprador, los productos, el punto, la hora y la forma de pago.
- Dado que filtro por "Pendientes", entonces solo veo esos.

### H17. Marcar un pedido como entregado o cancelado
- Dado un pedido "Pendiente" de mi tienda, cuando lo marco "Entregado", entonces cambia de estado para mí y para el comprador.
- Dado un pedido que ya está "Cancelado", entonces no puedo marcarlo como entregado.

### H18. Pedidos vencidos
- Dado un pedido "Pendiente" cuya hora de entrega pasó hace más de 24 horas, cuando corre la tarea automática, entonces pasa a "Vencido".

## Reportes

### H19. Reportar una tienda
Como comprador, quiero avisar si una tienda vende algo prohibido o no cumple.

- Dado una tienda, cuando toco "Reportar" y elijo un motivo, entonces veo "Gracias. El equipo lo revisará en 24 horas".
- Dado el motivo "Otro" sin detalle, cuando envío, entonces me pide escribir qué pasó.
- Dado que ya reporté esa tienda hoy, cuando intento de nuevo, entonces veo "Ya reportaste esta tienda hoy".
- Dado mi propia tienda, entonces no veo el botón "Reportar".

## Premium

### H20. Pedir el plan Premium
Como vendedor, quiero pagar el Premium y mandar el comprobante desde la app.

- Dado que abro "Premium", entonces veo el precio, lo que incluye y los datos de la cuenta donde pagar.
- Dado que subo la foto del comprobante, escribo el número y el monto, y envío, entonces la solicitud queda "En revisión".
- Dado una solicitud en revisión, cuando intento mandar otra, entonces no me deja.
- Dado que me rechazan la solicitud, entonces veo el motivo y puedo mandar una nueva.

### H21. Recibir los beneficios Premium
- Dado que el administrador aprueba mi solicitud, entonces mi tienda muestra "Sacó 10" y puedo subir una portada.
- Dado que llega la fecha de fin del periodo, cuando corre la tarea automática, entonces mi tienda vuelve al plan gratis con "Matriculado" y la portada deja de verse.

## Administración (panel web)

### H22. Dar de baja una tienda
Como administrador, quiero quitar una tienda que incumple las reglas y explicar por qué.

- Dado una tienda activa, cuando toco "Dar de baja" sin escribir motivo, entonces no me deja.
- Dado que escribo el motivo y confirmo, entonces la tienda desaparece de la vitrina, sus pedidos pendientes pasan a "Cancelado" y el vendedor ve el motivo al entrar.
- Dado una tienda dada de baja, cuando toco "Reactivar", entonces vuelve a la vitrina.

### H23. Revisar reportes
- Dado reportes nuevos, entonces aparecen primero, con la tienda y el motivo.
- Dado un reporte, cuando lo cierro sin acción, entonces me pide una nota.

### H24. Revisar solicitudes Premium
- Dado una solicitud pendiente, entonces veo la foto del comprobante, el número y el monto.
- Dado un número de comprobante que ya se usó en otra solicitud aprobada, cuando intento aprobar, entonces el panel lo avisa y no deja aprobar.
- Dado que rechazo, entonces me pide el motivo.

### H25. Manejar categorías, puntos de entrega y configuración
- Dado que desactivo un punto de entrega, entonces deja de aparecer al hacer pedidos, pero los pedidos viejos lo siguen mostrando.
- Dado que cambio los datos de la cuenta de pago, entonces el vendedor ve los nuevos en la pantalla de Premium.

### H26. Ver el resumen del piloto
- Dado una semana, entonces veo tiendas creadas, productos publicados, pedidos por estado, compradores distintos, solicitudes Premium enviadas y aprobadas, y reportes recibidos.

## Privacidad

### H27. Leer la política de privacidad
- Dado que estoy en Cuenta, cuando toco "Política de privacidad", entonces la veo completa.
- Dado la página `/privacidad`, cuando la abre cualquiera, entonces la ve sin entrar.

## Pruebas que se automatizan

No todo se prueba a mano. Lo que más se rompe y más daño hace se prueba con código:

| Qué | Dónde | Tipo de prueba |
|---|---|---|
| Reglas R1 a R31 (correos válidos, límites, estados de pedido, Premium, borrado) | Servidor | Pruebas automáticas de Laravel (Pest o PHPUnit) sobre la API |
| Cálculo del total y armado del mensaje de WhatsApp | Servidor | Pruebas automáticas |
| Que nadie pueda tocar la tienda o los pedidos de otro | Servidor | Pruebas automáticas: cada ruta 🔒 con un usuario ajeno debe responder 403 o 404 |
| Formularios de tienda, producto y pedido | App | Pruebas de widgets de Flutter para las validaciones |
| Recorrido completo (entrar, crear tienda, pedir) | Las dos | A mano, cada viernes, en Android y en el navegador |

Meta: que cada regla de `04` tenga al menos una prueba automática antes del piloto de la semana 8.
