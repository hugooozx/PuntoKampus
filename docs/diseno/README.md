# Referencias visuales de PuntoKampus

El usuario volvió a proporcionar `laminas.zip` el 14 de noviembre de 2026 y pidió usarlo como guía de la aplicación real, **sin generar más láminas**. Los JPEG de `referencias/` se extrajeron sin modificaciones; la numeración de archivo conserva el orden del ZIP, no el número impreso en cada lámina.

| Archivo | Contenido |
| --- | --- |
| [lamina-01.jpeg](referencias/lamina-01.jpeg) | 03: productos, búsqueda sin resultados y acceso |
| [lamina-02.jpeg](referencias/lamina-02.jpeg) | 02: Vitrina en escritorio |
| [lamina-03.jpeg](referencias/lamina-03.jpeg) | 06: crear y reportar una tienda |
| [lamina-04.jpeg](referencias/lamina-04.jpeg) | 05: pedidos de mi tienda, Premium y comprobante |
| [lamina-05.jpeg](referencias/lamina-05.jpeg) | 04: compra, versión con «Pendiente» verde; sustituida por la corrección siguiente |
| [lamina-06.jpeg](referencias/lamina-06.jpeg) | 01: las cuatro pestañas en celular |
| [lamina-07.jpeg](referencias/lamina-07.jpeg) | 04: compra, versión corregida con «Pendiente» naranja |

Las imágenes son una referencia visual. Los datos, importes, cuentas y códigos ilustrados no son contenido de producción. La mascota dibujada en la primera imagen tampoco sustituye la decisión posterior del usuario: conservar una mancha naranja provisional.

## Traducción a Flutter

- Fondo cálido, superficies blancas con borde fino, naranja oscuro en acciones y texto casi negro.
- Inter incluida localmente, con su licencia SIL OFL. Es una aproximación a la tipografía de las imágenes; el ZIP no aporta archivos de fuente ni especificaciones tipográficas.
- Títulos de peso 900, controles de al menos 48 dp y espacios de 4/8/12/16/24/40 dp.
- Buscador con etiqueta encima, categorías horizontales, selector Tiendas/Productos de ancho completo en celular y limitado en escritorio.
- Tiendas: fila compacta con logo, nombre, insignia, categoría y punto. En escritorio, dos columnas con descripción y acceso «Ver tienda».
- Productos: dos columnas en celular, nombre de tienda, precio negro, insignia de disponibilidad y «Ver producto». Con texto ampliado disminuyen las columnas.
- Navegación inferior con fondo melocotón en la sección activa; lateral en escritorio. Sin identidad ni sesión ficticia en el pie.
- «Matriculado» y «Disponible» verdes, «Sacó 10» dorado, «Agotado» gris. Pedidos pendientes en naranja y comprobantes en revisión en ámbar; siempre acompañados de texto.
- Galería de producto y detalle público de tienda con los mismos componentes. Pedir y reportar siguen deshabilitados hasta conectar sus servicios reales.

El skill UI/UX Pro Max guía accesibilidad, legibilidad y respuesta adaptable; las láminas y las decisiones del usuario determinan la dirección visual. No se agregó ningún filtro nuevo ni cambió el contrato de API. Se ofrece únicamente el tema claro de las referencias.

## Escenarios pendientes indicados por el usuario

Se implementarán con este lenguaje visual, sin exigir nuevas láminas:

| Pantalla | Requisito que conservar |
| --- | --- |
| P03: código | Seis dígitos, reenvío con espera y cambio de correo |
| P04: completar perfil | Nombres y aceptación obligatoria de la política de privacidad con enlace |
| P16: producto nuevo/editar | Hasta tres fotos e interruptor «Disponible» |
| P07: tienda del comprador | Acceso «Reportar»; en el incremento actual está visible y deshabilitado porque no existe aún el servicio de reportes |
| P22: borrar cuenta | Explicación y confirmación por código antes de eliminar |

Premium en tramo 1 aporta insignia y portada propia. El plan gratis también permite pedidos sin límite; no se promociona una exclusividad inexistente ni se prioriza Premium en Vitrina. Los códigos de pedido de las láminas son ejemplos secuenciales: el futuro servicio real debe generarlos aleatoriamente en el servidor. Ese servicio todavía no está implementado.

## Comprobación

`flutter test` verifica los componentes reales con respuestas HTTP simuladas exclusivamente en pruebas. Cubre anchos 320, 375, 768, 844 (horizontal) y 1440, escala de texto 1 y 2, movimiento reducido, orden de tiendas, puntos de entrega y estados de productos.

Después de compilar, `node scripts/verificar_vitrina_web.mjs` comprueba el navegador contra Laravel local. Con `--fixtures`, el mismo script intercepta respuestas solo dentro de su navegador aislado y utiliza `app/test/fixtures/vitrina.json` para comparar tarjetas con las referencias sin poblar MySQL. No es una segunda aplicación ni un modo accesible desde la interfaz real. Las capturas de comprobación se guardan en `.local/verificaciones/`, fuera de Git.

La revisión visual final por el usuario sigue pendiente; este ajuste no declara aprobadas las pantallas autenticadas ni sus funciones.
