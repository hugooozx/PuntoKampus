# Contexto del proyecto

Versión 1, 12 de noviembre de 2026.

Los demás documentos de esta carpeta dicen **qué** se construye. Este dice **por qué** y **para qué**: de dónde sale PuntoKampus, quién lo va a usar, qué se le exige en cada entrega y qué no se hace nunca. Si estás usando una herramienta de IA para programar, este es el primer archivo que debe leer.

## 1. Qué es PuntoKampus

Una vitrina digital para los negocios de los estudiantes de la Universidad Técnica de Babahoyo (UTB), en la provincia de Los Ríos, Ecuador. El estudiante que vende publica su tienda; el resto de la comunidad universitaria la encuentra, hace un pedido y lo recibe en un punto del campus. El dinero va directo del comprador al vendedor (efectivo, transferencia o Deuna): PuntoKampus no toca ese pago.

Hay dos formas de usarla, salidas del mismo código de Flutter:

- **App de Android**, publicada en Google Play. Es la principal.
- **Versión web**, para quien tiene iPhone o no quiere instalar nada. Hace todo lo que hace la app.

## 2. Por qué existe

El equipo partió de dos problemas que se ven todos los días en la universidad:

| Lado | Qué pasa hoy |
|---|---|
| Quien vende | Se promociona de boca en boca o con mensajes en grupos de WhatsApp que se pierden entre otros. Muchos recorren aulas y pasillos entre clases. Sus clientes casi siempre son compañeros de curso y amigos |
| Quien compra | No sabe quién vende lo que busca dentro de la universidad. Si no conoce al vendedor, no tiene cómo comprobar que es un estudiante real |

Por eso la plataforma tiene dos ideas fijas: **juntar a todos los vendedores en un solo lugar** y **dejar entrar solo con correo institucional**, para que cada tienda sea de un estudiante verificado. Cuando una decisión de diseño dude entre dos caminos, sirve preguntarse cuál ayuda más a que un negocio sea conocido fuera del círculo de su dueño, o a que un comprador confíe en un vendedor que no conoce.

## 3. Quién la va a usar de verdad

| Dato | Qué significa para quien programa |
|---|---|
| Estudiantes universitarios de Babahoyo | Los textos van en español, de tú, sin tecnicismos |
| Muchos celulares Android sencillos, con poca memoria | Fotos reducidas antes de subirlas, listas que cargan por partes, nada de animaciones pesadas. Se prueba cada viernes en el celular más sencillo del equipo |
| Datos móviles limitados | Cada pantalla carga solo lo que muestra. La versión web tarda más en abrir la primera vez: se mide en la semana 4 |
| Algunos con iPhone | Usan la versión web desde Safari. Tiene que funcionar ahí |
| Correos institucionales `utb.edu.ec` | El código de acceso puede caer en spam. Se prueba con correos reales desde la semana 4 |
| Vendedores que ya atienden por WhatsApp | El pedido termina en WhatsApp porque es donde el vendedor ya trabaja. La plataforma lo ordena y lo registra, no lo reemplaza |

## 4. Un proyecto, dos materias

PuntoKampus es al mismo tiempo el proyecto de investigación del semestre y el emprendimiento del equipo. Las dos materias se cumplen con la misma plataforma.

| Materia | Qué le pide a la plataforma |
|---|---|
| Proyecto Integrador de Saberes (Diseño de Proyecto de Investigación) | Una aplicación móvil terminada, no una maqueta. Al final, personas reales la usan y responden un cuestionario sobre qué tan útil y fácil de usar les resultó |
| Emprendimiento | Un MVP en la semana 9 y una prueba piloto con al menos 10 clientes reales, con datos reales. En la semana 18, la feria de la facultad |

El proyecto de investigación tiene tres fases: primero una encuesta a la universidad (la hacen otros integrantes, no está en la app), después la construcción de la plataforma (esta parte) y al final la evaluación con quienes la usaron.

**Cómo se llama lo que construimos.** En los documentos de Emprendimiento se dice "MVP". En los del proyecto de investigación se dice "primera versión funcional", porque el docente pidió una app terminada. La palabra "prototipo" no se usa en ninguna parte, tampoco en textos que vea el usuario.

## 5. Qué se le exige en cada entrega

| Cuándo | Qué tiene que pasar | Qué implica en el código |
|---|---|---|
| Semana 9 del periodo (primera entrega de Emprendimiento) | El tramo 1 funcionando con usuarios reales. Prueba piloto en la semana 8 con al menos 10 clientes | Los datos del piloto salen de la base de datos (`00-PRD-general.md`, sección 9). En producción no se cargan tiendas ni pedidos inventados |
| Antes de la feria | Prueba cerrada en Google Play: al menos 12 personas durante 14 días seguidos, y luego la solicitud de publicación. Google puede tardar o no aprobarla | La versión web tiene que estar completa: si Google se demora, el piloto y la evaluación se hacen desde la web |
| Después del uso | Evaluación: cada participante hace tareas reales (vendedor: crear tienda, publicar un producto, atender un pedido; comprador: buscar, pedir, confirmar la entrega) y luego responde el cuestionario | Esas seis tareas tienen que poder completarse sin ayuda. Por ahora el cuestionario no se programa dentro de la app |
| Semana 18 (feria) | Demostración en vivo ante docentes y visitantes | La app no puede fallar delante de la gente: preferir lo estable a lo vistoso |

La fecha exacta de las semanas 8 y 9 depende de las vacaciones de fin de año y está por confirmar. Semana 3 = 16 al 20 de noviembre de 2026.

## 6. Cómo gana dinero

| Fuente | Qué es | Tramo |
|---|---|---|
| Plan Premium | El vendedor paga por periodo académico. En el tramo 1 recibe la insignia "Sacó 10", portada propia y pedidos registrados sin límite | 1 |
| Destacados | El vendedor paga por aparecer primero en su categoría, con la etiqueta "Destacado" | 2 |
| Kit QR impreso | Tarjetas, cartel de mesa y stickers con el QR de la tienda. Se vende fuera de la app | Fuera de la app |
| Publicidad | Negocios de fuera de la universidad pagan un espacio con la etiqueta "Publicidad". No pueden vender | 2 |

El modelo se está rehaciendo para que deje ganancia al equipo, no solo cubra los gastos. Por eso **ningún precio va escrito en el código**: el precio del Premium y el límite de pedidos del plan gratis se cambian desde el panel del administrador (tabla `configuracion`). El piloto sirve también para medir si los vendedores pagan de verdad: las solicitudes Premium enviadas y aprobadas son ese dato.

## 7. Lo que no se hace

| No | Por qué |
|---|---|
| Pagos dentro de la app | El dinero va directo al vendedor. Cobrar dentro exige pasarela, comisiones y permisos que el proyecto no necesita |
| Tarjeta con chip (NFC) | La rechazó el docente de Emprendimiento el 5/11/2026. Se usa solo el código QR |
| App para iPhone en la App Store | Cuesta $99 al año. El iPhone usa la versión web |
| Tiendas de negocios que no son de estudiantes | El proyecto es para emprendimientos estudiantiles. Los de afuera solo compran publicidad |
| Comprar sin correo UTB | Sin el correo, la confianza deja de estar comprobada y se vuelve una app de delivery cualquiera |
| Insignia "Vendedor certificado" o parecida | Da a entender que la universidad avala al vendedor, y no es así |
| Reseñas escritas | Solo estrellas, en el tramo 2 |
| Otras universidades | Fuera de la versión 1.0 |

## 8. Datos personales

La plataforma guarda datos de estudiantes reales: correo, nombres, código de estudiante, carrera, número de WhatsApp, pedidos y fotos de comprobantes bancarios. Se aplica la Ley Orgánica de Protección de Datos Personales del Ecuador y las reglas de Google Play (borrar la cuenta desde la app y desde la web, y política de privacidad visible). Todo el detalle está en `05-privacidad-y-google-play.md`. Ante cualquier duda sobre un dato, la respuesta por defecto es no guardarlo, no mostrarlo y preguntar.

## 9. Glosario

| Palabra | Qué significa aquí |
|---|---|
| UTB | Universidad Técnica de Babahoyo |
| Periodo académico | El semestre. Este va de octubre de 2026 a marzo de 2027. El Premium vence al terminar el periodo |
| Semana del periodo | Se cuentan desde el inicio de clases. La semana 3 es del 16 al 20 de noviembre de 2026 |
| Tramo 1 y tramo 2 | Las dos partes en que se construye la plataforma: tramo 1 para la semana 9, tramo 2 antes de la feria |
| MVP | Producto mínimo que ya se puede usar con clientes reales. Aquí es el tramo 1 |
| Prueba piloto | Uso real con al menos 10 clientes en la semana 8, para medir pedidos y disposición a pagar |
| Prueba cerrada | Requisito de Google Play antes de publicar: 12 personas, 14 días seguidos |
| Punto de entrega | Lugar del campus donde se entrega el pedido. La lista se maneja desde el panel |
| Deuna | Aplicación de pagos muy usada en Ecuador. El comprador paga con ella directo al vendedor |
| "Matriculado" y "Sacó 10" | Insignias del plan gratis y del Premium |
| Dueño del producto | Quien decide qué entra en la plataforma, aprueba los cambios y revisa los reportes |
| Servidor y app | Las dos partes del trabajo: Laravel con PostgreSQL y Filament, y Flutter |
