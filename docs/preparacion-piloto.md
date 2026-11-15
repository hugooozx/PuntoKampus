# Preparación de la prueba web de PuntoKampus

## Datos que debe confirmar el equipo

| Dato | Dónde se configura | Cómo comprobarlo |
| --- | --- | --- |
| Correo de soporte | `PK_CORREO_SOPORTE` en Laravel | El dueño de una tienda de prueba dada de baja puede usar **Escribir al equipo** desde **Mi tienda**. |
| Responsable, contacto y fecha de privacidad | `PK_RESPONSABLE_DATOS`, `PK_CORREO_PRIVACIDAD` y `PK_PRIVACIDAD_ACTUALIZADA_EN` (formato `AAAA-MM-DD`) en Laravel | Abrir `/privacidad` sin cuenta, verificar el nombre y la fecha, probar el enlace de correo y abrir el formulario de borrado. El equipo revisa el texto antes de publicarlo. |
| Remitente y servicio de correo | `MAIL_MAILER=smtp`, parámetros `MAIL_*` y remitente autorizado, según el servicio elegido | Probar el acceso con tres correos UTB reales de participantes y anotar el tiempo de entrega y si llega a spam. Los secretos se configuran directamente en el servidor. |
| Periodo académico y cobro Premium | `configuraciones`, `periodos_academicos` y `cuentas_bancarias` en PostgreSQL | Confirmar fechas, precio, titular, banco, tipo y número de cuenta, Deuna si aplica y plazo de conservación de comprobantes. Revisar **Premium** con una cuenta vendedora. |
| Dirección web para los participantes | Web y API de prueba accesibles mediante HTTPS | Abrir la portada, una tienda, `/privacidad` y `/borrar-cuenta` directamente desde otro celular. |

El entorno local usa el modo de registro de correo. El precio provisional de Premium es **USD 2,50**. La cuenta de cobro y el periodo de esta computadora son ficticios. El [catálogo UTB](catalogo-utb.md) documenta las fuentes de las carreras, las mallas verificadas y los puntos de entrega iniciales. Para el recorrido de usabilidad se pueden usar tiendas y pedidos de prueba, con el envío por WhatsApp y el flujo de pago detenidos en la pantalla de revisión.

## Ensayo local

Abre la [Vitrina local](http://127.0.0.1:8766/vitrina) después de iniciar la aplicación. Esta computadora tiene cuatro tiendas ficticias activas para revisar las tarjetas y las categorías. [Papelería Entre Clases](http://127.0.0.1:8766/t/revision-web-papeleria) permite probar una tienda sin productos. El [enlace de la tienda dada de baja](http://127.0.0.1:8766/t/revision-web-baja) permite comprobar el regreso a la Vitrina.

## Recorrido con tres personas ajenas al equipo

Enviar el enlace del entorno de prueba junto con este texto cuando esté accesible desde sus celulares.

> Estamos probando PuntoKampus. Entra desde tu celular y haz las tareas de abajo por tu cuenta. Si te atoras, anota qué buscabas hacer y qué viste en pantalla. Usa las tiendas, productos y pedidos marcados para prueba. Cuando llegues a WhatsApp o veas datos de cobro, detente ahí.

1. Desde la portada, busca **Café Naranja**, cambia de categoría y alterna entre **Tiendas** y **Productos**. Encuentra un producto disponible y otro agotado.
2. Busca algo que no exista y vuelve a ver todo el catálogo. Abre el enlace que el equipo te entrega de una tienda dada de baja y regresa a la Vitrina.
3. Agrega un producto disponible al carrito, cambia la cantidad y continúa. Entra con el código UTB si se te pide. Elige un punto, día, hora y forma de pago. Si el equipo habilitó un pedido ficticio, comprueba el código de confirmación y la opción de abrir WhatsApp.
4. Desde tu propia cuenta UTB, abre **Mi tienda** y crea una tienda marcada como prueba. Localiza dónde publicarías un producto, gestionarías pedidos recibidos y consultarías el estado de Premium.
5. Encuentra la política de privacidad, la opción para cerrar sesión y la pantalla de borrado. Detente antes de confirmar un borrado.

Por persona, anotar navegador, tiempo hasta que abra la Vitrina, tiempo y bandeja de entrega del código, tareas completadas sin ayuda y punto exacto de cada bloqueo. En los resultados basta con identificar a la persona como A, B o C. Evitar capturas con códigos, comprobantes o correos.
