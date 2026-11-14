# Privacidad y Google Play

Versión 1, 12 de noviembre de 2026. Este documento no reemplaza la revisión de un abogado. Resume lo que piden la ley ecuatoriana y Google Play, y cómo lo cumple PuntoKampus.

## 1. Qué datos se guardan y para qué

| Dato | De quién | Para qué | Quién lo ve | Cuánto tiempo |
|---|---|---|---|---|
| Correo institucional | Todos | Entrar y comprobar que es de la UTB | El administrador | Mientras exista la cuenta |
| Nombres | Todos | Que el vendedor sepa quién le pide | El vendedor que recibe el pedido; el administrador | Mientras exista la cuenta |
| Código de estudiante, facultad, carrera, semestre | Vendedores | Comprobar que el vendedor es estudiante | El administrador | Mientras exista la cuenta |
| Número de WhatsApp | Vendedores | Recibir los pedidos | Quien le hace un pedido; el público solo si el vendedor lo activa | Mientras exista la cuenta |
| Pedidos | Comprador y vendedor | Historial y prueba piloto | Las dos partes del pedido; el administrador | Mientras existan las cuentas. Si una se borra, su nombre se reemplaza por "Usuario eliminado" |
| Foto del comprobante | Vendedores que piden Premium | Comprobar el pago | El administrador y el propio vendedor | Se borra **30 días** después de revisarla *(propuesta)*. El número y el monto se guardan como registro del pago |
| Reportes | Quien reporta | Revisar tiendas | El administrador. La tienda reportada no sabe quién la reportó | Mientras exista la tienda |

No se pide cédula, dirección ni datos bancarios del usuario. Los datos bancarios que aparecen en la foto del comprobante no se copian a ningún otro lado.

## 2. Lo que pide la ley ecuatoriana

La Ley Orgánica de Protección de Datos Personales se publicó en el Registro Oficial (Quinto Suplemento n.º 459) el 26 de mayo de 2021. Su reglamento general se expidió con el Decreto Ejecutivo n.º 904 de 2023.

| Lo que pide | Dónde lo dice | Cómo lo cumple PuntoKampus |
|---|---|---|
| Que la persona acepte el uso de sus datos | Ley de protección de datos | Casilla obligatoria de la política de privacidad al registrarse (P04), con la fecha guardada en `acepto_privacidad_en` |
| Acceso: la persona puede pedir todos sus datos, gratis, en 15 días | Art. 13 | Por ahora, por correo al equipo. Respuesta en menos de 15 días |
| Rectificación y actualización en 15 días | Art. 14 | La persona edita sus datos en Cuenta. Lo que no pueda editar, lo pide por correo |
| Eliminación en 15 días | Art. 15 | Borrado inmediato desde la app o desde `/borrar-cuenta` (reglas 29 a 31 de `04`) |
| Eliminación segura al terminar el plazo de conservación | Reglamento, art. 11 | La tarea automática borra las fotos de comprobantes vencidas |
| Inscribir la base de datos en el Registro Nacional de Protección de Datos Personales dentro de los 10 días de empezar a usarla | Reglamento, art. 86 | **Pendiente:** confirmar con el docente o con la universidad si un proyecto académico en prueba piloto debe inscribirse, y quién lo hace |

## 3. Lo que pide Google Play

| Requisito | Qué hay que hacer |
|---|---|
| Política de privacidad | Debe estar dentro de la app (P21) y su enlace en la ficha de Google Play (`/privacidad`). Tiene que nombrar a la app o a quien la publica |
| Formulario "Seguridad de los datos" | Se llena en Play Console con lo que dice la sección 1 de este documento. No se puede describir como opcional un dato que es obligatorio |
| Borrar la cuenta | Una opción dentro de la app (P22) y un enlace web donde se pueda pedir lo mismo (`/borrar-cuenta`). Se borran la cuenta y los datos asociados |
| Seguridad | Datos protegidos al viajar: HTTPS en todo el servidor |
| Prueba cerrada | Las cuentas personales de desarrollador creadas después del 13/11/2023 deben hacer una prueba cerrada con al menos 12 personas durante 14 días seguidos antes de pedir la publicación. Eso es del tramo 2 |

## 4. Seguridad mínima

- HTTPS en todo el servidor.
- Los códigos de acceso se guardan cifrados (`codigo_hash`), vencen en 10 minutos y aceptan 5 intentos.
- Las fotos de comprobantes se guardan fuera de la carpeta pública: solo el servidor las entrega, y solo a un administrador o al dueño de la solicitud.
- Las claves del servidor (base de datos, correo) van en el archivo `.env`, que **nunca** se sube al repositorio.
- Cada ruta 🔒 revisa que el usuario solo toque lo suyo (pruebas automáticas en `02`).
- Copia diaria de la base de datos, guardada fuera del servidor.

## 5. Borrador de la política de privacidad

Este texto se publica en `/privacidad` y en P21. Antes de publicarlo hay que completar lo que está entre corchetes.

> **Política de privacidad de PuntoKampus**
>
> Última actualización: [fecha].
>
> PuntoKampus es una plataforma hecha por estudiantes de la Universidad Técnica de Babahoyo para que la comunidad universitaria compre a los negocios de sus compañeros. Responsable de los datos: [nombre del responsable o del equipo]. Contacto: [correo del equipo].
>
> **Qué datos guardamos.** Tu correo institucional y tus nombres. Si creas una tienda, también tu código de estudiante, facultad, carrera, semestre y número de WhatsApp. Guardamos los pedidos que haces o recibes. Si pides el plan Premium, guardamos la foto de tu comprobante durante 30 días después de revisarlo, y el número y el monto del pago.
>
> **Para qué los usamos.** Para dejarte entrar, mostrar tu tienda, registrar tus pedidos y comprobar tus pagos. También usamos datos agrupados, sin nombres, para medir cómo funciona la plataforma en la prueba piloto del proyecto.
>
> **Quién los ve.** El vendedor ve tu nombre y tu pedido cuando le compras. Quien te hace un pedido ve tu WhatsApp. El público lo ve solo si tú lo activas. El equipo de PuntoKampus ve los datos para administrar la plataforma. No vendemos ni compartimos tus datos con nadie más.
>
> **Tus derechos.** Puedes ver y corregir tus datos en la sección Cuenta. Puedes pedirnos una copia de tus datos o borrar tu cuenta en cualquier momento, desde la app o en [dominio]/borrar-cuenta. Respondemos cualquier pedido en menos de 15 días, como manda la Ley Orgánica de Protección de Datos Personales.
>
> **Cuánto tiempo los guardamos.** Mientras tengas tu cuenta. Al borrarla, eliminamos tus datos. En los pedidos que tuviste con otras personas, tu nombre se reemplaza por "Usuario eliminado".
>
> **Cambios.** Si cambiamos esta política, te avisaremos en la app antes de que el cambio empiece a regir.

## 6. Pendientes

| Tema | Quién lo decide |
|---|---|
| Plazo para borrar la foto del comprobante (propuesta: 30 días) | Dueño del producto |
| Nombre del responsable de los datos y correo de contacto del equipo | Dueño del producto |
| Si hay que inscribir la base de datos en el Registro Nacional | Consultar con el docente o con la universidad |
| Dominio de la plataforma | Dueño del producto, con quien programa el servidor |

## Fuentes

- Asamblea Nacional del Ecuador. (2021). Ley Orgánica de Protección de Datos Personales. *Registro Oficial, Quinto Suplemento*, (459). https://www.finanzaspopulares.gob.ec/wp-content/uploads/2021/07/ley_organica_de_proteccion_de_datos_personales.pdf
- Presidencia de la República del Ecuador. (2023). *Reglamento General de la Ley Orgánica de Protección de Datos Personales* (Decreto Ejecutivo n.º 904). https://www.telecomunicaciones.gob.ec/wp-content/uploads/2023/11/Decreto-Ejecutivo-No.-904.pdf
- Google. (s. f.-a). *Información sobre los requisitos de eliminación de cuentas de aplicaciones de Google Play*. Ayuda de Play Console. Recuperado el 12 de noviembre de 2026, de https://support.google.com/googleplay/android-developer/answer/13327111?hl=es
- Google. (s. f.-b). *Datos del usuario*. Ayuda de Play Console. Recuperado el 12 de noviembre de 2026, de https://support.google.com/googleplay/android-developer/answer/10144311?hl=es-419
- Google. (s. f.-c). *Proporciona información para la sección de Seguridad de los datos de Google Play*. Ayuda de Play Console. Recuperado el 12 de noviembre de 2026, de https://support.google.com/googleplay/android-developer/answer/10787469?hl=es-419
- Google. (s. f.-d). *App testing requirements for new personal developer accounts*. Play Console Help. Recuperado el 10 de noviembre de 2026, de https://support.google.com/googleplay/android-developer/answer/14151465
